enum RefrigerantFluid {
  r407c(
    label: 'R-407C',
    baseCondenserTemp: 55.0,
    baseWaterTemp: 30.0,
    baseEvapTemp: -5.0,
    baseSaturationTemp: -8.0,
    baseEvapPressure: 4.8,
  ),
  r22(
    label: 'R-22',
    baseCondenserTemp: 52.0,
    baseWaterTemp: 29.0,
    baseEvapTemp: -6.0,
    baseSaturationTemp: -9.5,
    baseEvapPressure: 4.3,
  ),
  r134a(
    label: 'R-134a',
    baseCondenserTemp: 48.0,
    baseWaterTemp: 28.0,
    baseEvapTemp: -4.0,
    baseSaturationTemp: -7.0,
    baseEvapPressure: 2.9,
  );

  const RefrigerantFluid({
    required this.label,
    required this.baseCondenserTemp,
    required this.baseWaterTemp,
    required this.baseEvapTemp,
    required this.baseSaturationTemp,
    required this.baseEvapPressure,
  });

  final String label;
  final double baseCondenserTemp;
  final double baseWaterTemp;
  final double baseEvapTemp;
  final double baseSaturationTemp;
  final double baseEvapPressure;

  static RefrigerantFluid? fromLabel(String label) {
    for (final f in values) {
      if (f.label == label) return f;
    }
    return null;
  }
}