import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'main_bindings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  MainBindings.init();
  runApp(const TapToPestsApp());
}
