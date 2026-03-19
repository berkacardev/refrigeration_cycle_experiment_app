import 'package:equatable/equatable.dart';
import 'package:refrigeration_cycle_experiment_app/product/enums/fault_severity.dart';

class DeviceFault extends Equatable {
  final String code;
  final String message;
  final FaultSeverity severity;
  final DateTime timestamp;

  const DeviceFault({
    required this.code,
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  DeviceFault copyWith({
    String? code,
    String? message,
    FaultSeverity? severity,
    DateTime? timestamp,
  }) {
    return DeviceFault(
      code:      code      ?? this.code,
      message:   message   ?? this.message,
      severity:  severity  ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static DeviceFault? tryParse(String line) {
    if (!line.startsWith('FAULT:')) return null;
    final parts = line.split(':');
    if (parts.length < 3) return null;
    final code    = parts[1];
    final message = parts.sublist(2).join(':');
    return DeviceFault(
      code:      code,
      message:   message,
      severity:  _severityFromCode(code),
      timestamp: DateTime.now(),
    );
  }

  static FaultSeverity _severityFromCode(String code) {
    final num = int.tryParse(code.replaceAll('E', '')) ?? 0;
    if ([1, 2, 15, 20].contains(num))       return FaultSeverity.critical;
    if ([12, 13, 14].contains(num))          return FaultSeverity.danger;
    if ([3, 4, 5, 6, 17, 18].contains(num)) return FaultSeverity.error;
    return FaultSeverity.warning;
  }

  String get severityIcon => switch (severity) {
    FaultSeverity.critical => '🔴',
    FaultSeverity.danger   => '🟠',
    FaultSeverity.error    => '🟡',
    FaultSeverity.warning  => '⚪',
  };

  String get logText => '$severityIcon $code: $message';

  @override
  List<Object?> get props => [code];

  @override
  bool get stringify => true;
}