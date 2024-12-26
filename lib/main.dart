import 'package:flutter/material.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/services/auth_service.dart';
import 'package:lingualloop/services/question_service.dart';
import 'package:lingualloop/ui/screens/video_quiz_screen.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'package:dio/dio.dart';
import 'TokenInterceptor.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (context) {
            final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:5213/ll-api/'));
            final authService = AuthService(dio, );
            dio.interceptors.add(TokenInterceptor(authService));
            return authService;
          },
        ),
        Provider<Dio>(
          create: (context) => context.read<AuthService>().dio,
        ),
        Provider<QuestionService>(
          create: (context) {
            final dio = context.read<Dio>();
            return QuestionService(dio);
          },
        ),
        Provider<UserService>(
          create: (context) {
            final dio = context.read<Dio>();
            return UserService(dio);
          },
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider<ScoreWithLivesProvider>(
          create: (_) => ScoreWithLivesProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Lingual Loop',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => NavbarWidget(),
        '/videoquiz': (context) => VideoQuizScreen(),
      },



      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF9FBFF),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF9FBFF), // AppBar arka plan rengi
        ),
      ),

    );
  }
}