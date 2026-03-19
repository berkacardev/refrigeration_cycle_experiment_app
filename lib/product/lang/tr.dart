class AppStrings {
  AppStrings._();

  static const appTitle = 'Soğutma Çevrimi  —  Deneysel İzleme Sistemi';
  static const appTitleShort = 'Soğutma Çevrimi İzleme';
  static const appSubtitle = 'Soğutma Çevrimi';
  static const appVersion = 'v1.0';
  static const appSubtitleFull = 'Deneysel İzleme v1.0';

  static const menu = 'MENÜ';
  static const openMenu = 'Menüyü Aç';

  static const fluidType = 'Akışkan Tipi';
  static const experiment = 'Deney';
  static const experimentList = 'Deneyler Listesi';
  static const liveDataStream = 'Anlık Veri Akışı';
  static const arduinoConnection = 'Arduino Bağlantısı';
  static const experimentDuration = 'Deney Süresi';
  static const waitingExperiment = 'Deney bekleniyor…';

  static const startExperiment = '▶  DENEY BAŞLAT';
  static const stopExperiment = '■  DURDUR';
  static const arduinoRequired = 'Arduino bağlantısı gerekli';

  static const connect = '⚡  BAĞLAN';
  static const connecting = '⏳  BAĞLANIYOR...';
  static const disconnect = '🔌  BAĞLANTIYI KES';
  static const exportCsv = '⬇  VERİ AKTAR (CSV)';
  static const importCsv = '⬆  CSV İÇE AKTAR';

  static const portNotFound = 'Port bulunamadı';
  static const selectPort = 'Port Seçin';
  static const scanPorts = 'Portları Tara';

  static const connectionFailed = 'Bağlantı Başarısız';
  static const portBusy = 'Port Meşgul';
  static const deviceNotFound = 'Cihaz Bulunamadı';
  static const accessDenied = 'Erişim Engellendi';
  static const unknownDevice = 'Bilinmeyen Cihaz';
  static const deviceVerified = 'Cihaz Doğrulandı';
  static const deviceConnected = 'Deney cihazına başarıyla bağlanıldı!';
  static const noDetail = 'Detay yok';

  static const close = 'Kapat';
  static const ok = 'Tamam';
  static const cancel = 'Vazgeç';
  static const delete = 'Sil';
  static const continueAnyway = 'Yine de Devam Et';

  static const deleteExperiment = 'Deneyi Sil';
  static const deleteConfirm = 'Bu deneyi silmek istediğinize emin misiniz?';
  static const deleteIrreversible = 'Bu işlem geri alınamaz.';

  static const activeFaults = 'Aktif Arızalar';
  static const clearFaults = 'Arızaları Temizle';
  static const criticalFault = 'Kritik Arıza!';

  static const arduinoConnected = 'Arduino Bağlı';
  static const notConnected = 'Bağlı Değil';
  static const disconnectBtn = 'Bağlantıyı Kes';

  static const condenserTemp = 'Kondenser Sıcaklığı';
  static const condenserWaterTemp = 'Kondenser Soğutma Suyu Sıcaklığı';
  static const evapAndSatTemp = 'Evaporatör & Doyma Sıcaklığı';
  static const evapPressure = 'Evaporatör Basıncı';
  static const evaporator = 'Evaporatör';
  static const saturationTemp = 'Doyma Sıcaklığı';
  static const condenser = 'Kondenser';

  static const condenserZone = '▲  KONDENSER BÖLGESİ';
  static const evaporatorZone = '▼  EVAPORATÖR BÖLGESİ';

  static const allCondenserMinimized = 'Tüm kondenser grafikleri küçültüldü';
  static const allEvapMinimized = 'Tüm evaporatör grafikleri küçültüldü';

  static const minimize = 'Küçült';
  static const fullscreen = 'Tam Ekran';
  static const normalSize = 'Normal Boyut';
  static const unknownChart = 'Bilinmeyen grafik';
  static const hideDiagram = 'Şemayı Gizle';
  static const showDiagram = 'Şemayı Göster';
  static const hide = 'Gizle';

  static const condShortLabel = 'Kond. Sıc.';
  static const waterShortLabel = 'Su Sıc.';
  static const evapTempShortLabel = 'Evap. Sıc.';
  static const evapPressureShortLabel = 'Evap. Bas.';

  static const probeCondTemp = 'Kond. Sıcaklık';
  static const probeWaterTemp = 'Kond. Su Sıcaklık';
  static const probeEvapTemp = 'Evap. Sıcaklık';
  static const probeEvapPressure = 'Evap. Basınç';

  static const highPressure = 'YÜKSEK BASINÇ';
  static const lowPressure = 'DÜŞÜK BASINÇ';
  static const dischargeLine = 'Basma Hattı';
  static const superheatedVapor = '(Kızgın Buhar)';
  static const suctionLine = 'Emiş Hattı';
  static const saturatedVapor = '(Doymuş Buhar)';
  static const liquidLine = 'Sıvı Hattı';
  static const condensedLiquid = '(Yoğuşmuş Sıvı)';
  static const afterExpansion = 'Genleşme Sonrası';
  static const wetVapor = '(Islak Buhar)';
  static const condenserLabel = 'KONDENSER';
  static const heatRejection = 'Isı Atımı  (Q_H)';
  static const evaporatorLabel = 'EVAPORATÖR';
  static const heatAbsorption = 'Isı Çekimi  (Q_L)';
  static const compressorLabel = 'KOMPRESÖR';
  static const expansionValve = 'Genleşme';
  static const valve = 'Vanası';

  static const importedExperiment = 'İçe aktarılmış deney';
  static const completedExperiment = 'Tamamlanmış deney';
  static const runningExperiment = 'Devam ediyor';
  static String restoreTooltip(String name) => '$name\nTıklayarak geri yükle';

  static const exportCancelledOrEmpty = 'Dışa aktarma iptal edildi veya veri yok.';
  static const importCancelledOrInvalid = 'İçe aktarma iptal edildi veya dosya geçersiz.';
  static String csvSaved(String path) => 'CSV kaydedildi: $path';
  static String imported(String id) => 'İçe aktarıldı: $id';
  static String faultCount(int count) => 'Arıza: $count';
  static String faultBadge(int count) => '$count Arıza';
  static String clearCount(int count) => 'Temizle ($count)';

  static const developerName = 'Berk Acar';
  static const developedBy = 'tarafından geliştirilmiştir';
  static const linkedinUrl = 'https://www.linkedin.com/in/berkacar/';

  static String portBusyMessage(String port) =>
      '$port başka bir uygulama tarafından kullanılıyor.\n\n'
          'Arduino IDE Serial Monitor açıksa kapatın ve tekrar deneyin.';
  static String deviceNotFoundMessage(String port) =>
      '$port portunda cihaz bulunamadı.\n\nUSB kablosunu kontrol edin ve portları yeniden tarayın.';
  static String accessDeniedMessage(String port) =>
      '$port portuna erişim izni yok.\n\nUygulamayı yönetici olarak çalıştırmayı deneyin.';
  static String connectionFailedMessage(String port) =>
      '$port portuna bağlanılamadı.\n\nCihazın bağlı olduğundan ve doğru portu seçtiğinizden emin olun.';
  static String unknownDeviceMessage(String deviceId) =>
      deviceId.isEmpty
          ? 'Cihazdan yanıt alınamadı.\nDoğru porta bağlı olduğunuzdan emin olun.'
          : 'Beklenen: RCE_DEVICE_V1\nAlınan: $deviceId';
  static String deviceLabel(String id) => 'Cihaz: $id';

  static const superheatLabel = 'Kızgınlık';
  static const superheatNull = 'Kızgınlık: —';
  static String superheatValue(double v) => 'Kızgınlık: ${v.toStringAsFixed(1)} °C';

  static const filterSectionTitle = 'SİNYAL FİLTRESİ';
  static const filterSoft = 'yumuşak';
  static const filterFast = 'hızlı';
  static const filterNarrow = 'dar';
  static const filterWide = 'geniş';
  static const filterSensors = 'Sensörler';
  static const filterSelectAll = 'Tümünü Seç';
  static const filterSelectNone = 'Hiçbiri';
  static String filterAlphaLabel(double v) => 'Alpha: ${v.toStringAsFixed(2)}';
  static String filterWindowLabel(int v) => 'Pencere: $v';

  static const filterSensorCondenser = 'Kondenser Sıc.';
  static const filterSensorWater = 'Su Sıc.';
  static const filterSensorEvapTemp = 'Evap. Sıc.';
  static const filterSensorEvapPressure = 'Evap. Basınç';

  static const filterTypeNone = 'Filtre Yok';
  static const filterTypeLowPass = 'Alçak Geçiren';
  static const filterTypeMovingAvg = 'Hareketli Ortalama';
  static const filterTypeEma = 'Üssel Hareketli Ort.';
  static const filterTypeMedian = 'Medyan';

  static const filterShortNone = 'Yok';
  static const filterShortLpf = 'LPF';
  static const filterShortMa = 'MA';
  static const filterShortEma = 'EMA';
  static const filterShortMed = 'MED';
}