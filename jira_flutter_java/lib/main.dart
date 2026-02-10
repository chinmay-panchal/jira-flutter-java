import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jira_flutter_java/Core/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'Core/data/dataSource/app_data_source.dart';
import 'Core/data/repository/app_repository.dart';
import 'Core/network/global_app.dart';

import 'Features/Auth/AuthView/login_screen.dart';
import 'Features/Auth/AuthViewModel/auth_view_model.dart';
import 'Features/Project/ProjectView/project_list_screen.dart';
import 'Features/Project/ProjectViewModel/project_view_model.dart';
import 'Features/User/UserViewModel/user_view_model.dart';
import 'Features/Dashboard/DashboardViewModel/task_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with web-specific options
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDcpVqqzZBlcY4Q29MAowqTv1rRH1Auwbw",
        authDomain: "java-flutter-jira.firebaseapp.com",
        projectId: "java-flutter-jira",
        storageBucket: "java-flutter-jira.firebasestorage.app",
        messagingSenderId: "582096148432",
        appId: "1:582096148432:web:518a72bfc8212d734b4bd5",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

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
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            home: authVm.jwtToken == null
                ? const LoginScreen()
                : const ProjectListScreen(),
          );
        },
      ),
    );
  }
}