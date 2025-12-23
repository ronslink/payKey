import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart';
import 'core/constants/api_constants.dart';

void main() {
  // Configure for local development
  ApiConstants.overrideBaseUrl('http://10.0.2.2:3000'); // Android Emulator
  // For iOS Simulator use: http://localhost:3000
  
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PayKeyApp()));
}
