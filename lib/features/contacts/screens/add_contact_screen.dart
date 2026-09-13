import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/screens/profile_screen.dart'; // profileRepoProvider

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _controller = TextEditingController();
  bool _isSearching = false;
  bool _isAdding = false;
  String? _error;
  Map<String, dynamic>? _foundUser;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _foundUser = null;
    });

    final result = await ref.read(profileRepoProvider).findByUsername(query);

    setState(() {
      _isSearching = false;
      if (result == null) {
        _error = 'No user found with that username';
      } else if (result['uid'] == ref.read(authStateProvider).value?.uid) {
        _error = "That's your own username";
      } else {
        _foundUser = result;
      }
    });
  }

  Future<void> _addContact() async {
    final me = ref.read(authStateProvider).value;
    if (me == null || _foundUser == null) return;

    setState(() => _isAdding = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(me.uid)
        .collection('contacts')
        .doc(_foundUser!['uid'])
        .set({
      'uid': _foundUser!['uid'],
      'name': _foundUser!['name'],
      'username': _foundUser!['username'],
      'photoUrl': _foundUser!['photoUrl'],
      'isAppUser': true,
      'addedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() => _isAdding = false);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isSearching ? null : _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            if (_isSearching) const Center(child: CircularProgressIndicator()),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_foundUser != null)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((_foundUser!['name'] ?? '?')[0].toUpperCase()),
                  ),
                  title: Text(_foundUser!['name'] ?? ''),
                  subtitle: Text('@${_foundUser!['username']}'),
                  trailing: _isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.person_add),
                          onPressed: _addContact,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}