// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class PendingFinalSubmit {
//   final int examId;
//   final Map<int, dynamic> answers; // snapshot lengkap
//   final String queuedAt; // ISO8601

//   PendingFinalSubmit({
//     required this.examId,
//     required this.answers,
//     required this.queuedAt,
//   });

//   Map<String, dynamic> toJson() => {
//         'examId': examId,
//         'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
//         'queuedAt': queuedAt,
//       };

//   static PendingFinalSubmit fromJson(Map<String, dynamic> j) =>
//       PendingFinalSubmit(
//         examId: j['examId'] as int,
//         answers: Map<String, dynamic>.from(j['answers'] as Map)
//             .map((k, v) => MapEntry(int.parse(k), v)),
//         queuedAt: j['queuedAt'] as String,
//       );
// }

// class FinalSubmitQueue {
//   static const _key = 'exam_data';

//   static Future<void> enqueue(PendingFinalSubmit item) async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_key);
//     final list = <Map<String, dynamic>>[];
//     if (raw != null && raw.isNotEmpty) {
//       (jsonDecode(raw) as List)
//           .forEach((e) => list.add(Map<String, dynamic>.from(e)));
//     }
//     final i = list.indexWhere((e) => e['examId'] == item.examId);
//     if (i >= 0)
//       list[i] = item.toJson();
//     else
//       list.add(item.toJson());
//     await prefs.setString(_key, jsonEncode(list));
//   }

//   static Future<List<PendingFinalSubmit>> all() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_key);
//     if (raw == null || raw.isEmpty) return [];
//     return (jsonDecode(raw) as List)
//         .map((e) => PendingFinalSubmit.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   static Future<void> remove(int examId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_key);
//     if (raw == null || raw.isEmpty) return;
//     final list = (jsonDecode(raw) as List).cast<Map>();
//     list.removeWhere((e) => e['examId'] == examId);
//     await prefs.setString(_key, jsonEncode(list));
//   }
// }
