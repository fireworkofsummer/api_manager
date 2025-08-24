import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/api_provider.dart' as providers;
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() {
  // 初始化桌面平台的数据库
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ApiManagerApp());
}

class ApiManagerApp extends StatelessWidget {
  const ApiManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => providers.ApiProviderManager(),
      child: MaterialApp(
        title: 'API Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
