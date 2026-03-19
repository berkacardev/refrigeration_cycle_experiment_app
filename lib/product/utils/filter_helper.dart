import 'dart:math';

class FilterHelper {
  FilterHelper._();

  static double lowPass(double current, double previous, double alpha) {
    return previous + alpha * (current - previous);
  }

  static List<double> lowPassBuffer(List<double> data, double alpha) {
    if (data.isEmpty) return [];
    final result = <double>[data.first];
    for (int i = 1; i < data.length; i++) {
      result.add(lowPass(data[i], result[i - 1], alpha));
    }
    return result;
  }

  static double highPass(double current, double previous, double previousFiltered, double alpha) {
    return alpha * (previousFiltered + current - previous);
  }

  static List<double> highPassBuffer(List<double> data, double alpha) {
    if (data.length < 2) return List.from(data);
    final result = <double>[data.first];
    for (int i = 1; i < data.length; i++) {
      result.add(highPass(data[i], data[i - 1], result[i - 1], alpha));
    }
    return result;
  }

  static double movingAverage(List<double> data, int windowSize) {
    if (data.isEmpty) return 0;
    final start = max(0, data.length - windowSize);
    final window = data.sublist(start);
    return window.reduce((a, b) => a + b) / window.length;
  }

  static List<double> movingAverageBuffer(List<double> data, int windowSize) {
    if (data.isEmpty) return [];
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - windowSize + 1);
      final window = data.sublist(start, i + 1);
      result.add(window.reduce((a, b) => a + b) / window.length);
    }
    return result;
  }

  static double exponentialMovingAverage(double current, double previousEma, double alpha) {
    return alpha * current + (1 - alpha) * previousEma;
  }

  static List<double> exponentialMovingAverageBuffer(List<double> data, double alpha) {
    if (data.isEmpty) return [];
    final result = <double>[data.first];
    for (int i = 1; i < data.length; i++) {
      result.add(exponentialMovingAverage(data[i], result[i - 1], alpha));
    }
    return result;
  }

  static double median(List<double> data, int windowSize) {
    if (data.isEmpty) return 0;
    final start = max(0, data.length - windowSize);
    final window = List<double>.from(data.sublist(start))..sort();
    final mid = window.length ~/ 2;
    if (window.length.isOdd) return window[mid];
    return (window[mid - 1] + window[mid]) / 2;
  }

  static List<double> medianBuffer(List<double> data, int windowSize) {
    if (data.isEmpty) return [];
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - windowSize + 1);
      final window = List<double>.from(data.sublist(start, i + 1))..sort();
      final mid = window.length ~/ 2;
      if (window.length.isOdd) {
        result.add(window[mid]);
      } else {
        result.add((window[mid - 1] + window[mid]) / 2);
      }
    }
    return result;
  }

  static double clamp(double value, double minVal, double maxVal) {
    return value.clamp(minVal, maxVal);
  }

  static double deadband(double value, double previous, double threshold) {
    return (value - previous).abs() < threshold ? previous : value;
  }

  static List<double> deadbandBuffer(List<double> data, double threshold) {
    if (data.isEmpty) return [];
    final result = <double>[data.first];
    for (int i = 1; i < data.length; i++) {
      result.add(deadband(data[i], result[i - 1], threshold));
    }
    return result;
  }

  static double rateLimit(double current, double previous, double maxRate) {
    final diff = current - previous;
    if (diff.abs() > maxRate) {
      return previous + maxRate * diff.sign;
    }
    return current;
  }

  static List<double> rateLimitBuffer(List<double> data, double maxRate) {
    if (data.isEmpty) return [];
    final result = <double>[data.first];
    for (int i = 1; i < data.length; i++) {
      result.add(rateLimit(data[i], result[i - 1], maxRate));
    }
    return result;
  }

  static double kalmanSingle(
      double measurement,
      double previousEstimate,
      double previousError,
      double processNoise,
      double measurementNoise,
      ) {
    final predictedError = previousError + processNoise;
    final kalmanGain = predictedError / (predictedError + measurementNoise);
    return previousEstimate + kalmanGain * (measurement - previousEstimate);
  }

  static double kalmanError(double previousError, double processNoise, double measurementNoise) {
    final predictedError = previousError + processNoise;
    final kalmanGain = predictedError / (predictedError + measurementNoise);
    return (1 - kalmanGain) * predictedError;
  }

  static double standardDeviation(List<double> data, int windowSize) {
    if (data.length < 2) return 0;
    final start = max(0, data.length - windowSize);
    final window = data.sublist(start);
    final mean = window.reduce((a, b) => a + b) / window.length;
    final variance = window.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / window.length;
    return sqrt(variance);
  }

  static bool isSpikeDetected(List<double> data, int windowSize, double multiplier) {
    if (data.length < windowSize + 1) return false;
    final recent = data.sublist(0, data.length - 1);
    final stdDev = standardDeviation(recent, windowSize);
    final mean = movingAverage(recent, windowSize);
    return (data.last - mean).abs() > stdDev * multiplier;
  }
}