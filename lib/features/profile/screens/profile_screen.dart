import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/profile_repository.dart';

final profileRepoProvider = Provider((ref) => ProfileRepository());

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _editing = false;
  String _currentUsername = '';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final data = await ref.read(profileRepoProvider).getProfile(uid);
    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _currentUsername = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final newUsername = _usernameController.text.trim().toLowerCase();
      if (newUsername != _currentUsername) {
        await ref.read(profileRepoProvider).setUsername(
              uid: uid,
              username: newUsername,
              currentUsername: _currentUsername,
            );
        _currentUsername = newUsername;
      }
      await ref.read(profileRepoProvider).updateProfile(
            uid: uid,
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
          );
      setState(() => _editing = false);
    } catch (e) {
      setState(() {
        _errorText = e.toString().contains('username-taken')
            ? 'That username is already taken'
            : 'Something went wrong. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Profile' : 'Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _nameController.text = _nameController.text; // no-op, keep as-is
                setState(() {
                  _editing = false;
                  _errorText = null;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _editing ? _buildEditView() : _buildInfoView(user),
        ),
      ),
    );
  }

  Widget _buildInfoView(user) {
    return Column(
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 48,
          child: Text(
            _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(_nameController.text, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('@${_usernameController.text}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        if (_bioController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_bioController.text, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 8),
        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
          ),
        ),
      ],
    );
  }

  Widget _buildEditView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              child: Text(
                _nameController.text.isNotEmpty
                    ? _nameController.text[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              helperText: 'Others find and add you using this. Unique, lowercase.',
              prefixText: '@',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Choose a username';
              if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v.trim())) {
                return '3-20 chars, letters/numbers/underscore only';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Status / Bio',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}