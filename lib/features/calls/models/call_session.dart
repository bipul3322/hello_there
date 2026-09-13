import '../../call_logs/models/call_log_entry.dart'; // reuse CallType, CallDirection

enum CallStatus { ringing, accepted, declined, cancelled, ended }

class CallSession {
  final String id;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String calleeName;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;

  CallSession({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.calleeName,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory CallSession.fromMap(String id, Map<String, dynamic> map) {
    return CallSession(
      id: id,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      calleeId: map['calleeId'] ?? '',
      calleeName: map['calleeName'] ?? '',
      type: map['type'] == 'video' ? CallType.video : CallType.audio,
      status: CallStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => CallStatus.ended,
      ),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}