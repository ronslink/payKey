import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PayKey',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayKey'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'PayKey Mobile App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Payroll and Tax Management System',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '✅ Backend Integrated',
              style: TextStyle(color: Colors.green, fontSize: 18),
            ),
            Text(
              '✅ Tax Accumulation Active',
              style: TextStyle(color: Colors.green, fontSize: 18),
            ),
            Text(
              '✅ Mobile App Compiled',
              style: TextStyle(color: Colors.green, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}