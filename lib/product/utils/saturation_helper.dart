import 'dart:math';
import 'package:refrigeration_cycle_experiment_app/product/enums/refrigerant_fluid.dart';

abstract class SaturationHelper {
  SaturationHelper._();

  static const double _atmBar = 1.01325;

  static double saturationTemp(double pressureGauge, RefrigerantFluid fluid) {
    final pressure = pressureGauge + _atmBar;
    if (pressure <= 0) return double.nan;
    return switch (fluid) {
      RefrigerantFluid.r407c => _r407c(pressure),
      RefrigerantFluid.r22   => _r22(pressure),
      RefrigerantFluid.r134a => _r134a(pressure),
    };
  }

  static double superheat(double evapTemp, double pressureGauge, RefrigerantFluid fluid) {
    final tSat = saturationTemp(pressureGauge, fluid);
    if (tSat.isNaN) return double.nan;
    return evapTemp - tSat;
  }

  static double _r407c(double p) {
    final lp = log(p);
    return 0.27881557 * pow(lp, 3) + 2.08721003 * pow(lp, 2) + 20.31920250 * lp - 36.89630567;
  }

  static double _r22(double p) {
    final lp = log(p);
    return 0.31520516 * pow(lp, 3) + 2.27084948 * pow(lp, 2) + 21.13686774 * lp - 41.08689398;
  }

  static double _r134a(double p) {
    final lp = log(p);
    return 0.03322643 * pow(lp, 3) + 2.36502464 * pow(lp, 2) + 21.34274239 * lp - 26.73342039;
  }
}