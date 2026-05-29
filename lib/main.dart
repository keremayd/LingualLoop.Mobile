import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/providers/VideoProvider.dart';
import 'package:lingualloop/services/BadgeService.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/services/VideoService.dart';
import 'package:lingualloop/ui/screens/SignUpScreen.dart';
import 'package:lingualloop/ui/screens/karty_quiz_screen.dart';
import 'package:lingualloop/ui/screens/profile_screen.dart';
import 'package:lingualloop/ui/screens/video_quiz_screen.dart';
import 'package:lingualloop/ui/screens/welcome_screen.dart';
import 'package:lingualloop/ui/widgets/NavbarWidget.dart';
import 'ui/screens/login_screen.dart';
import 'package:dio/dio.dart';
import 'TokenInterceptor.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Alt sistem çubuğunu şeffaf yap ama içeriği alta taşırma
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF041227),
  ));

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (context) {
            final dio = Dio(
              BaseOptions(
                baseUrl: 'http://10.0.2.2:5213/ll-api/',
              ),
            );
            final authService = AuthService(dio);
            dio.interceptors.add(TokenInterceptor(authService));
            return authService;
          },
        ),
        Provider<Dio>(
          create: (context) => context.read<AuthService>().dio,
        ),
        Provider<VideoService>(
          create: (context) {
            final dio = context.read<Dio>();
            return VideoService(dio);
          },
        ),
        Provider<UserService>(
          create: (context) {
            final dio = context.read<Dio>();
            return UserService(dio);
          },
        ),
        Provider<KartyService>(
          create: (context) {
            final dio = context.read<Dio>();
            return KartyService(dio);
          },
        ),
        Provider<BadgeService>(
          create: (context) {
            final dio = context.read<Dio>();
            return BadgeService(dio);
          },
        ),
        Provider<LocalFileService>(
          create: (context) {
            return LocalFileService();
          },
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider<ScoreWithLivesProvider>(
          create: (_) => ScoreWithLivesProvider(),
        ),
        ChangeNotifierProvider<KartyProvider>(
          create: (_) => KartyProvider(),
        ),
        ChangeNotifierProvider<BadgeProvider>(
          create: (_) => BadgeProvider(),
        ),
        ChangeNotifierProvider<VideoProvider>(
          create: (_) => VideoProvider(),
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
      initialRoute: '/welcome',
      routes: {
        '/signin': (context) => LoginScreen(),
        '/home': (context) => NavbarWidget(),
        '/videoquiz': (context) => VideoQuizScreen(),
        '/kartyquiz': (context) => KartyQuizScreen(),
        '/profile': (context) => ProfileScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/signup': (context) => SignUpScreen(),
      },

      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF041227),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF041227), // AppBar arka plan rengi
        ),
      ),

    );
  }
}