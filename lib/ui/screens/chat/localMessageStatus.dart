import 'package:eschool/data/models/chat/chatMessage.dart';

class LocalMessageStatus {
  final String localId;
  final ChatMessage message;
  final bool isSending;
  final String? error;

  LocalMessageStatus({
    required this.localId,
    required this.message,
    this.isSending = true,
    this.error,
  });
}