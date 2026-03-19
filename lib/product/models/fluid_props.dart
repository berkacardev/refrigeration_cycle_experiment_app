import 'package:equatable/equatable.dart';

class FluidProps extends Equatable {
  final String name;
  final double baseCondenserTemp;
  final double baseWaterTemp;
  final double baseEvapTemp;
  final double baseSaturationTemp;
  final double baseEvapPressure;

  const FluidProps({
    required this.name,
    required this.baseCondenserTemp,
    required this.baseWaterTemp,
    required this.baseEvapTemp,
    required this.baseSaturationTemp,
    required this.baseEvapPressure,
  });

  FluidProps copyWith({
    String? name,
    double? baseCondenserTemp,
    double? baseWaterTemp,
    double? baseEvapTemp,
    double? baseSaturationTemp,
    double? baseEvapPressure,
  }) {
    return FluidProps(
      name:                name                ?? this.name,
      baseCondenserTemp:   baseCondenserTemp   ?? this.baseCondenserTemp,
      baseWaterTemp:       baseWaterTemp       ?? this.baseWaterTemp,
      baseEvapTemp:        baseEvapTemp        ?? this.baseEvapTemp,
      baseSaturationTemp:  baseSaturationTemp  ?? this.baseSaturationTemp,
      baseEvapPressure:    baseEvapPressure    ?? this.baseEvapPressure,
    );
  }

  @override
  List<Object?> get props => [
    name,
    baseCondenserTemp,
    baseWaterTemp,
    baseEvapTemp,
    baseSaturationTemp,
    baseEvapPressure,
  ];

  @override
  bool get stringify => true;
}