import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:lingualloop/models/responses/word_collection_response.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/karty_sound_button.dart';

class WordCollectionTile extends StatelessWidget {
  const WordCollectionTile({
    super.key,
    required this.item,
    required this.category,
    required this.scale,
    required this.audioService,
    required this.activeSpeech,
    required this.onPlay,
  });

  final WordCollectionItem item;
  final String category;
  final double scale;
  final PronunciationService audioService;
  final ValueListenable<({int kartyId, int requestId})?> activeSpeech;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final (face, depth) = switch (item.article.toLowerCase()) {
      'der' => (const Color(0xFF1CB1F5), const Color(0xFF1B84B5)),
      'die' => (const Color(0xFFF52A2A), const Color(0xFFAA1C1C)),
      _ => (const Color(0xFFFF9300), const Color(0xFFC97800)),
    };
    final (status, statusColor) = category == 'article'
        ? ('Artikel çalış', const Color(0xFFFFC93A))
        : category == 'new'
            ? ('Yeni tanıştın', const Color(0xFF93D334))
            : item.isDue
                ? ('Tekrar zamanı', const Color(0xFF1CB1F5))
                : item.isNew
                    ? ('Yeni tanıştın', const Color(0xFF93D334))
                    : item.needsArticlePractice
                        ? ('Artikel çalış', const Color(0xFFFFC93A))
                        : ('Çalışıldı', const Color(0xFF8FA0B5));
    return Container(
      height: 224 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFF041227),
        borderRadius: BorderRadius.circular(30 * scale),
        border: Border.all(color: const Color(0xFF0B2143), width: 1.1 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2143),
            offset: Offset(0, 7 * scale),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(17 * scale),
        child: Row(children: [
          Container(
            width: 180 * scale,
            height: 180 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23 * scale),
              border: Border.all(
                color: const Color(0xFF163258),
                width: 5 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B2143),
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18 * scale),
              child: ColoredBox(
                color: const Color(0xFF0C2244),
                child: item.kartyUrl.isEmpty
                    ? const SizedBox.expand()
                    : Image.network(item.kartyUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.expand()),
              ),
            ),
          ),
          SizedBox(width: 20 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        9 * scale, 4 * scale, 9 * scale, 5 * scale),
                    decoration: BoxDecoration(
                      color: face,
                      borderRadius: BorderRadius.circular(11 * scale),
                      boxShadow: [
                        BoxShadow(color: depth, offset: Offset(0, 4 * scale))
                      ],
                    ),
                    child: Text(item.article,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTypography.family,
                          fontWeight: AppTypography.label,
                          fontSize: 23 * scale,
                          height: 1,
                        )),
                  ),
                  SizedBox(width: 9 * scale),
                  Expanded(
                    child: Text(item.nounText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTypography.family,
                          fontWeight: AppTypography.word,
                          fontSize: 35 * scale,
                          height: 1.05,
                        )),
                  ),
                ]),
                SizedBox(height: 18 * scale),
                Text(status,
                    style: TextStyle(
                      color: statusColor,
                      fontFamily: AppTypography.family,
                      fontWeight: AppTypography.label,
                      fontSize: 20 * scale,
                      height: 1.1,
                    )),
              ],
            ),
          ),
          SizedBox(width: 6 * scale),
          if (item.audioUrl != null && item.audioUrl!.isNotEmpty)
            ValueListenableBuilder<({int kartyId, int requestId})?>(
              valueListenable: activeSpeech,
              builder: (context, active, _) => ValueListenableBuilder<bool>(
                valueListenable: audioService.isSpeaking,
                builder: (context, speaking, _) => ValueListenableBuilder<bool>(
                  valueListenable: audioService.isMuted,
                  builder: (context, muted, _) => KartySoundButton(
                    scale: scale,
                    muted: muted,
                    speaking: active?.kartyId == item.kartyId && speaking,
                    animationTrigger: active?.requestId ?? 0,
                    onToggle: onPlay,
                    semanticsLabel: '${item.nounText} telaffuzunu dinle',
                    semanticsHint: muted
                        ? 'Dinlemek için önce sesi aç'
                        : 'Telaffuzu yeniden çal',
                    tooltip: muted ? 'Sesi açıp dinle' : 'Telaffuzu dinle',
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
