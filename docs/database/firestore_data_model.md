# Firestore Data Model (Messenger-like App)

## 1. users (collection)
users/{userId}
- uid: string
- name: string
- email: string
- phone: string
- avatarUrl: string
- about: string
- lastSeen: Timestamp
- isOnline: bool
- fcmToken: string

## 2. chats (collection)
chats/{chatId}
- chatId: string
- isGroup: bool
- members: array<string>
- admins: array<string> (group only)
- lastMessage: map {
    text: string
    senderId: string
    timestamp: Timestamp
    type: string (text, image, video, file)
}
- createdAt: Timestamp
- updatedAt: Timestamp

## 3. messages (subcollection)
chats/{chatId}/messages/{messageId}
- messageId: string
- senderId: string
- text: string
- type: string (text, image, video, file)
- mediaUrl: string
- thumbnailUrl: string
- timestamp: Timestamp
- deliveredTo: array<string>
- readBy: array<string>
- replyTo: map? {
    messageId: string
    text: string
    senderId: string
}
- reactions: map<string, string>  
  // key = userId, value = emoji

## 4. typing (subcollection)
chats/{chatId}/typing/{userId}
- userId: string
- isTyping: bool

## 5. call_sessions (collection)
call_sessions/{callId}
- callerId: string
- calleeId: string
- type: string (audio, video)
- offer: map
- answer: map
- iceCandidates: array<map>
- status: string (ringing, accepted, ended)
- timestamp: Timestamp
