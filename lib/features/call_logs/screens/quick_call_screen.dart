import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../contacts/screens/contacts_screen.dart'; // contactsStreamProvider

class QuickCallScreen extends ConsumerWidget {
  const QuickCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Call')),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('Add a contact first to call them'));
          }
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final c = contacts[index];
              return ListTile(
                leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
                title: Text(c.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () {
                        // Stub — will launch CallScreen once SDK is wired in
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      onPressed: () {
                        // Stub
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}