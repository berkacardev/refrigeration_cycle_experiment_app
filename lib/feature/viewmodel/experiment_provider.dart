import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:refrigeration_cycle_experiment_app/product/enums/fault_severity.dart';
import 'package:refrigeration_cycle_experiment_app/product/enums/refrigerant_fluid.dart';
import 'package:refrigeration_cycle_experiment_app/product/models/device_fault.dart';
import 'package:refrigeration_cycle_experiment_app/product/models/experiment_record.dart';
import 'package:refrigeration_cycle_experiment_app/product/models/sensor_reading.dart';
import 'package:refrigeration_cycle_experiment_app/product/service/serial_port_service.dart';
import 'package:refrigeration_cycle_experiment_app/product/service/serial_port_service_impl.dart';
import 'package:refrigeration_cycle_experiment_app/product/utils/saturation_helper.dart';
import 'package:refrigeration_cycle_experiment_app/product/utils/filter_helper.dart';
import 'package:refrigeration_cycle_experiment_app/product/enums/filter_type.dart';

class ExperimentProvider extends ChangeNotifier {
  final SerialPortService _serialService = SerialPortServiceImpl();

  StreamSubscription<String>? _lineSub;
  StreamSubscription<SensorReading>? _sensorSub;
  StreamSubscription<DeviceFault>? _faultSub;
  StreamSubscription<String>? _messageSub;
  StreamSubscription<String>? _errorSub;

  ExperimentProvider() {
    _lineSub    = _serialService.onLineReceived.listen(_onLine);
    _sensorSub  = _serialService.onSensorData.listen(_onSensorData);
    _faultSub   = _serialService.onFault.listen(_onFault);
    _messageSub = _serialService.onDeviceMessage.listen(_onDeviceMessage);
    _errorSub   = _serialService.onError.listen(_onError);
    scanPorts();
  }

  RefrigerantFluid _selectedFluid = RefrigerantFluid.r407c;
  RefrigerantFluid get selectedFluid => _selectedFluid;

  void selectFluid(RefrigerantFluid fluid) {
    _selectedFluid = fluid;
    notifyListeners();
  }

  List<ExperimentRecord> _experiments = [];
  List<ExperimentRecord> get experiments => _experiments;

  final Set<int> _importedIndices = {};
  bool isImported(int index) => _importedIndices.contains(index);

  final Set<int> _finishedIndices = {};
  bool isFinished(int index) => _finishedIndices.contains(index);

  bool isRunningExperiment(int index) => _running && _runningExpIndex == index;

  bool get canExportCsv {
    if (_selectedExpIndex < 0 || _selectedExpIndex >= _experiments.length) return false;
    if (isRunningExperiment(_selectedExpIndex)) return false;
    return _experiments[_selectedExpIndex].dataCount > 0;
  }

  int _selectedExpIndex = -1;
  int get selectedExpIndex => _selectedExpIndex;

  int _runningExpIndex = -1;

  ExperimentRecord? get _runningExperiment =>
      _runningExpIndex >= 0 && _runningExpIndex < _experiments.length
          ? _experiments[_runningExpIndex]
          : null;

  bool get _viewingRunningExp => _selectedExpIndex == _runningExpIndex && _running;

  void selectExperiment(int index) {
    _selectedExpIndex = index;
    _loadExperimentData(index);
    notifyListeners();
  }

  void _loadExperimentData(int index) {
    if (index < 0 || index >= _experiments.length) return;
    final exp = _experiments[index];

    condenserTempBuf.clear();
    waterTempBuf.clear();
    evapTempBuf.clear();
    satTempBuf.clear();
    evapPressureBuf.clear();
    timestampBuf.clear();

    condenserTempBuf.addAll(exp.condenserTempHistory);
    waterTempBuf.addAll(exp.waterTempHistory);
    evapTempBuf.addAll(exp.evapTempHistory);
    satTempBuf.addAll(exp.satTempHistory);
    evapPressureBuf.addAll(exp.evapPressureHistory);
    timestampBuf.addAll(exp.timestamps);

    if (exp.dataCount > 0) {
      final last = exp.dataCount - 1;
      _latest = SensorReading(
        time: DateTime.now(),
        condenserTemp: exp.condenserTempHistory[last],
        waterTemp: exp.waterTempHistory[last],
        evapTemp: exp.evapTempHistory[last],
        evapPressure: exp.evapPressureHistory[last],
        saturationTemp: exp.satTempHistory[last],
      );
    } else {
      _latest = null;
    }
  }

