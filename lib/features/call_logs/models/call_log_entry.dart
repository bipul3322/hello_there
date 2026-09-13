enum CallType { audio, video }
enum CallDirection { incoming, outgoing, missed }

class CallLogEntry {
  final String id;
  final String contactId;
  final String contactName;
  final String? contactPhotoUrl;
  final CallType type;
  final CallDirection direction;
  final DateTime timestamp;
  final Duration duration;

  CallLogEntry({
    required this.id,
    required this.contactId,
    required this.contactName,
    this.contactPhotoUrl,
    required this.type,
    required this.direction,
    required this.timestamp,
    required this.duration,
  });

  factory CallLogEntry.fromMap(String id, Map<String, dynamic> map) {
    return CallLogEntry(
      id: id,
      contactId: map['contactId'] ?? '',
      contactName: map['contactName'] ?? '',
      contactPhotoUrl: map['contactPhotoUrl'],
      type: map['type'] == 'video' ? CallType.video : CallType.audio,
      direction: CallDirection.values.firstWhere(
        (d) => d.name == map['direction'],
        orElse: () => CallDirection.outgoing,
      ),
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      duration: Duration(seconds: map['durationSeconds'] ?? 0),
    );
  }
}