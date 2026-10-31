import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/group_session.dart';

/// CloudSyncService manages real-time group swiping synchronization between
/// multiple physical iPhones and web clients using Google Firebase Realtime Database REST.
/// Includes Conflict-Free Replicated Data Type (CRDT) set-union merging so concurrent
/// swipes from multiple phones never overwrite each other.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  /// User's live Firebase Realtime Database in europe-west1 (Belgium)
  static String firebaseBaseUrl =
      'https://tastematch-3e908-default-rtdb.europe-west1.firebasedatabase.app';

  Timer? _pollingTimer;
  String? _currentlyWatchedGroupId;
  bool _isSyncInFlight = false;
  bool isCloudHealthy = true;
  DateTime? lastSyncedAt;

  final _activeGroupStreamController =
      StreamController<GroupSession>.broadcast();

  Stream<GroupSession> get groupUpdatesStream =>
      _activeGroupStreamController.stream;

  /// Clean PIN code for storage keys (remove spaces)
  String _cleanPin(String pin) => pin.replaceAll(' ', '').trim();

  /// Conflict-Free Replicated Data Type (CRDT) merge of two GroupSession snapshots.
  /// Ensures members, votes, status transitions, and matches never get lost when
  /// multiple iPhones swipe simultaneously.
  static GroupSession mergeSessions(
    GroupSession local,
    GroupSession remote,
  ) {
    // 1. Merge members by userId
    final memberMap = <String, GroupMember>{};
    for (final m in remote.members) {
      memberMap[m.userId] = m;
    }
    for (final m in local.members) {
      final existing = memberMap[m.userId];
      if (existing == null) {
        memberMap[m.userId] = m;
      } else {
        memberMap[m.userId] = existing.copyWith(
          isReady: existing.isReady || m.isReady,
        );
      }
    }
    final mergedMembers = memberMap.values.toList();

    // 2. Merge votes per restaurant (Set union of userIds)
    final allRestaurantKeys = <String>{
      ...remote.votes.keys,
      ...local.votes.keys,
    };
    final mergedVotes = <String, List<String>>{};
    for (final restId in allRestaurantKeys) {
      final combinedVoters = <String>{
        ...(remote.votes[restId] ?? const []),
        ...(local.votes[restId] ?? const []),
      };
      mergedVotes[restId] = combinedVoters.toList();
    }

    // 3. Monotonic status progression: lobby -> swiping -> completed
    int statusPriority(GroupStatus s) {
      switch (s) {
        case GroupStatus.lobby:
          return 0;
        case GroupStatus.swiping:
          return 1;
        case GroupStatus.completed:
          return 2;
      }
    }

    final mergedStatus =
        statusPriority(local.status) >= statusPriority(remote.status)
            ? local.status
            : remote.status;

    // 4. Merge & recompute matchedRestaurantIds based on merged votes + members
    final matchedSet = <String>{
      ...remote.matchedRestaurantIds,
      ...local.matchedRestaurantIds,
    };

    final totalMembers = max(mergedMembers.length, 1);
    final rule = local.matchRule;

    for (final entry in mergedVotes.entries) {
      final restId = entry.key;
      final voterCount = entry.value.length;
      final isMatch = (rule == MatchRule.unanimous)
          ? voterCount >= totalMembers
          : voterCount > (totalMembers / 2);
      if (isMatch) {
        matchedSet.add(restId);
      }
    }

    // Preserve deck from host/remote if non-empty
    final deck = remote.restaurantDeckIds.isNotEmpty
        ? remote.restaurantDeckIds
        : local.restaurantDeckIds;

    return local.copyWith(
      status: mergedStatus,
      members: mergedMembers,
      restaurantDeckIds: deck,
      votes: mergedVotes,
      matchedRestaurantIds: matchedSet.toList(),
    );
  }

  /// Save or merge-update a group session in the cloud
  Future<GroupSession> pushGroupToCloud(GroupSession group) async {
    GroupSession toSave = group;
    try {
      final cleanPin = _cleanPin(group.pinCode);

      // Fetch latest remote snapshot first to avoid overwriting concurrent swipes
      final existingRemote = await fetchGroupById(group.id);
      if (existingRemote != null) {
        toSave = mergeSessions(group, existingRemote);
      }

      final jsonPayload = jsonEncode(toSave.toJson());

      // 1. Save Group Session document
      final groupUri = Uri.parse('$firebaseBaseUrl/groups/${toSave.id}.json');
      final groupResp = await http
          .put(
            groupUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonPayload,
          )
          .timeout(const Duration(seconds: 4));

      // 2. Map 6-digit PIN to Group ID for instant lookup
      final pinUri = Uri.parse('$firebaseBaseUrl/pins/$cleanPin.json');
      await http
          .put(
            pinUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(toSave.id),
          )
          .timeout(const Duration(seconds: 4));

      if (groupResp.statusCode >= 200 && groupResp.statusCode < 300) {
        isCloudHealthy = true;
        lastSyncedAt = DateTime.now();
        debugPrint(
          '☁️ [CloudSync] Synced group ${toSave.id} (PIN: ${toSave.pinCode}, Members: ${toSave.members.length}, Matches: ${toSave.matchedRestaurantIds.length})',
        );
      }
    } catch (e) {
      isCloudHealthy = false;
      debugPrint(
        '⚠️ [CloudSync] Cloud push notice: $e (Falling back to local in-memory state)',
      );
    }
    return toSave;
  }

  /// Look up a group by 6-digit PIN code from the cloud
  Future<GroupSession?> fetchGroupByPin(String pinCode) async {
    try {
      final clean = _cleanPin(pinCode);
      final pinUri = Uri.parse('$firebaseBaseUrl/pins/$clean.json');
      final pinResp =
          await http.get(pinUri).timeout(const Duration(seconds: 4));

      if (pinResp.statusCode == 200 &&
          pinResp.body != 'null' &&
          pinResp.body.isNotEmpty) {
        final groupId = jsonDecode(pinResp.body) as String;
        isCloudHealthy = true;
        lastSyncedAt = DateTime.now();
        return await fetchGroupById(groupId);
      }
    } catch (e) {
      isCloudHealthy = false;
      debugPrint('⚠️ [CloudSync] Could not fetch PIN from cloud: $e');
    }
    return null;
  }

  /// Fetch a specific group by ID from the cloud
  Future<GroupSession?> fetchGroupById(String groupId) async {
    try {
      final groupUri = Uri.parse('$firebaseBaseUrl/groups/$groupId.json');
      final groupResp =
          await http.get(groupUri).timeout(const Duration(seconds: 4));

      if (groupResp.statusCode == 200 &&
          groupResp.body != 'null' &&
          groupResp.body.isNotEmpty) {
        final decoded = jsonDecode(groupResp.body);
        if (decoded is Map<String, dynamic>) {
          isCloudHealthy = true;
          lastSyncedAt = DateTime.now();
          return GroupSession.fromJson(decoded);
        }
      }
    } catch (e) {
      isCloudHealthy = false;
      debugPrint('⚠️ [CloudSync] Error fetching group $groupId: $e');
    }
    return null;
  }

  /// Start watching a group in real time across devices (polls cloud every 1.2s)
  void startWatchingGroup(
    String groupId, {
    required void Function(GroupSession) onUpdate,
  }) {
    stopWatchingGroup();
    _currentlyWatchedGroupId = groupId;

    // Immediate first fetch
    fetchGroupById(groupId).then((latest) {
      if (latest != null && _currentlyWatchedGroupId == groupId) {
        onUpdate(latest);
        _activeGroupStreamController.add(latest);
      }
    });

    // High-frequency 1.2s poll for instant live multiplayer experience
    _pollingTimer =
        Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      if (_currentlyWatchedGroupId != groupId) {
        timer.cancel();
        return;
      }
      if (_isSyncInFlight) return;
      _isSyncInFlight = true;
      try {
        final latest = await fetchGroupById(groupId);
        if (latest != null && _currentlyWatchedGroupId == groupId) {
          onUpdate(latest);
          _activeGroupStreamController.add(latest);
        }
      } finally {
        _isSyncInFlight = false;
      }
    });
  }

  /// Stop watching when the session ends or user leaves
  void stopWatchingGroup() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentlyWatchedGroupId = null;
    _isSyncInFlight = false;
  }
}
