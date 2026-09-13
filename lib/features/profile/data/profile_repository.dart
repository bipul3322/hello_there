import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((d) => d.data());
  }

  /// Reserves a username and updates the profile atomically.
  /// Throws if the username is already taken by someone else.
  Future<void> setUsername({
    required String uid,
    required String username,
    required String currentUsername,
  }) async {
    final normalized = username.trim().toLowerCase();

    await _db.runTransaction((txn) async {
      final newRef = _db.collection('usernames').doc(normalized);
      final newSnap = await txn.get(newRef);

      if (newSnap.exists && newSnap.data()?['uid'] != uid) {
        throw Exception('username-taken');
      }

      // free the old reservation if it existed and differs
      if (currentUsername.isNotEmpty && currentUsername != normalized) {
        final oldRef = _db.collection('usernames').doc(currentUsername);
        txn.delete(oldRef);
      }

      txn.set(newRef, {'uid': uid});
      txn.update(_db.collection('users').doc(uid), {'username': normalized});
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String bio,
    String? photoUrl,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'bio': bio,
      'photoUrl': ?photoUrl,
    });
  }

  /// Finds a user by exact username, for the Add Contact flow.
  Future<Map<String, dynamic>?> findByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    final snap = await _db.collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'uid': snap.docs.first.id, ...snap.docs.first.data()};
  }
}