class UserModel {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isOnline,
    this.lastSeen,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      avatarUrl: data['avatarUrl'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen']?.toDate(),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'fcmToken': fcmToken,
    };
  }
}
