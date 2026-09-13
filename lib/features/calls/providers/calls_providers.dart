import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/calls_repository.dart';
import '../models/call_session.dart';

final callsRepoProvider = Provider((ref) => CallsRepository());

final callSessionProvider =
    StreamProvider.family<CallSession?, String>((ref, callId) {
  return ref.watch(callsRepoProvider).watchCall(callId);
});

final incomingCallProvider = StreamProvider<CallSession?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(callsRepoProvider).watchIncomingCall(uid);
});