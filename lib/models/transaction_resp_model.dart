import 'package:bb_factory_test_app/utils/hash_map_reverse_extension.dart';

class TransactionRespModel {
  TransactionRespModel({
    this.data,
    this.timeLine,
    this.total,
    this.weeks,
    this.totalEnergy,
  });

  factory TransactionRespModel.fromJson({required Map<String, dynamic> json}) {
    return TransactionRespModel(
      data: ((json['data'] as Map<String, dynamic>).justReverse()).entries,
      timeLine: json['timeline'] as Map<String, dynamic>,
      total: json['total'] as num,
      weeks: (json['weeks'] ?? -1) as int,
    );
  }

  TransactionRespModel copyWith({double? totalEnergy}) {
    return TransactionRespModel(
      data: data,
      timeLine: timeLine,
      total: total,
      weeks: weeks,
      totalEnergy: totalEnergy ?? this.totalEnergy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "data": data,
      "timeline": timeLine,
      "total": total,
      "totalEnergy": totalEnergy,
      "weeks": weeks,
    };
  }

  final Iterable<MapEntry<String, dynamic>>? data;
  final Map<String, dynamic>? timeLine;
  final num? total;
  final double? totalEnergy;
  final int? weeks;
}
