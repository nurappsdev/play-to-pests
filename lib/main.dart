import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'main_bindings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await MainBindings.init();
  runApp(const SmashStressApp());
}
