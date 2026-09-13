import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../call_logs/screens/call_logs_screen.dart';
import '../../contacts/screens/contacts_screen.dart';
import '../../calls/providers/calls_providers.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _fabOpen = false;
  final _searchController = TextEditingController();
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      _fabOpen ? _fabAnimController.forward() : _fabAnimController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingCallProvider, (previous, next) {
      next.whenData((call) {
        if (call != null) {
          context.push('/incoming-call/${call.id}');
        }
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        // tapping outside the FAB closes it if open
        onTap: _fabOpen ? _toggleFab : null,
        child: IndexedStack(
          index: _selectedIndex,
          children: const [CallLogsScreen(), ContactsScreen()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.history), label: 'Recent'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contacts'),
        ],
      ),
      floatingActionButton: _buildSpeedDialFab(),
    );
  }

  Widget _buildSpeedDialFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScaleTransition(
          scale: _fabAnimController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton.extended(
              heroTag: 'addContactFab',
              onPressed: () {
                _toggleFab();
                context.push('/add-contact');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Contact'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
        ),
        ScaleTransition(
          scale: _fabAnimController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton.extended(
              heroTag: 'quickCallFab',
              onPressed: () {
                _toggleFab();
                context.push('/quick-call');
              },
              icon: const Icon(Icons.call),
              label: const Text('Quick Call'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'mainFab',
          onPressed: _toggleFab,
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0, // 45° rotation, + becomes x
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
