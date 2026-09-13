import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/callable_list_item.dart';
import '../../auth/providers/auth_providers.dart';
import '../../calls/util/call_actions.dart';
import '../data/call_logs_repository.dart';
import '../models/call_log_entry.dart';

final callLogsRepoProvider = Provider((ref) => CallLogsRepository());

final callLogsStreamProvider = StreamProvider<List<CallLogEntry>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(callLogsRepoProvider).watchCallLogs(user.uid);
});

class CallLogsScreen extends ConsumerWidget {
  const CallLogsScreen({super.key});

  IconData _directionIcon(CallDirection d) {
    switch (d) {
      case CallDirection.incoming: return Icons.call_received;
      case CallDirection.outgoing: return Icons.call_made;
      case CallDirection.missed: return Icons.call_missed;
    }
  }

  Color _directionColor(CallDirection d) => d == CallDirection.missed ? Colors.red : Colors.grey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(callLogsStreamProvider);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) return const Center(child: Text('No recent calls'));

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return CallableListItem(
              avatar: CircleAvatar(
                backgroundImage:
                    log.contactPhotoUrl != null ? NetworkImage(log.contactPhotoUrl!) : null,
                child: log.contactPhotoUrl == null
                    ? Text(log.contactName.isNotEmpty ? log.contactName[0] : '?')
                    : null,
              ),
              title: Text(log.contactName),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_directionIcon(log.direction), size: 14, color: _directionColor(log.direction)),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMM d, h:mm a').format(log.timestamp)),
                ],
              ),
              trailing: Icon(
                log.type == CallType.video ? Icons.videocam : Icons.call,
                color: Colors.grey,
              ),
              // No dedicated contact object on hand here, so avatar tap
              // just opens the same call picker as the body for now.
              onAvatarTap: () {},
              onCall: (isVideo) => startCallWith(
                context, ref,
                contactId: log.contactId,
                contactName: log.contactName,
                type: isVideo ? CallType.video : CallType.audio,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}