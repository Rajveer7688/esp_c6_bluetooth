import 'package:blue/repositories/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app.dart';

/// -- Entry point of Flutter App
Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// -- GetX Local Storage
  await GetStorage.init();

  /// -- Overcome from transparent spaces at the bottom in iOS full Mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  /// -- Manage all actions regarding authentications
  Get.put(AuthenticationRepository());

  /// -- Await Splash until other items Load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// -- Main App Starts here...
  runApp(const App());
}