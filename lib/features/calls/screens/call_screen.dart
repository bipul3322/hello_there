import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../call_logs/models/call_log_entry.dart';
import '../models/call_session.dart';
import '../providers/calls_providers.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String callId;
  final String role; // 'caller' or 'callee'
  const CallScreen({super.key, required this.callId, required this.role});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _durationTimer;
  Timer? _connectSimTimer;
  Duration _elapsed = Duration.zero;
  bool _connected = false;
  bool _muted = false;
  bool _speakerOn = false;
  bool _ended = false;
  StreamSubscription? _callSub;
  CallSession? _call;
  Timer? _ringTimeout;

  @override
  void initState() {
    super.initState();
    _callSub = ref
        .read(callsRepoProvider)
        .watchCall(widget.callId)
        .listen(_onCallUpdate);
    if (widget.role == 'callee') {
      _startSimulatedConnect();
    } else {
      _ringTimeout = Timer(const Duration(seconds: 30), () {
        if (!_connected && !_ended) _finishCall();
      });
    }
  }

  void _onCallUpdate(CallSession? call) {
    if (call == null || !mounted) return;
    setState(() => _call = call);
    if (call.status == CallStatus.accepted &&
        !_connected &&
        widget.role == 'caller') {
      _ringTimeout?.cancel();
      _startSimulatedConnect();
    }
    if ((call.status == CallStatus.declined ||
            call.status == CallStatus.ended) &&
        !_ended) {
      _finishCall(remoteEnded: true);
    }
  }

  void _startSimulatedConnect() {
    // TODO: swap this block for a real RTC SDK connect callback later
    _connectSimTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _connected = true);
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    });
  }

  Future<void> _finishCall({bool remoteEnded = false}) async {
    if (_ended) return;
    _ended = true;
    _durationTimer?.cancel();
    _connectSimTimer?.cancel();

    final me = ref.read(authStateProvider).value;
    final call = _call;
    if (me != null && call != null) {
      if (!remoteEnded) {
        await ref
            .read(callsRepoProvider)
            .updateStatus(widget.callId, CallStatus.ended);
      }
      final isCaller = call.callerId == me.uid;
      await ref
          .read(callsRepoProvider)
          .writeCallLog(
            forUserId: me.uid,
            contactId: isCaller ? call.calleeId : call.callerId,
            contactName: isCaller ? call.calleeName : call.callerName,
            type: call.type,
            direction: isCaller
                ? CallDirection.outgoing
                : CallDirection.incoming,
            timestamp: call.createdAt,
            duration: _elapsed,
          );
    }
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _durationTimer?.cancel();
    _connectSimTimer?.cancel();
    _ringTimeout?.cancel();
    super.dispose();
  }

  String get _statusText {
    if (_connected) {
      final m = _elapsed.inMinutes.toString().padLeft(2, '0');
      final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    return widget.role == 'caller' ? 'Ringing...' : 'Connecting...';
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    final displayName = call == null
        ? ''
        : (widget.role == 'caller' ? call.calleeName : call.callerName);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 60,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0] : '?',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (call?.type == CallType.video) ...[
                  const SizedBox(height: 24),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Video preview\n(placeholder — SDK not wired yet)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      onTap: () => setState(() => _muted = !_muted),
                    ),
                    _controlButton(
                      icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
                      onTap: () => setState(() => _speakerOn = !_speakerOn),
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.red,
                      onPressed: _finishCall,
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton({required IconData icon, required VoidCallback onTap}) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white24,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}
