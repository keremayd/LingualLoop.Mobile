import 'package:lingualloop/ui/app_typography.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/services.dart' show rootBundle;
import 'package:lingualloop/providers/BadgeProvider.dart';
import 'package:lingualloop/providers/ArticlePracticeProvider.dart';
import 'package:lingualloop/providers/KartyProvider.dart';
import 'package:lingualloop/providers/ProfileLearningStatsProvider.dart';
import 'package:lingualloop/providers/QuestsProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';
import 'package:lingualloop/providers/UserProvider.dart';
import 'package:lingualloop/providers/VideoProvider.dart';
import 'package:lingualloop/services/BadgeService.dart';
import 'package:lingualloop/services/ArticlePracticeService.dart';
import 'package:lingualloop/services/FileService.dart';
import 'package:lingualloop/services/KartyService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/services/QuestService.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/services/AuthenticationService.dart';
import 'package:lingualloop/services/VideoService.dart';
import 'package:lingualloop/ui/screens/SignUpScreen.dart';
import 'package:lingualloop/ui/screens/article_practice_screen.dart';
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

/// Ekranların üzerlerine push edilen route kapanınca (örn. oyun ekranından
/// dönüş) veri tazelemesi yapabilmesi için global route gözlemcisi.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

String get apiBaseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5213/ll-api/';
  }

  return 'http://localhost:5214/ll-api/';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['Rubik'],
      await rootBundle.loadString('assets/fonts/Rubik-LICENSE.txt'),
    );
    yield LicenseEntryWithLineBreaks(
      ['Baloo 2'],
      await rootBundle.loadString('assets/fonts/Baloo2-LICENSE.txt'),
    );
  });
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (context) {
            final dio = Dio(
              BaseOptions(
                baseUrl: apiBaseUrl,
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
        // Telaffuz oynatıcısı uygulama ömrü boyunca tek: her ekranda yenisi
        // kurulsaydı sesler çakışır ve bellekte oynatıcı birikirdi.
        Provider<PronunciationService>(
          create: (_) => PronunciationService(),
          dispose: (_, service) => service.dispose(),
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
        Provider<QuestService>(
          create: (context) {
            final dio = context.read<Dio>();
            return QuestService(dio);
          },
        ),
        Provider<LocalFileService>(
          create: (context) {
            return LocalFileService();
          },
        ),
        Provider<ArticlePracticeService>(
          create: (context) => ArticlePracticeService(
            context.read<Dio>(),
            context.read<LocalFileService>(),
          ),
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
        ChangeNotifierProvider<ArticlePracticeProvider>(
          create: (context) =>
              ArticlePracticeProvider(context.read<ArticlePracticeService>()),
        ),
        ChangeNotifierProvider<ProfileLearningStatsProvider>(
          create: (_) => ProfileLearningStatsProvider(),
        ),
        ChangeNotifierProvider<BadgeProvider>(
          create: (_) => BadgeProvider(),
        ),
        ChangeNotifierProvider<VideoProvider>(
          create: (_) => VideoProvider(),
        ),
        ChangeNotifierProvider<QuestsProvider>(
          create: (context) => QuestsProvider(context.read<QuestService>()),
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
      navigatorObservers: [routeObserver],
      title: 'Lingual Loop',
      initialRoute: '/welcome',
      routes: {
        '/signin': (context) => LoginScreen(),
        '/home': (context) => NavbarWidget(),
        '/videoquiz': (context) => VideoQuizScreen(),
        '/kartyquiz': (context) => KartyQuizScreen(),
        '/kartyreview': (context) => KartyQuizScreen(reviewMode: true),
        '/articlepractice': (context) => const ArticlePracticeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/signup': (context) => SignUpScreen(),
      },
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFFF9FBFF),
        fontFamily: AppTypography.family,
        textTheme: AppTypography.textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF9FBFF), // AppBar arka plan rengi
        ),
      ),
    );
  }
}
