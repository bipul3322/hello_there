import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../call_logs/models/call_log_entry.dart';
import '../../profile/screens/profile_screen.dart'; // profileRepoProvider
import '../../../core/permissions/call_permissions.dart';
import '../providers/calls_providers.dart';

Future<void> startCallFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String contactUid,
  required String contactName,
}) async {
  final type = await showModalBottomSheet<CallType>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Call $contactName',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.call),
            title: const Text('Audio Call'),
            onTap: () => Navigator.of(context).pop(CallType.audio),
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Video Call'),
            onTap: () => Navigator.of(context).pop(CallType.video),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (type == null || !context.mounted) return;

  final granted = await CallPermissions.ensure(context, type);
  if (!granted) return;

  final me = ref.read(authStateProvider).value;
  if (me == null) return;
  final myProfile = await ref.read(profileRepoProvider).getProfile(me.uid);
  final callId = await ref.read(callsRepoProvider).startCall(
        callerId: me.uid,
        callerName: myProfile?['name'] ?? 'Unknown',
        calleeId: contactUid,
        calleeName: contactName,
        type: type,
      );
  if (context.mounted) context.push('/call/$callId?role=caller');
}