import 'dart:math';
import 'package:refrigeration_cycle_experiment_app/product/enums/refrigerant_fluid.dart';

abstract class SaturationHelper {
  SaturationHelper._();

  static double saturationTemp(double pressure, RefrigerantFluid fluid) {
    if (pressure <= 0) return double.nan;
    return switch (fluid) {
      RefrigerantFluid.r407c => _r407c(pressure),
      RefrigerantFluid.r22   => _r22(pressure),
      RefrigerantFluid.r134a => _r134a(pressure),
    };
  }

  static double superheat(double evapTemp, double pressure, RefrigerantFluid fluid) {
    final tSat = saturationTemp(pressure, fluid);
    if (tSat.isNaN) return double.nan;
    return evapTemp - tSat;
  }

  static double _r407c(double p) {
    final lp = log(p);
    return 0.25955 * (pow(lp, 3) - 1.41307 * pow(lp, 2) + 16.8028 * lp - 109.781);
  }

  static double _r22(double p) {
    final lp = log(p);
    return -1.0540 * pow(lp, 2) + 20.623 * lp - 45.870;
  }

  static double _r134a(double p) {
    final lp = log(p);
    return -1.5783 * pow(lp, 2) + 22.448 * lp - 55.921;
  }
}