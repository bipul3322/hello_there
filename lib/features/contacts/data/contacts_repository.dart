import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';

class ContactsRepository {
  final _db = FirebaseFirestore.instance;

  Stream<List<Contact>> watchContacts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Contact.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> updateContactName(
    String userId,
    String contactId,
    String name,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .update({'name': name});
  }

  Future<void> deleteContact(String userId, String contactId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }
}
