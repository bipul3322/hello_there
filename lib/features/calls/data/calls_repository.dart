import 'package:cloud_firestore/cloud_firestore.dart';
import '../../call_logs/models/call_log_entry.dart';
import '../models/call_session.dart';

class CallsRepository {
  final _db = FirebaseFirestore.instance;

  Future<String> startCall({
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required CallType type,
  }) async {
    final doc = await _db.collection('calls').add({
      'callerId': callerId,
      'callerName': callerName,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'type': type.name,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<CallSession?> watchCall(String callId) {
    return _db.collection('calls').doc(callId).snapshots().map(
        (d) => d.exists ? CallSession.fromMap(d.id, d.data()!) : null);
  }

  /// Any call currently ringing where I'm the callee.
  Stream<CallSession?> watchIncomingCall(String myUid) {
    return _db
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : CallSession.fromMap(snap.docs.first.id, snap.docs.first.data()));
  }

  Future<void> updateStatus(String callId, CallStatus status) async {
    await _db.collection('calls').doc(callId).update({'status': status.name});
  }

  Future<void> writeCallLog({
    required String forUserId,
    required String contactId,
    required String contactName,
    required CallType type,
    required CallDirection direction,
    required DateTime timestamp,
    required Duration duration,
  }) async {
    await _db.collection('users').doc(forUserId).collection('callLogs').add({
      'contactId': contactId,
      'contactName': contactName,
      'contactPhotoUrl': null,
      'type': type.name,
      'direction': direction.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': duration.inSeconds,
    });
  }
}