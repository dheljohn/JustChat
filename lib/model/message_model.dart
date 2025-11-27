class MessageModel {
  final String messageId;
  final String senderId;
  final String? text;
  final String type; // text, image, video, file
  final String? mediaUrl;
  final String? thumbnailUrl;
  final DateTime timestamp;
  final List<String>? deliveredTo;
  final List<String>? readBy;
  final Map<String, dynamic>? replyTo;
  final Map<String, String>? reactions;

  MessageModel({
    required this.messageId,
    required this.senderId,
    this.text,
    required this.type,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.timestamp,
    this.deliveredTo,
    this.readBy,
    this.replyTo,
    this.reactions,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String id) {
    return MessageModel(
      messageId: id,
      senderId: data['senderId'],
      text: data['text'],
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      deliveredTo:
          data['deliveredTo'] != null
              ? List<String>.from(data['deliveredTo'])
              : [],
      readBy: data['readBy'] != null ? List<String>.from(data['readBy']) : [],
      replyTo: data['replyTo'],
      reactions:
          data['reactions'] != null
              ? Map<String, String>.from(data['reactions'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'timestamp': timestamp,
      'deliveredTo': deliveredTo,
      'readBy': readBy,
      'replyTo': replyTo,
      'reactions': reactions,
    };
  }
}
