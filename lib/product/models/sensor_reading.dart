import 'package:equatable/equatable.dart';

class SensorReading extends Equatable {
  final DateTime time;
  final double condenserTemp;
  final double waterTemp;
  final double evapTemp;
  final double saturationTemp;
  final double evapPressure;

  const SensorReading({
    required this.time,
    required this.condenserTemp,
    required this.waterTemp,
    required this.evapTemp,
    required this.saturationTemp,
    required this.evapPressure,
  });

  double get superheat => evapTemp - saturationTemp;

  SensorReading copyWith({
    DateTime? time,
    double? condenserTemp,
    double? waterTemp,
    double? evapTemp,
    double? saturationTemp,
    double? evapPressure,
  }) {
    return SensorReading(
      time:           time           ?? this.time,
      condenserTemp:  condenserTemp  ?? this.condenserTemp,
      waterTemp:      waterTemp      ?? this.waterTemp,
      evapTemp:       evapTemp       ?? this.evapTemp,
      saturationTemp: saturationTemp ?? this.saturationTemp,
      evapPressure:   evapPressure   ?? this.evapPressure,
    );
  }

  @override
  List<Object?> get props => [
    time,
    condenserTemp,
    waterTemp,
    evapTemp,
    saturationTemp,
    evapPressure,
  ];

  @override
  bool get stringify => true;
}