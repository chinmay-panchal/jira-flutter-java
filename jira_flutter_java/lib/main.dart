import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jira_flutter_java/Features/Project/ProjectViewModel/project_view_model.dart';
import 'package:jira_flutter_java/Features/User/UserViewModel/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:jira_flutter_java/Features/Auth/AuthView/login_screen.dart';
import 'package:jira_flutter_java/Features/Auth/AuthViewModel/auth_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData.dark(),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            secondary: Colors.grey,
          ),
        ),
        themeMode: ThemeMode.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
