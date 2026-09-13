import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/contact.dart';
import 'contacts_screen.dart'; // contactsRepoProvider

class ContactDetailScreen extends ConsumerStatefulWidget {
  final Contact contact;
  const ContactDetailScreen({super.key, required this.contact});

  @override
  ConsumerState<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final me = ref.read(authStateProvider).value;
    if (me == null) return;
    setState(() => _isSaving = true);
    await ref.read(contactsRepoProvider).updateContactName(
          me.uid,
          widget.contact.id,
          _nameController.text.trim(),
        );
    if (mounted) setState(() {
      _isSaving = false;
      _isEditing = false;
    });
  }

  Future<void> _delete() async {
    final me = ref.read(authStateProvider).value;
    if (me == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Remove ${widget.contact.name} from your contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(contactsRepoProvider).deleteContact(me.uid, widget.contact.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'Contact'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() {
              if (_isEditing) _nameController.text = contact.name;
              _isEditing = !_isEditing;
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      contact.photoUrl != null ? NetworkImage(contact.photoUrl!) : null,
                  child: contact.photoUrl == null
                      ? Text(contact.name.isNotEmpty ? contact.name[0] : '?',
                          style: const TextStyle(fontSize: 32))
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              if (_isEditing)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Display Name', border: OutlineInputBorder()),
                )
              else
                Text(contact.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              if (_isEditing)
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                )
              else
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Contact', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}