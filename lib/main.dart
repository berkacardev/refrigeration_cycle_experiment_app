import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:refrigeration_cycle_experiment_app/feature/view/home/home_screen.dart';
import 'package:refrigeration_cycle_experiment_app/feature/viewmodel/experiment_provider.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';

late ExperimentProvider _globalProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1300, 800),
    center: true,
    title: 'Soğutma Çevrimi Deney İzleme',
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  _globalProvider = ExperimentProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: _globalProvider,
      child: const RefrigerationApp(),
    ),
  );
}

class RefrigerationApp extends StatefulWidget {
  const RefrigerationApp({super.key});

  @override
  State<RefrigerationApp> createState() => _RefrigerationAppState();
}

class _RefrigerationAppState extends State<RefrigerationApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    // Prevent default close so we can clean up first
    windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await _globalProvider.shutdownGracefully();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soğutma Çevrimi İzleme',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}