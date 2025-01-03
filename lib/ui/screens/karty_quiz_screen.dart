import 'package:flutter/material.dart';
import 'package:lingualloop/services/UserService.dart';
import 'package:lingualloop/ui/widgets/LessonCard.dart';
import 'package:lingualloop/ui/widgets/MainLessonCard.dart';
import 'package:lingualloop/ui/widgets/SwipableCard.dart';
import 'package:provider/provider.dart';

import '../../models/User.dart';
import '../../models/responses/ScoreWithLivesResponse.dart';
import '../../providers/ScoreWithLivesProvider.dart';
import '../../providers/UserProvider.dart';
import '../widgets/CustomAppBar.dart';
import '../widgets/ProgressBar.dart';

class KartyQuizScreen extends StatefulWidget {
  @override
  _KartyQuizScreenState createState() => _KartyQuizScreenState();
}

class _KartyQuizScreenState extends State<KartyQuizScreen> {
  int duration = 3;
  final ValueNotifier<bool> isCountdownFinished = ValueNotifier(false);
  User? user;
  ScoreWithLivesResponse? scoreWithLives;
  bool isLoading = true;
  int streak = 0;
  final ValueNotifier<int> progressBarResetNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> durationNotifier = ValueNotifier<int>(3);





  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double screenHeight = constraints.maxHeight; // 706.09
        double screenWidth = constraints.maxWidth; // 392.72

        return Scaffold(
          backgroundColor: Color(0xFF5F5CEF),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(93),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(
                    top: 50,
                  ),
                  child: CustomAppBar(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                ProgressBar(
                                  duration: duration,
                                  isCountdownFinished: isCountdownFinished,
                                  onReset: progressBarResetNotifier, // Reset tetikleyici

                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/icons/cup.png',
                                  height: 22,
                                  width: 22,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "${scoreWithLives?.score}",
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Color(0xFFF99300),
                                      fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 20),
                                Image.asset(
                                  'assets/icons/fire.png',
                                  height: 22,
                                  width: 22,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "${streak}",
                                  style: TextStyle(
                                      fontSize: 17,
                                      color: Color(0xFFFF6536),
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          body: Column(
            children: [
              SwipableCard(),
            ],
          ),
        );
      },
    );
  }
}