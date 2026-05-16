import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Tracks who is currently in a watch room (host + viewers).
class RoomPresenceService {
  static const _staleAfter = Duration(seconds: 90);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _memberRef(
    String roomId,
    String userId,
  ) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(userId);
  }

  Future<void> joinRoom({
    required String roomId,
    required bool isHost,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _memberRef(roomId, user.uid).set({
      'userId': user.uid,
      'displayName': user.displayName ?? user.email ?? 'Guest',
      'role': isHost ? 'host' : 'viewer',
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> heartbeat(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _memberRef(roomId, user.uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _memberRef(roomId, user.uid).delete();
  }

  /// Active viewers only (excludes host). Host uses this for the viewer count badge.
  Stream<int> activeViewerCount(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .where('role', isEqualTo: 'viewer')
        .snapshots()
        .map(_countActive);
  }

  int _countActive(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final cutoff = DateTime.now().subtract(_staleAfter);
    var count = 0;
    for (final doc in snapshot.docs) {
      final lastSeen = doc.data()['lastSeen'];
      if (lastSeen is Timestamp) {
        if (lastSeen.toDate().isAfter(cutoff)) count++;
      } else {
        count++;
      }
    }
    return count;
  }
}