  bool _running = false;
  bool get running => _running;

  DateTime? _startTime;
  Duration get elapsed => _startTime == null
      ? Duration.zero
      : DateTime.now().difference(_startTime!);

  String get elapsedLabel {
    final e = elapsed;
    final m = e.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = e.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get connected => _serialService.isConnected;

  String _selectedPort = '';
  String get selectedPort => _selectedPort;

  List<String> _availablePorts = [];
  List<String> get availablePorts => _availablePorts;

  void scanPorts() {
    _availablePorts = _serialService.scanPorts();
    if (_availablePorts.isNotEmpty && _selectedPort.isEmpty) {
      _selectedPort = _availablePorts.first;
    }
    notifyListeners();
  }

  void selectPort(String port) {
    _selectedPort = port;
    notifyListeners();
  }

  bool _connecting = false;
  bool get connecting => _connecting;

  Future<void> connect() async {
    if (_connecting) return;

    if (connected) {
      if (_running) {
        stopExperiment();
      }
      await _serialService.disconnect();
      _deviceVerified = false;
      _deviceId = '';
      notifyListeners();
      return;
    }

    if (_selectedPort.isEmpty) return;

    _connecting = true;
    notifyListeners();

    try {
      final success = await _serialService.connect(_selectedPort);
      if (success) {
        _skipCount = 0;
        await Future.delayed(const Duration(milliseconds: 800));
        await _serialService.send('PING\n');
      }
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  static const String _expectedHandshake = 'RCE_DEVICE_V1';

  bool _deviceVerified = false;
  bool get deviceVerified => _deviceVerified;

  String _deviceId = '';
  String get deviceId => _deviceId;

  final List<DeviceFault> _activeFaults = [];
  List<DeviceFault> get activeFaults => List.unmodifiable(_activeFaults);

  int get faultCount => _activeFaults.length;
  bool get hasFaults => _activeFaults.isNotEmpty;
  bool get hasCriticalFault => _activeFaults.any(
          (f) => f.severity == FaultSeverity.critical || f.severity == FaultSeverity.danger);

  DeviceFault? get lastFault => _activeFaults.isNotEmpty ? _activeFaults.last : null;

  final List<DeviceFault> _faultHistory = [];
  List<DeviceFault> get faultHistory => List.unmodifiable(_faultHistory);

  Future<void> clearFaults() async {
    await _serialService.sendClearFaults();
    _activeFaults.clear();
    notifyListeners();
  }

  Future<void> requestStatus() async => _serialService.sendStatus();
  Future<void> requestFaults() async  => _serialService.sendFaults();

  void _onLine(String line) {}

  int _skipCount = 0;
  static const int _skipFirst = 5;

  void _onSensorData(SensorReading reading) {
    if (_skipCount < _skipFirst) {
      _skipCount++;
      return;
    }

    final tSat = SaturationHelper.saturationTemp(reading.evapPressure, _selectedFluid);
    final sh   = SaturationHelper.superheat(reading.evapTemp, reading.evapPressure, _selectedFluid);

    final enriched = reading.copyWith(
      saturationTemp: tSat.isNaN ? reading.saturationTemp : tSat,
    );

    _latest = enriched;
    _runningExperiment?.addReading(enriched);

    if (_viewingRunningExp) {
      condenserTempBuf.add(enriched.condenserTemp);
      waterTempBuf.add(enriched.waterTemp);
      evapTempBuf.add(enriched.evapTemp);
      satTempBuf.add(enriched.saturationTemp);
      evapPressureBuf.add(enriched.evapPressure);
      timestampBuf.add(enriched.time);
    }

    final ts = _timestamp();
    logLines.insert(0,
        '$ts  Tk=${enriched.condenserTemp.toStringAsFixed(1)}  '
            'Te=${enriched.evapTemp.toStringAsFixed(1)}  '
            'Tsat=${tSat.isNaN ? "—" : tSat.toStringAsFixed(1)}  '
            'P=${enriched.evapPressure.toStringAsFixed(2)}  '
            'ΔT=${sh.isNaN ? "—" : sh.toStringAsFixed(1)}');
    _trimLog();
    notifyListeners();
  }

  void _onFault(DeviceFault fault) {
    _activeFaults.removeWhere((f) => f.code == fault.code);
    _activeFaults.add(fault);
    _faultHistory.add(fault);

    final ts = _timestamp();
    logLines.insert(0, '$ts  ${fault.logText}');
    _trimLog();
    notifyListeners();
  }

  void _onDeviceMessage(String message) {
    if (message.startsWith('HANDSHAKE:')) {
      final id = message.substring('HANDSHAKE:'.length).trim();
      _deviceId = id;
      _deviceVerified = (id == _expectedHandshake);
      notifyListeners();
      return;
    }

    final ts = _timestamp();
    logLines.insert(0, '$ts  📟 $message');
    _trimLog();
    notifyListeners();
  }

  void _onError(String error) {
    final ts = _timestamp();
    logLines.insert(0, '$ts  ❌ $error');
    _trimLog();
    notifyListeners();
  }

  void _trimLog() {
    while (logLines.length > 80) logLines.removeLast();
  }

  String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  SensorReading? _latest;
  SensorReading? get latest => _latest;

  final List<double>   condenserTempBuf  = [];
  final List<double>   waterTempBuf      = [];
  final List<double>   evapTempBuf       = [];
  final List<double>   satTempBuf        = [];
  final List<double>   evapPressureBuf   = [];
  final List<DateTime> timestampBuf      = [];

  FilterType _filterType = FilterType.none;
  FilterType get filterType => _filterType;

  double _filterAlpha = 0.3;
  double get filterAlpha => _filterAlpha;

  int _filterWindow = 5;
  int get filterWindow => _filterWindow;

  final Set<String> _filteredSensors = {};
  bool isSensorFiltered(String key) => _filteredSensors.contains(key);
  Set<String> get filteredSensors => Set.unmodifiable(_filteredSensors);

  static const allSensorKeys = [
    'condenserTemp',
    'waterTemp',
    'evapTemp',
    'evapPressure',
  ];

  void setFilterType(FilterType type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterAlpha(double alpha) {
    _filterAlpha = alpha.clamp(0.01, 1.0);
    notifyListeners();
  }

  void setFilterWindow(int window) {
    _filterWindow = window.clamp(2, 30);
    notifyListeners();
  }

  void toggleSensorFilter(String key) {
    if (_filteredSensors.contains(key)) {
      _filteredSensors.remove(key);
    } else {
      _filteredSensors.add(key);
    }
    notifyListeners();
  }

  void setAllSensorsFiltered(bool filtered) {
    if (filtered) {
      _filteredSensors.addAll(allSensorKeys);
    } else {
      _filteredSensors.clear();
    }
    notifyListeners();
  }

  List<double> _applyFilter(List<double> raw) {
    if (raw.isEmpty || _filterType == FilterType.none) return raw;
    switch (_filterType) {
      case FilterType.none:
        return raw;
      case FilterType.lowPass:
        return FilterHelper.lowPassBuffer(raw, _filterAlpha);
      case FilterType.movingAverage:
        return FilterHelper.movingAverageBuffer(raw, _filterWindow);
      case FilterType.exponentialMovingAverage:
        return FilterHelper.exponentialMovingAverageBuffer(raw, _filterAlpha);
      case FilterType.median:
        return FilterHelper.medianBuffer(raw, _filterWindow);
    }
  }

  List<double> get filteredCondenserTempBuf =>
      isSensorFiltered('condenserTemp') ? _applyFilter(condenserTempBuf) : condenserTempBuf;
  List<double> get filteredWaterTempBuf =>
      isSensorFiltered('waterTemp') ? _applyFilter(waterTempBuf) : waterTempBuf;
  List<double> get filteredEvapTempBuf =>
      isSensorFiltered('evapTemp') ? _applyFilter(evapTempBuf) : evapTempBuf;
  List<double> get filteredSatTempBuf =>
      isSensorFiltered('evapTemp') ? _applyFilter(satTempBuf) : satTempBuf;
  List<double> get filteredEvapPressureBuf =>
      isSensorFiltered('evapPressure') ? _applyFilter(evapPressureBuf) : evapPressureBuf;

  bool get isFilterActive => _filterType != FilterType.none && _filteredSensors.isNotEmpty;

  final List<String> logLines = [];

  Timer? _clockTicker;

  void startExperiment() {
    if (_running) return;
    if (!connected) return; // ── Guard: cannot start without connection ──
    _running = true;
    _startTime = DateTime.now();
    _skipCount = 0;

    condenserTempBuf.clear();
    waterTempBuf.clear();
    evapTempBuf.clear();
    satTempBuf.clear();
    evapPressureBuf.clear();
    timestampBuf.clear();
    _latest = null;

    final n = _experiments.length + 1;
    final rec = ExperimentRecord(
      id: 'DENEY_${n.toString().padLeft(3, '0')}',
      date: DateTime.now(),
      fluid: _selectedFluid.label,
    );
    _experiments = [..._experiments, rec];
    _selectedExpIndex = _experiments.length - 1;
    _runningExpIndex  = _experiments.length - 1;

    if (connected) _serialService.sendStart();

    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    notifyListeners();
  }

  void stopExperiment() {
    if (_runningExpIndex >= 0) {
      _finishedIndices.add(_runningExpIndex);
    }
    _running = false;
    _runningExpIndex = -1;
    _clockTicker?.cancel();

    if (connected) _serialService.sendStop();

    notifyListeners();
  }

  bool deleteExperiment(int index) {
    if (index < 0 || index >= _experiments.length) return false;
    if (isRunningExperiment(index)) return false;

    _experiments = List.from(_experiments)..removeAt(index);

    _importedIndices.remove(index);
    _finishedIndices.remove(index);

    final newImported = <int>{};
    for (final i in _importedIndices) {
      newImported.add(i > index ? i - 1 : i);
    }
    _importedIndices
      ..clear()
      ..addAll(newImported);

    final newFinished = <int>{};
    for (final i in _finishedIndices) {
      newFinished.add(i > index ? i - 1 : i);
    }
    _finishedIndices
      ..clear()
      ..addAll(newFinished);

    if (_runningExpIndex > index) {
      _runningExpIndex--;
    }

    if (_selectedExpIndex == index) {
      _selectedExpIndex = _experiments.isNotEmpty
          ? (_selectedExpIndex >= _experiments.length ? _experiments.length - 1 : _selectedExpIndex)
          : -1;
      if (_selectedExpIndex >= 0) {
        _loadExperimentData(_selectedExpIndex);
      } else {
        _latest = null;
        condenserTempBuf.clear();
        waterTempBuf.clear();
        evapTempBuf.clear();
        satTempBuf.clear();
        evapPressureBuf.clear();
        timestampBuf.clear();
      }
    } else if (_selectedExpIndex > index) {
      _selectedExpIndex--;
    }

    notifyListeners();
    return true;
  }

  Future<String?> exportCsv() async {
    if (_selectedExpIndex < 0 || _selectedExpIndex >= _experiments.length) return null;
    final exp = _experiments[_selectedExpIndex];
    if (exp.dataCount == 0) return null;

    final hasFilter = isFilterActive;
    final fCondenser = hasFilter && isSensorFiltered('condenserTemp') ? _applyFilter(exp.condenserTempHistory) : null;
    final fWater = hasFilter && isSensorFiltered('waterTemp') ? _applyFilter(exp.waterTempHistory) : null;
    final fEvap = hasFilter && isSensorFiltered('evapTemp') ? _applyFilter(exp.evapTempHistory) : null;
    final fSat = hasFilter && isSensorFiltered('evapTemp') ? _applyFilter(exp.satTempHistory) : null;
    final fPressure = hasFilter && isSensorFiltered('evapPressure') ? _applyFilter(exp.evapPressureHistory) : null;

    final buf = StringBuffer();
    var header = 'Zaman,Kondenser_Sicaklik_C,Su_Sicaklik_C,Evaporator_Sicaklik_C,Doyma_Sicaklik_C,Evaporator_Basinc_bar';
    if (fCondenser != null) header += ',Kondenser_Sicaklik_Filtreli';
    if (fWater != null) header += ',Su_Sicaklik_Filtreli';
    if (fEvap != null) header += ',Evaporator_Sicaklik_Filtreli';
    if (fSat != null) header += ',Doyma_Sicaklik_Filtreli';
    if (fPressure != null) header += ',Evaporator_Basinc_Filtreli';
    buf.writeln(header);

    for (int i = 0; i < exp.dataCount; i++) {
      final t = exp.timestamps[i];
      final ts = '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
      var row = '$ts,'
          '${exp.condenserTempHistory[i].toStringAsFixed(2)},'
          '${exp.waterTempHistory[i].toStringAsFixed(2)},'
          '${exp.evapTempHistory[i].toStringAsFixed(2)},'
          '${exp.satTempHistory[i].toStringAsFixed(2)},'
          '${exp.evapPressureHistory[i].toStringAsFixed(3)}';
      if (fCondenser != null) row += ',${fCondenser[i].toStringAsFixed(2)}';
      if (fWater != null) row += ',${fWater[i].toStringAsFixed(2)}';
      if (fEvap != null) row += ',${fEvap[i].toStringAsFixed(2)}';
      if (fSat != null) row += ',${fSat[i].toStringAsFixed(2)}';
      if (fPressure != null) row += ',${fPressure[i].toStringAsFixed(3)}';
      buf.writeln(row);
    }

    final filterSuffix = hasFilter ? '_${_filterType.shortLabel}' : '';
    final defaultName = '${exp.id}_${exp.fluid}$filterSuffix.csv';

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'CSV Olarak Kaydet',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (outputPath == null) return null;

    final file = File(outputPath);
    await file.writeAsString(buf.toString());

    final ts = _timestamp();
    logLines.insert(0, '$ts  📁 CSV dışa aktarıldı → ${file.path}');
    _trimLog();
    notifyListeners();

    return outputPath;
  }

  Future<String?> importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'CSV İçe Aktar',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final filePath = result.files.single.path;
    if (filePath == null) return null;

    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length < 2) {
        final ts = _timestamp();
        logLines.insert(0, '$ts  ❌ CSV dosyası boş veya geçersiz');
        _trimLog();
        notifyListeners();
        return null;
      }

      final header = lines[0].trim();
      if (!header.contains('Kondenser') && !header.contains('Zaman')) {
        final ts = _timestamp();
        logLines.insert(0, '$ts  ❌ CSV formatı tanınmıyor');
        _trimLog();
        notifyListeners();
        return null;
      }

      final condenserTemps = <double>[];
      final waterTemps = <double>[];
      final evapTemps = <double>[];
      final satTemps = <double>[];
      final evapPressures = <double>[];
      final timestamps = <DateTime>[];

      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].trim().split(',');
        if (parts.length < 6) continue;

        try {
          final time = DateTime.parse(parts[0].trim());
          final condT = double.parse(parts[1].trim());
          final waterT = double.parse(parts[2].trim());
          final evapT = double.parse(parts[3].trim());
          final satT = double.parse(parts[4].trim());
          final evapP = double.parse(parts[5].trim());

          timestamps.add(time);
          condenserTemps.add(condT);
          waterTemps.add(waterT);
          evapTemps.add(evapT);
          satTemps.add(satT);
          evapPressures.add(evapP);
        } catch (_) {
          continue;
        }
      }

      if (timestamps.isEmpty) {
        final ts = _timestamp();
        logLines.insert(0, '$ts  ❌ CSV\'den veri okunamadı');
        _trimLog();
        notifyListeners();
        return null;
      }

      final rawName = result.files.single.name.replaceAll('.csv', '').replaceAll('.CSV', '');
      final impId = 'imp_$rawName';

      final rec = ExperimentRecord(
        id: impId,
        date: timestamps.first,
        fluid: _selectedFluid.label,
      );

      for (int i = 0; i < timestamps.length; i++) {
        final reading = SensorReading(
          time: timestamps[i],
          condenserTemp: condenserTemps[i],
          waterTemp: waterTemps[i],
          evapTemp: evapTemps[i],
          evapPressure: evapPressures[i],
          saturationTemp: satTemps[i],
        );
        rec.addReading(reading);
      }

      _experiments = [..._experiments, rec];
      final newIndex = _experiments.length - 1;
      _importedIndices.add(newIndex);
      _selectedExpIndex = newIndex;
      _loadExperimentData(newIndex);

      final ts = _timestamp();
      logLines.insert(0, '$ts  📥 CSV içe aktarıldı: $impId (${timestamps.length} veri)');
      _trimLog();
      notifyListeners();

      return impId;
    } catch (e) {
      final ts = _timestamp();
      logLines.insert(0, '$ts  ❌ CSV okuma hatası: $e');
      _trimLog();
      notifyListeners();
      return null;
    }
  }

  Future<void> shutdownGracefully() async {
    if (_running && connected) {
      try {
        await _serialService.sendStop();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (_) {}
    }
    _running = false;
    _runningExpIndex = -1;
    _clockTicker?.cancel();

    if (connected) {
      try {
        await _serialService.disconnect();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _lineSub?.cancel();
    _sensorSub?.cancel();
    _faultSub?.cancel();
    _messageSub?.cancel();
    _errorSub?.cancel();
    _serialService.dispose();
    super.dispose();
  }
}