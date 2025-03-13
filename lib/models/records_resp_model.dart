import 'package:bb_factory_test_app/hive/models/transaction_hive_model.dart';

class RecordsRespModel {
  RecordsRespModel({
    required this.size,
    this.list,
  });

  RecordsRespModel copyWith({List<TransactionHiveModel>? list, int? size}) {
    return RecordsRespModel(
      size: size ?? this.size,
      list: list ?? this.list,
    );
  }

  final int size;
  final List<TransactionHiveModel>? list;
}
