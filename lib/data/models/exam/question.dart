import 'package:eschool/data/models/exam/answerOption.dart';

class Question {
  final int? id;
  final String? question;
  final String? type;
  final List<AnswerOption>? options;
  final String? choice_style;
  final int? marks;
  final String? image;
  final String? note;

  // int totalCorrectAnswer() {
  //   return (options ?? [])
  //       .where((option) => option.isAnswer == 1)
  //       .toList()
  //       .length;
  // }

  Question({
    this.id,
    this.question,
    this.type,
    List<AnswerOption>? options,
    this.marks,
    this.image,
    this.note,
    this.choice_style = 'numeric',
  }) : options = (type == 'multiple_choice' || type == 'true_false') ? options : null;

  Question copyWith({
    int? id,
    String? question,
    String? type,
    List<AnswerOption>? options,
    int? marks,
    String? image,
    String? note,
    String? choice_style,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: (type ?? this.type) == 'multiple_choice' || (type ?? this.type) == 'true_false' ? options ?? this.options : null,
      marks: marks ?? this.marks,
      image: image ?? this.image,
      note: note ?? this.note,
      choice_style: choice_style ?? this.choice_style,
    );
  }

  Question.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        question = json['question'] as String?,
        type = json['type'] as String?,
        options = ((json['type'] == 'multiple_choice' || json['type'] == 'true_false') && json['options'] != null)
            ? (json['options'] as List)
                .map((dynamic e) => AnswerOption.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        marks = json['marks'] as int?,
        image = json['image'] as String?,
        choice_style = json['choice_style'] as String?,
        note = json['note'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'type': type,
        'options': type == 'multiple_choice' || type == 'true_false' ? options?.map((e) => e.toJson()).toList() : null,
        'marks': marks,
        'image': image,
        'note': note,
      };

  @override
  String toString() {
    return '''
  Question(
    id: $id,
    question: "$question",
    type: "$type",
    marks: $marks,
    options: $options,
    image: "$image",
    note: "$note"
  )
  ''';
  }
}
