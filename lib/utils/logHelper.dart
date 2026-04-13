import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void logRemoteMessageAndroid(RemoteMessage m, {String tag = 'FCM-ANDROID'}) {
  debugPrint('[$tag] ========= REMOTE MESSAGE =========');
  debugPrint('[$tag] messageId   : ${m.messageId}');
  debugPrint('[$tag] from        : ${m.from}');
  debugPrint('[$tag] sentTime    : ${m.sentTime}');
  debugPrint('[$tag] collapseKey : ${m.collapseKey}');
  debugPrint('[$tag] ttl         : ${m.ttl}');

  // notification block (kalau ada)
  final n = m.notification;
  if (n != null) {
    debugPrint('[$tag] ---- notification ----');
    debugPrint('[$tag] title  : ${n.title}');
    debugPrint('[$tag] body   : ${n.body}');
    if (n.android != null) {
      debugPrint('[$tag] channelId : ${n.android!.channelId}');
      debugPrint('[$tag] ticker    : ${n.android!.ticker}');
      debugPrint('[$tag] color     : ${n.android!.color}');
      debugPrint('[$tag] imageUrl  : ${n.android!.imageUrl}');
      debugPrint('[$tag] sound     : ${n.android!.sound}');
      debugPrint('[$tag] count     : ${n.android!.count}');
      debugPrint('[$tag] smallIcon : ${n.android!.smallIcon}');
      debugPrint('[$tag] clickAction: ${n.android!.clickAction}');
      debugPrint('[$tag] visibility : ${n.android!.visibility}');
      debugPrint('[$tag] priority   : ${n.android!.priority}');
    }
  } else {
    debugPrint('[$tag] (no notification block)');
  }

  // data map
  if (m.data.isNotEmpty) {
    debugPrint('[$tag] ---- data (${m.data.length}) ----');
    m.data.forEach((k, v) => debugPrint('[$tag] $k = $v'));
  } else {
    debugPrint('[$tag] (no data)');
  }

  // ukur latency (kalau server kirim "sent_at" ISO8601 di data)
  final sentAtStr = m.data['sent_at'];
  if (sentAtStr != null) {
    final sentAt = DateTime.tryParse(sentAtStr);
    if (sentAt != null) {
      debugPrint('[$tag] latency     : ${DateTime.now().difference(sentAt)}');
    }
  }

  debugPrint('[$tag] ==================================');
}
