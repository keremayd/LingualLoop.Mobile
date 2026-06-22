import 'package:flutter/material.dart';
import 'package:lingualloop/ui/widgets/CurvedDesign.dart';
import 'package:lingualloop/ui/widgets/CustomIconButton.dart';
import 'package:lingualloop/ui/widgets/TimeBar.dart';
import 'package:provider/provider.dart';

import '../widgets/Buttons/AnswerButton.dart';
import '../widgets/CustomAppBar.dart';
import 'package:lingualloop/providers/VideoProvider.dart';
import 'package:lingualloop/providers/ScoreWithLivesProvider.dart';

class VideoQuizScreen extends StatefulWidget {
  @override
  _VideoQuizScreenState createState() => _VideoQuizScreenState();
}

class _VideoQuizScreenState extends State<VideoQuizScreen> {
  @override
  void initState() {
    super.initState();

    // provider init'ini frame sonrasında çağırıyoruz (context güvenli)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      videoProvider.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoProvider>(context);

    if (provider.isLoading) {
      return Container(
        color: const Color(0xFF5F5CEF),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF5F5CEF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(93),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 50),
              child: CustomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 29),
                    ),

                    // TimeBar
                    if (provider.duration.value != 0)
                      TimeBar(
                        duration: provider.duration,
                        isFinished: provider.isFinished,
                        onReset: provider.timeBarResetNotifier,
                      ),

                    // Score & streak (ScoreWithLivesProvider'dan gelmeye devam ediyoruz)
                    Row(
                      children: [
                        Image.asset('assets/icons/cup.png', height: 22, width: 22),
                        const SizedBox(width: 4),
                        Consumer<ScoreWithLivesProvider>(
                          builder: (context, scoreProvider, child) {
                            return Text(
                              "${scoreProvider.scoreWithLives?.score}",
                              style: const TextStyle(
                                fontSize: 17,
                                color: Color(0xFFF99300),
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        Image.asset('assets/icons/fire.png', height: 22, width: 22),
                        const SizedBox(width: 4),
                        Text(
                          "${provider.streak}",
                          style: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFFFF6536),
                              fontWeight: FontWeight.w600),
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
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF7875FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: provider.isFinished,
                      builder: (context, value, child) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: provider.duration.value == 0 || value
                                ? Align(
                                  alignment: Alignment.centerRight,
                                  child: CustomIconButton(
                                    img: 'next',
                                    backgroundColor: Colors.white,
                                    iconColor: const Color(0xFF5F5CEF),
                                    ontap: () => provider.nextVideo(context),
                                  ),
                                )
                                  : null,
                          ),
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomIconButton(img: 'info', backgroundColor: Colors.white, iconColor: Color(0xFF7875FC)),
                              const SizedBox(width: 10),
                              CustomIconButton(img: 'subtitleopen', clickedImg: 'subtitleclose', backgroundColor: Colors.white, iconColor: Color(0xFF7875FC)),
                            ],
                          ),
                          CustomIconButton(img: 'bookmark', backgroundColor: Colors.white, iconColor: Color(0xFF7875FC)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          CustomDesignWidget(),

          Expanded(
            child: Center(
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFF7875FC)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Text(
                            "Süre tükenmeden yanıtını seç!",
                            style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Spacer(),

                      // Butonlar ve "veya"
                      ValueListenableBuilder<bool>(
                        valueListenable: provider.isFinished,
                        builder: (context, value, child) {
                          // isFinished true olduğunda provider buton renklerini güncellesin
                          if (value) {
                            provider.updateButtonBorder();
                          }

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnswerButton(
                                    text: provider.aButton,
                                    onPressed: provider.isFinished.value ? null : () => provider.answerQuestion(context, provider.aButton),
                                    buttonDisabledColor: provider.buttonsColor[provider.aButton] ?? Colors.transparent,
                                    textColor: provider.textColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "veya",
                                style: TextStyle(fontSize: 20, color: Color(0xFF5F5CEF), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnswerButton(
                                    text: provider.bButton,
                                    onPressed: provider.isFinished.value ? null : () => provider.answerQuestion(context, provider.bButton),
                                    buttonDisabledColor: provider.buttonsColor[provider.bButton] ?? Colors.transparent,
                                    textColor: provider.textColor,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
