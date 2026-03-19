import 'package:refrigeration_cycle_experiment_app/product/lang/tr.dart';

enum FilterType {
  none,
  lowPass,
  movingAverage,
  exponentialMovingAverage,
  median,
}

extension FilterTypeExtension on FilterType {
  String get label {
    switch (this) {
      case FilterType.none:
        return AppStrings.filterTypeNone;
      case FilterType.lowPass:
        return AppStrings.filterTypeLowPass;
      case FilterType.movingAverage:
        return AppStrings.filterTypeMovingAvg;
      case FilterType.exponentialMovingAverage:
        return AppStrings.filterTypeEma;
      case FilterType.median:
        return AppStrings.filterTypeMedian;
    }
  }

  String get shortLabel {
    switch (this) {
      case FilterType.none:
        return AppStrings.filterShortNone;
      case FilterType.lowPass:
        return AppStrings.filterShortLpf;
      case FilterType.movingAverage:
        return AppStrings.filterShortMa;
      case FilterType.exponentialMovingAverage:
        return AppStrings.filterShortEma;
      case FilterType.median:
        return AppStrings.filterShortMed;
    }
  }
}