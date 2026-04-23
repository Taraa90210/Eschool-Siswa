import 'package:eschool/data/models/chat/chatMessage.dart';
import 'package:image_picker/image_picker.dart';

class TempMessage {
  static ChatMessage create({
    required String message,
    required int senderId,
    required int receiverId,
    required List<XFile> attachments,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatId: 0, // temporary
      senderId: senderId,
      message: message,
      readAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      attachments: attachments.map((file) => 
        ChatMessageAttachment(
          id: 0,
          messageId: 0,
          file: file.path,
          fileType: file.name.split('.').last,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ).toList(),
    );
  }
}