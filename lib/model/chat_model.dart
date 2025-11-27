class ChatModel {
  final String chatId;
  final bool isGroup;
  final List<String> members;
  final List<String>? admins;
  final Map<String, dynamic>? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.chatId,
    required this.isGroup,
    required this.members,
    this.admins,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data, String id) {
    return ChatModel(
      chatId: id,
      isGroup: data['isGroup'] ?? false,
      members: List<String>.from(data['members'] ?? []),
      admins: data['admins'] != null ? List<String>.from(data['admins']) : null,
      lastMessage: data['lastMessage'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isGroup': isGroup,
      'members': members,
      'admins': admins,
      'lastMessage': lastMessage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
