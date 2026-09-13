import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/callable_list_item.dart';
import '../../auth/providers/auth_providers.dart';
import '../../call_logs/models/call_log_entry.dart';
import '../../calls/util/call_actions.dart';
import '../../home/screens/home_shell.dart';
import '../data/contacts_repository.dart';
import '../models/contact.dart';

final contactsRepoProvider = Provider((ref) => ContactsRepository());

final contactsStreamProvider = StreamProvider<List<Contact>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(contactsRepoProvider).watchContacts(user.uid);
});

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsStreamProvider);
    final query = ref.watch(searchQueryProvider).toLowerCase();

    return contactsAsync.when(
      data: (contacts) {
        final filtered = query.isEmpty
            ? contacts
            : contacts.where((c) => c.name.toLowerCase().contains(query)).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No contacts found'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final contact = filtered[index];
            return CallableListItem(
              avatar: CircleAvatar(
                backgroundImage:
                    contact.photoUrl != null ? NetworkImage(contact.photoUrl!) : null,
                child: contact.photoUrl == null ? Text(contact.name[0]) : null,
              ),
              title: Text(contact.name),
              subtitle: contact.phone != null ? Text(contact.phone!) : null,
              onAvatarTap: () => context.push('/contact/${contact.id}', extra: contact),
              onCall: (isVideo) => startCallWith(
                context, ref,
                contactId: contact.uid ?? contact.id,
                contactName: contact.name,
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