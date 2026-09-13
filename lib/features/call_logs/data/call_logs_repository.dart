import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_log_entry.dart';

class CallLogsRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<CallLogEntry>> watchCallLogs(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('callLogs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CallLogEntry.fromMap(d.id, d.data())).toList());
  }
}