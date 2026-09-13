import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../call_logs/models/call_log_entry.dart';
import '../../profile/screens/profile_screen.dart'; // profileRepoProvider
import '../../../core/permissions/call_permissions.dart';
import '../providers/calls_providers.dart';

Future<void> startCallWith(
  BuildContext context,
  WidgetRef ref, {
  required String contactId,
  required String contactName,
  required CallType type,
}) async {
  final granted = await CallPermissions.ensure(context, type);
  if (!granted) return;

  final me = ref.read(authStateProvider).value;
  if (me == null) return;
  final myProfile = await ref.read(profileRepoProvider).getProfile(me.uid);
  final callId = await ref.read(callsRepoProvider).startCall(
        callerId: me.uid,
        callerName: myProfile?['name'] ?? 'Unknown',
        calleeId: contactId,
        calleeName: contactName,
        type: type,
      );
  if (context.mounted) context.push('/call/$callId?role=caller');
}