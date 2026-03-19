import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/sensor_reading.dart';
import '../models/device_fault.dart';
import 'serial_port_service.dart';

class SerialPortServiceImpl implements SerialPortService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _portSubscription;
  String _serialBuffer = '';
  ConnectionStatus _status = ConnectionStatus.disconnected;

  final _lineController    = StreamController<String>.broadcast();
  final _sensorController  = StreamController<SensorReading>.broadcast();
  final _faultController   = StreamController<DeviceFault>.broadcast();
  final _messageController = StreamController<String>.broadcast();
  final _errorController   = StreamController<String>.broadcast();

  static const _deviceMessages = [
    'STARTED', 'STOPPED', 'READY', 'FAULTS_CLEARED', 'NO_FAULTS',
    '--- STATUS ---', '--------------',
  ];

  @override
  ConnectionStatus get status => _status;

  @override
  bool get isConnected => _status == ConnectionStatus.connected;

  @override
  List<String> scanPorts() => SerialPort.availablePorts;

  @override
  Future<bool> connect(String portName, {int baudRate = 9600}) async {
    if (_status == ConnectionStatus.connected) {
      await disconnect();
    }

    _status = ConnectionStatus.connecting;
    _messageController.add('⏳ $portName bağlanılıyor...');

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      _port = SerialPort(portName);

      if (!_port!.isOpen && !_port!.openReadWrite()) {
        final err = SerialPort.lastError;
        _status = ConnectionStatus.error;

        final errStr = err.toString().toLowerCase();
        if (errStr.contains('access') || errStr.contains('denied') || errStr.contains('busy')) {
          _errorController.add('Port başka bir uygulama tarafından kullanılıyor: $portName');
        } else if (errStr.contains('not found') || errStr.contains('no such')) {
          _errorController.add('Port bulunamadı: $portName — Cihaz bağlı mı?');
        } else if (errStr.contains('permission')) {
          _errorController.add('Port erişim izni yok: $portName');
        } else {
          _errorController.add('Port açılamadı: $err');
        }

        _port?.dispose();
        _port = null;
        return false;
      }

      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;
      _port!.config = config;

      await Future.delayed(const Duration(milliseconds: 50));

      _reader = SerialPortReader(_port!);
      _portSubscription = _reader!.stream.listen(
        _onDataReceived,
        onError: (error) {
          _errorController.add('Okuma hatası: $error');
          disconnect();
        },
        onDone: () {
          _errorController.add('Port bağlantısı beklenmedik şekilde kesildi');
          disconnect();
        },
      );

      _status = ConnectionStatus.connected;
      _messageController.add('✅ $portName bağlandı ($baudRate baud)');
      return true;
    } on SerialPortError catch (e) {
      _status = ConnectionStatus.error;
      _errorController.add('Seri port hatası: ${e.message}');
      _port?.dispose();
      _port = null;
      return false;
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorController.add('Beklenmeyen bağlantı hatası: $e');
      _port?.dispose();
      _port = null;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _portSubscription?.cancel();
    } catch (_) {}
    _portSubscription = null;
    _reader = null;

    try {
      if (_port != null && _port!.isOpen) {
        _port!.close();
      }
    } catch (_) {}

    try {
      _port?.dispose();
    } catch (_) {}
    _port = null;

    _serialBuffer = '';
    _status = ConnectionStatus.disconnected;
    _messageController.add('🔌 Bağlantı kesildi');
  }

  @override
  Future<void> send(String data) async {
    if (_port == null || !_port!.isOpen) {
      _errorController.add('Port açık değil, komut gönderilemedi');
      return;
    }
    _port!.write(Uint8List.fromList(utf8.encode(data)));
  }

  @override
  Future<void> sendStart() => send('START\n');

  @override
  Future<void> sendStop() => send('STOP\n');

  @override
  Future<void> sendStatus() => send('STATUS\n');

  @override
  Future<void> sendFaults() => send('FAULTS\n');

  @override
  Future<void> sendClearFaults() => send('CLEAR\n');

  @override
  Stream<String> get onLineReceived => _lineController.stream;

  @override
  Stream<SensorReading> get onSensorData => _sensorController.stream;

  @override
  Stream<DeviceFault> get onFault => _faultController.stream;

  @override
  Stream<String> get onDeviceMessage => _messageController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  void _onDataReceived(Uint8List data) {
    final incoming = utf8.decode(data, allowMalformed: true);
    _serialBuffer += incoming;

    while (_serialBuffer.contains('\n')) {
      final idx = _serialBuffer.indexOf('\n');
      final line = _serialBuffer.substring(0, idx).trim();
      _serialBuffer = _serialBuffer.substring(idx + 1);

      if (line.isNotEmpty) {
        _processLine(line);
      }
    }
  }

  void _processLine(String line) {
    _lineController.add(line);

    if (line.startsWith('HANDSHAKE:')) {
      _messageController.add(line);
      return;
    }

    if (line.startsWith('FAULT:')) {
      final fault = DeviceFault.tryParse(line);
      if (fault != null) {
        _faultController.add(fault);
      }
      return;
    }

    if (_isDeviceMessage(line)) {
      _messageController.add(line);
      return;
    }

    if (line.contains(':') && !line.contains(',')) {
      _messageController.add(line);
      return;
    }

    if (line.trimLeft().startsWith('E') && line.contains('ago)')) {
      _messageController.add(line);
      return;
    }

    _tryParseSensorData(line);
  }

  bool _isDeviceMessage(String line) {
    for (final msg in _deviceMessages) {
      if (line.startsWith(msg)) return true;
    }
    if (line.startsWith('ACTIVE_FAULTS:')) return true;
    return false;
  }

  void _tryParseSensorData(String line) {
    final parts = line.split(',');
    if (parts.length < 4) return;

    try {
      final condenserTemp = double.parse(parts[0].trim());
      final waterTemp = double.parse(parts[1].trim());
      final evapTemp = double.parse(parts[2].trim());
      final evapPressure = double.parse(parts[3].trim());
      final saturationTemp = parts.length >= 5
          ? double.parse(parts[4].trim())
          : 0.0;

      _sensorController.add(SensorReading(
        time: DateTime.now(),
        condenserTemp: condenserTemp,
        waterTemp: waterTemp,
        evapTemp: evapTemp,
        evapPressure: evapPressure,
        saturationTemp: saturationTemp,
      ));
    } catch (_) {
    }
  }

  @override
  void dispose() {
    disconnect();
    _lineController.close();
    _sensorController.close();
    _faultController.close();
    _messageController.close();
    _errorController.close();
  }
}