import '../../domain/entities/score_entity.dart';

class ScoreModel extends ScoreEntity {
  ScoreModel({
    super.id,
    required super.score,
    required super.dateTime,
  });

  factory ScoreModel.fromMap(Map<String, dynamic> map) {
    return ScoreModel(
      id: map['id'],
      score: map['score'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'score': score,
      'dateTime': dateTime.millisecondsSinceEpoch,
    };
  }
}
