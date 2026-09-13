import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../call_logs/models/call_log_entry.dart';
import '../models/call_session.dart';
import '../providers/calls_providers.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final String callId;
  const IncomingCallScreen({super.key, required this.callId});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  bool _handled =
      false; // true the instant Accept/Decline is tapped — stops the
  // auto-pop-on-status-change below from racing our own navigation

  @override
  Widget build(BuildContext context) {
    final callAsync = ref.watch(callSessionProvider(widget.callId));

    return callAsync.when(
      data: (call) {
        if (!_handled && (call == null || call.status != CallStatus.ringing)) {
          if (call != null) {
            final me = ref.read(authStateProvider).value;
            if (me != null) {
              ref
                  .read(callsRepoProvider)
                  .writeCallLog(
                    forUserId: me.uid,
                    contactId: call.callerId,
                    contactName: call.callerName,
                    type: call.type,
                    direction: CallDirection.missed,
                    timestamp: call.createdAt,
                    duration: Duration.zero,
                  );
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && context.canPop()) context.pop();
          });
          return const SizedBox.shrink();
        }
        if (call == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(),
                  CircleAvatar(
                    radius: 60,
                    child: Text(
                      call.callerName.isNotEmpty ? call.callerName[0] : '?',
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    call.callerName,
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  Text(
                    call.type == CallType.video
                        ? 'Incoming video call'
                        : 'Incoming audio call',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          FloatingActionButton(
                            backgroundColor: Colors.red,
                            onPressed: () async {
                              setState(() => _handled = true);
                              final me = ref.read(authStateProvider).value;
                              await ref
                                  .read(callsRepoProvider)
                                  .updateStatus(
                                    widget.callId,
                                    CallStatus.declined,
                                  );
                              if (me != null) {
                                await ref
                                    .read(callsRepoProvider)
                                    .writeCallLog(
                                      forUserId: me.uid,
                                      contactId: call.callerId,
                                      contactName: call.callerName,
                                      type: call.type,
                                      direction: CallDirection.missed,
                                      timestamp: call.createdAt,
                                      duration: Duration.zero,
                                    );
                              }
                              if (context.mounted) context.pop();
                            },
                            child: const Icon(Icons.call_end),
                          ),
                          const Text(
                            'Decline',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          FloatingActionButton(
                            backgroundColor: Colors.green,
                            onPressed: () async {
                              setState(() => _handled = true);
                              await ref
                                  .read(callsRepoProvider)
                                  .updateStatus(
                                    widget.callId,
                                    CallStatus.accepted,
                                  );
                              if (context.mounted) {
                                context.pushReplacement(
                                  '/call/${widget.callId}?role=callee',
                                );
                              }
                            },
                            child: const Icon(Icons.call),
                          ),
                          const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
