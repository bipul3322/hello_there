import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/contacts/screens/add_contact_screen.dart';
import '../../features/call_logs/screens/quick_call_screen.dart';
import '../../features/calls/screens/call_screen.dart';
import '../../features/calls/screens/incoming_call_screen.dart';
import '../../features/contacts/models/contact.dart';
import '../../features/contacts/screens/contact_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/add-contact',
        builder: (context, state) => const AddContactScreen(),
      ),
      GoRoute(
        path: '/quick-call',
        builder: (context, state) => const QuickCallScreen(),
      ),
      GoRoute(
        path: '/call/:callId',
        builder: (context, state) => CallScreen(
          callId: state.pathParameters['callId']!,
          role: state.uri.queryParameters['role'] ?? 'callee',
        ),
      ),
      GoRoute(
        path: '/incoming-call/:callId',
        builder: (context, state) =>
            IncomingCallScreen(callId: state.pathParameters['callId']!),
      ),
      GoRoute(
        path: '/contact-detail',
        builder: (context, state) =>
            ContactDetailScreen(contact: state.extra as Contact),
      ),
      GoRoute(
        path: '/contact/:contactId',
        builder: (context, state) =>
            ContactDetailScreen(contact: state.extra as Contact),
      ),
    ],
  );
});
