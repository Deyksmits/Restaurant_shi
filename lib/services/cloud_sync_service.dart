import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/group_session.dart';

/// CloudSyncService manages real-time group swiping synchronization between
/// multiple physical iPhones and web clients using Google Firebase Realtime / Firestore REST.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  /// User's live Firebase Realtime Database in europe-west1 (Belgium)
  static String firebaseBaseUrl =
      'https://tastematch-3e908-default-rtdb.europe-west1.firebasedatabase.app';

  Timer? _pollingTimer;
  String? _currentlyWatchedGroupId;
  final _activeGroupStreamController = StreamController<GroupSession>.broadcast();

  Stream<GroupSession> get groupUpdatesStream => _activeGroupStreamController.stream;

  /// Clean PIN code for storage keys (remove spaces)
  String _cleanPin(String pin) => pin.replaceAll(' ', '').trim();

  /// Save or update a group session in the cloud
  Future<bool> pushGroupToCloud(GroupSession group) async {
    try {
      final cleanPin = _cleanPin(group.pinCode);
      final jsonPayload = jsonEncode(group.toJson());

      // 1. Save Group Session document
      final groupUri = Uri.parse('$firebaseBaseUrl/groups/${group.id}.json');
      final groupResp = await http.put(
        groupUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonPayload,
      ).timeout(const Duration(seconds: 4));

      // 2. Map 6-digit PIN to Group ID for instant lookup
      final pinUri = Uri.parse('$firebaseBaseUrl/pins/$cleanPin.json');
      await http.put(
        pinUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(group.id),
      ).timeout(const Duration(seconds: 4));

      if (groupResp.statusCode >= 200 && groupResp.statusCode < 300) {
        debugPrint('☁️ [CloudSync] Successfully pushed group ${group.id} (PIN: ${group.pinCode}) to Firebase');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Cloud push notice: $e (Falling back to local in-memory state)');
    }
    return false;
  }

  /// Look up a group by 6-digit PIN code from the cloud
  Future<GroupSession?> fetchGroupByPin(String pinCode) async {
    try {
      final clean = _cleanPin(pinCode);
      final pinUri = Uri.parse('$firebaseBaseUrl/pins/$clean.json');
      final pinResp = await http.get(pinUri).timeout(const Duration(seconds: 4));

      if (pinResp.statusCode == 200 && pinResp.body != 'null' && pinResp.body.isNotEmpty) {
        final groupId = jsonDecode(pinResp.body) as String;
        return await fetchGroupById(groupId);
      }
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Could not fetch PIN from cloud: $e');
    }
    return null;
  }

  /// Fetch a specific group by ID from the cloud
  Future<GroupSession?> fetchGroupById(String groupId) async {
    try {
      final groupUri = Uri.parse('$firebaseBaseUrl/groups/$groupId.json');
      final groupResp = await http.get(groupUri).timeout(const Duration(seconds: 4));

      if (groupResp.statusCode == 200 && groupResp.body != 'null' && groupResp.body.isNotEmpty) {
        final decoded = jsonDecode(groupResp.body);
        if (decoded is Map<String, dynamic>) {
          return GroupSession.fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CloudSync] Error fetching group $groupId: $e');
    }
    return null;
  }

  /// Start watching a group in real time across devices (polls cloud every 1.5s)
  void startWatchingGroup(String groupId, {required void Function(GroupSession) onUpdate}) {
    stopWatchingGroup();
    _currentlyWatchedGroupId = groupId;

    // Immediate first fetch
    fetchGroupById(groupId).then((latest) {
      if (latest != null && _currentlyWatchedGroupId == groupId) {
        onUpdate(latest);
        _activeGroupStreamController.add(latest);
      }
    });

    // High-frequency 1.5s poll for instant live multiplayer experience
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_currentlyWatchedGroupId != groupId) {
        timer.cancel();
        return;
      }

      final latest = await fetchGroupById(groupId);
      if (latest != null && _currentlyWatchedGroupId == groupId) {
        onUpdate(latest);
        _activeGroupStreamController.add(latest);
      }
    });
  }

  /// Stop watching when the session ends or user leaves
  void stopWatchingGroup() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentlyWatchedGroupId = null;
  }
}
