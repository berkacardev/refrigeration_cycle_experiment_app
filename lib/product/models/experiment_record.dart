import 'package:equatable/equatable.dart';
import 'package:refrigeration_cycle_experiment_app/product/models/sensor_reading.dart';

class ExperimentRecord extends Equatable {
  final String id;
  final DateTime date;
  final String fluid;

  final List<double>   condenserTempHistory = [];
  final List<double>   waterTempHistory     = [];
  final List<double>   evapTempHistory      = [];
  final List<double>   satTempHistory       = [];
  final List<double>   evapPressureHistory  = [];
  final List<DateTime> timestamps           = [];

  ExperimentRecord({
    required this.id,
    required this.date,
    required this.fluid,
  });

  void addReading(SensorReading r) {
    condenserTempHistory.add(r.condenserTemp);
    waterTempHistory.add(r.waterTemp);
    evapTempHistory.add(r.evapTemp);
    satTempHistory.add(r.saturationTemp);
    evapPressureHistory.add(r.evapPressure);
    timestamps.add(r.time);
  }

  int get dataCount => condenserTempHistory.length;

  double elapsedSecondsAt(int index) {
    if (index < 0 || index >= timestamps.length || timestamps.isEmpty) return 0;
    return timestamps[index].difference(timestamps.first).inMilliseconds / 1000.0;
  }

  double get totalDurationSec {
    if (timestamps.length < 2) return 0;
    return timestamps.last.difference(timestamps.first).inMilliseconds / 1000.0;
  }

  String get dateLabel {
    final d = date;
    return '${d.day.toString().padLeft(2, '0')}'
        '.${d.month.toString().padLeft(2, '0')}'
        '.${d.year.toString().substring(2)}';
  }

  ExperimentRecord copyWith({
    String? id,
    DateTime? date,
    String? fluid,
  }) {
    return ExperimentRecord(
      id:    id    ?? this.id,
      date:  date  ?? this.date,
      fluid: fluid ?? this.fluid,
    );
  }

  @override
  List<Object?> get props => [id];

  @override
  bool get stringify => true;
}