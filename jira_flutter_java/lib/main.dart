import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'Core/data/dataSource/app_data_source.dart';
import 'Core/data/repository/app_repository.dart';
import 'Core/network/global_app.dart';
import 'Core/theme/theme_provider.dart';

import 'Features/Auth/AuthView/login_screen.dart';
import 'Features/Auth/AuthViewModel/auth_view_model.dart';
import 'Features/Project/ProjectView/project_list_screen.dart';
import 'Features/Project/ProjectViewModel/project_view_model.dart';
import 'Features/User/UserViewModel/user_view_model.dart';
import 'Features/Dashboard/DashboardViewModel/task_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final dataSource = AppDataSource();
  final repository = AppRepository(dataSource);

  final authVm = AuthViewModel(repository);
  await authVm.loadToken();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProvider(
          create: (context) => ProjectViewModel(context.read<AppRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => UserViewModel(context.read<AppRepository>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: GlobalApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Jira',
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            home: authVm.jwtToken == null
                ? const LoginScreen()
                : const ProjectListScreen(),
          );
        },
      ),
    );
  }
}
/* ---------------- LIGHT THEME ---------------- */

final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: Colors.black,
    secondary: Colors.black,
    error: Colors.red,
    surface: Colors.white,
    onSurface: Colors.black,
    outline: Colors.black,
  ),

  scaffoldBackgroundColor: Colors.white,

  inputDecorationTheme: InputDecorationTheme(
    floatingLabelStyle: const TextStyle(color: Colors.black),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.black),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.black),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.black),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),

  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.black,
    selectionHandleColor: Colors.black,
  ),
);

/* ---------------- DARK THEME ---------------- */

final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: Colors.white,
    secondary: Colors.white,
    error: Colors.red,
    surface: Colors.black,
    onSurface: Colors.white,
    outline: Colors.white,
  ),

  scaffoldBackgroundColor: Colors.black,

  appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),

  inputDecorationTheme: InputDecorationTheme(
    floatingLabelStyle: const TextStyle(color: Colors.white),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.white),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.white),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.white),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),

  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Colors.white,
    selectionHandleColor: Colors.white,
  ),
);
