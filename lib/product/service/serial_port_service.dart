import 'dart:async';
import '../models/sensor_reading.dart';
import '../models/device_fault.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

abstract class SerialPortService {
  ConnectionStatus get status;

  bool get isConnected;

  List<String> scanPorts();

  Future<bool> connect(String portName, {int baudRate = 9600});

  Future<void> disconnect();

  Future<void> send(String data);

  Future<void> sendStart() => send('START\n');

  Future<void> sendStop() => send('STOP\n');

  Future<void> sendStatus() => send('STATUS\n');

  Future<void> sendFaults() => send('FAULTS\n');

  Future<void> sendClearFaults() => send('CLEAR\n');

  Stream<String> get onLineReceived;

  Stream<SensorReading> get onSensorData;

  Stream<DeviceFault> get onFault;

  Stream<String> get onDeviceMessage;

  Stream<String> get onError;

  void dispose();
}