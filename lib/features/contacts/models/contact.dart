class Contact {
  final String id;
  final String? uid;
  final String name;
  final String? photoUrl;
  final String? phone;
  final bool isAppUser;

  Contact({
    required this.id,
    this.uid,
    required this.name,
    this.photoUrl,
    this.phone,
    this.isAppUser = false,
  });

  factory Contact.fromMap(String id, Map<String, dynamic> map) {
    return Contact(
      id: id,
      uid: map['uid'],
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      isAppUser: map['isAppUser'] ?? false,
    );
  }
}