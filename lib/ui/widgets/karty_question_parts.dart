import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_button_style.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/karty_answer_feedback_effect.dart';
import 'package:lingualloop/ui/widgets/karty_control_glyphs.dart';
import 'package:lingualloop/ui/widgets/surface_gloss.dart';

/// Karty'nin kelime pekiştikçe zorlaşan sorularının cevap parçaları: görsel
/// düğmeleri, artikel, harf yuvaları ve karoları. Soru her zaman kartta,
/// cevaplar kartın altında.

const _green = (Color(0xFF93D334), Color(0xFF628C22));
const _red = (Color(0xFFF52A2A), Color(0xFF9A1414));

/// Seçenek ve harf karoları patikadaki yan durak karosu: lacivert yüz,
/// koyu taban, düğüm parlaması. Karonun kendisi nötr; renk cevapta.
const _tile = (Color(0xFF163258), Color(0xFF0B2143));

class KartyImageOption {
  const KartyImageOption({required this.kartyId, required this.image});

  final int kartyId;
  final ImageProvider image;
}

/// İkişerli dizilmiş görsel düğmeleri; harf karolarıyla aynı malzeme. Cevap
/// verilince doğru seçenek yeşile, yapılan yanlış kırmızıya döner (patikada
/// tamamlanan deste gibi), diğerleri geri çekilir.
class KartyImageOptions extends StatelessWidget {
  const KartyImageOptions({
    super.key,
    required this.scale,
    required this.width,
    required this.tileHeight,
    required this.options,
    required this.answerId,
    required this.onPick,
    this.pickedId,
    this.enabled = true,
  });

  final double scale;
  final double width;
  final double tileHeight;
  final List<KartyImageOption> options;
  final int answerId;
  final ValueChanged<int> onPick;

  /// Verilen cevap; `null` iken soru bekliyor.
  final int? pickedId;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final gap = 26 * scale;
    final tileWidth = (width - gap) / 2;
    final answered = pickedId != null;

    Widget tile(KartyImageOption option) {
      final isAnswer = option.kartyId == answerId;
      final isWrongPick = option.kartyId == pickedId && !isAnswer;
      return _OptionTile(
        key: ValueKey('karty-option-${option.kartyId}'),
        scale: scale,
        width: tileWidth,
        height: tileHeight,
        image: option.image,
        result: !answered
            ? null
            : isAnswer
                ? true
                : isWrongPick
                    ? false
                    : null,
        dim: answered && !isAnswer && !isWrongPick,
        enabled: enabled && !answered,
        onTap: () => onPick(option.kartyId),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i += 2) ...[
          if (i > 0) SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              tile(options[i]),
              if (i + 1 < options.length) ...[
                SizedBox(width: gap),
                tile(options[i + 1]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    super.key,
    required this.scale,
    required this.width,
    required this.height,
    required this.image,
    required this.result,
    required this.dim,
    required this.enabled,
    required this.onTap,
  });

  final double scale;
  final double width;
  final double height;
  final ImageProvider image;

  /// `true` doğru seçenek, `false` yapılan yanlış, `null` cevap yok.
  final bool? result;
  final bool dim;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // Yanlış cevabın hareketi; büyük karttaki "hayır" jestiyle aynı.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _shakeOffset = TweenSequence([
    TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 20),
    TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 40),
    TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 20),
  ]).animate(_shake);

  @override
  void didUpdateWidget(covariant _OptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != false && widget.result == false) {
      _shake.forward(from: 0);
    }
    if (!widget.enabled) _pressed = false;
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final depth = 14 * s;
    // Düğüm ve durak karolarının köşe oranı (`AppButtonStyle` ikon kontrolü).
    final radius = math.min(widget.width, widget.height) * 24.75 / 84.75;
    final result = widget.result;
    final (face, base) = switch (result) {
      true => _green,
      false => _red,
      null => _tile,
    };

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Görsel seçeneği',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.dim ? .42 : 1,
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _pressed = false)
              : null,
          onTapUp: widget.enabled
              ? (_) {
                  setState(() => _pressed = false);
                  widget.onTap();
                }
              : null,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeOffset.value, 0),
              child: child,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: result == true ? 1.03 : 1,
              child: SizedBox(
                width: widget.width,
                height: widget.height + depth,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    left: 0,
                    top: depth,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 60),
                      opacity: _pressed ? 0 : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: widget.width,
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 80),
                    curve: Curves.easeOut,
                    left: 0,
                    top: _pressed ? depth : 0,
                    width: widget.width,
                    height: widget.height,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: face,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: Stack(fit: StackFit.expand, children: [
                        // Büyük karoda parlama düğümünkinden iri durmasın.
                        CustomPaint(
                          painter: FaceGlossPainter(
                              radius: radius, unitWidth: 150 * s),
                        ),
                        Padding(
                          padding: EdgeInsets.all(34 * s),
                          child:
                              Image(image: widget.image, fit: BoxFit.contain),
                        ),
                      ]),
                    ),
                  ),
                  if (result != null)
                    Positioned(
                      top: -14 * s,
                      right: -10 * s,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: _ResultBadge(scale: s, correct: result),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.scale, required this.correct});

  final double scale;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    // Karo zaten renge döndüğü için rozet nötr lacivert bir çip (duraklat
    // düğmesinin malzemesi); renk işarette. Yeşil karoda yeşil rozet karoya
    // karışıyordu, koyu halka ise uygulamada olmayan bir kontur dili. Beyaz
    // işaret karonun içine konamaz: görsellerin beyaz tabanında kayboluyor.
    // İşaret renk körlüğünde de doğruyu söyler.
    return Container(
      width: 74 * scale,
      height: 74 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _tile.$1,
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [BoxShadow(color: _tile.$2, offset: Offset(0, 8 * scale))],
      ),
      child: KartyControlMark(
        glyph: correct ? KartyControlGlyph.check : KartyControlGlyph.cross,
        size: 44 * scale,
        color: correct ? _green.$1 : _red.$1,
      ),
    );
  }
}

/// der · die · das. Cevaptan sonra yalnız doğru artikel parlak kalır.
class KartyArticleChoices extends StatelessWidget {
  const KartyArticleChoices({
    super.key,
    required this.scale,
    required this.onPick,
    this.revealed,
    this.enabled = true,
  });

  static const articles = ['der', 'die', 'das'];

  final double scale;
  final ValueChanged<String> onPick;

  /// Doğru artikel; `null` iken soru bekliyor.
  final String? revealed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final gap = 26 * scale;
          final width = (constraints.maxWidth - 2 * gap) / 3;
          final answered = revealed != null;

          Widget button(String article) {
            final (face, base) = kartyArticleTones(article);
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: answered && revealed != article ? .42 : 1,
              child: IgnorePointer(
                ignoring: answered,
                child: DepthPressableButton(
                  width: width,
                  height: 119.25 * scale,
                  radius: 34 * scale,
                  shadowOffset: 12 * scale,
                  backgroundColor: face,
                  shadowColor: base,
                  fontSize: 44 * scale,
                  enabled: answered || enabled,
                  onPressed: () => onPick(article),
                  child: Text(
                    article,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44 * scale,
                      fontWeight: AppTypography.action,
                      fontFamily: AppTypography.family,
                    ),
                  ),
                ),
              ),
            );
          }

          return Row(children: [
            button(articles[0]),
            SizedBox(width: gap),
            button(articles[1]),
            SizedBox(width: gap),
            button(articles[2]),
          ]);
        },
      );
}

/// Harfleri karıştırır; tohum karta bağlı olduğu için aynı kartta sıra
/// değişmez. Karışım kelimenin kendisini vermez.
List<String> kartyShuffledLetters(String word, int seed) {
  final letters = word.split('');
  if (letters.toSet().length < 2) return letters;
  final random = math.Random(seed);
  do {
    letters.shuffle(random);
  } while (letters.join() == word);
  return letters;
}

enum KartyLettersState { answering, solved, failed }

/// Artikel ve kelimenin harf yuvaları. Uzun kelimede yuvalar küçülür, tek
/// satır kalır. Dolu yuvaya dokunmak harfi havuza geri yollar; sağındaki
/// harfler bir yuva sola kayar, metinden harf silmek gibi.
class KartyLetterSlots extends StatelessWidget {
  const KartyLetterSlots({
    super.key,
    required this.scale,
    required this.article,
    required this.word,
    required this.placed,
    required this.state,
    this.onRemove,
  });

  final double scale;
  final String article;
  final String word;

  /// Yuvalara sırayla konmuş harfler; yanlış harf de olabilir.
  final List<String> placed;
  final KartyLettersState state;

  /// Dolu yuvaya dokunulunca yuvanın sırası; `null` iken yuvalar kapalı.
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final letters = word.split('');
          final s = scale;
          final slot = math.min(
            86 * s,
            (constraints.maxWidth - 112 * s) / letters.length - 9 * s,
          );
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KartyArticleBadge(article: article, scale: s),
              SizedBox(width: 14 * s),
              for (var i = 0; i < letters.length; i++)
                _letterSlot(s, slot, i),
            ],
          );
        },
      );

  Widget _letterSlot(double s, double width, int index) {
    final answering = state == KartyLettersState.answering;
    final filled = index < placed.length;
    // Sonuçta doğru yazılış görünür; yanlış harf konmuş yuva kırmızıdır.
    final letter = answering ? (filled ? placed[index] : null) : word[index];
    final wrong = state == KartyLettersState.failed &&
        (!filled || placed[index] != word[index]);
    final (face, lip) = switch (state) {
      KartyLettersState.solved => _green,
      _ when wrong => _red,
      _ when filled => _tile,
      _ => (const Color(0xFF0C2244), const Color(0xFF0B2143)),
    };
    final slot = Container(
      width: width,
      height: width * 1.24,
      margin: EdgeInsets.symmetric(horizontal: 4.5 * s),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(18 * s),
        border: answering && index == placed.length
            ? Border.all(color: const Color(0xFF1CB1F5), width: 5 * s)
            : null,
        boxShadow: [BoxShadow(color: lip, offset: Offset(0, 7 * s))],
      ),
      child: letter == null
          ? null
          : Text(
              letter,
              style: TextStyle(
                color: Colors.white,
                fontSize: width * .66,
                fontWeight: AppTypography.word,
                fontFamily: AppTypography.family,
                height: 1,
              ),
            ),
    );
    final remove = onRemove;
    if (!answering || !filled || remove == null) return slot;
    return Semantics(
      button: true,
      label: '${placed[index]} harfini geri al',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('karty-slot-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: () => remove(index),
        child: slot,
      ),
    );
  }
}

/// Dizilecek harfler. Kullanılan harfin yerinde boş yuvası kalır.
class KartyLetterTiles extends StatelessWidget {
  const KartyLetterTiles({
    super.key,
    required this.scale,
    required this.width,
    required this.letters,
    required this.used,
    required this.onTap,
    this.enabled = true,
  });

  final double scale;
  final double width;
  final List<String> letters;
  final Set<int> used;
  final ValueChanged<int> onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final count = letters.length;
    final perRow = count <= 5 ? count : (count / 2).ceil();
    final gap = 16 * s;
    final tile = math.min(112 * s, (width - (perRow - 1) * gap) / perRow);
    final height = tile * 124 / 112;
    final depth = tile * 12 / 112;
    // Düğmenin çizdiği köşe; parlama ona otursun.
    final glossRadius = AppButtonStyle.resolve(
      width: tile,
      totalHeight: height + depth,
      legacyRadius: tile * .27,
      legacyDepth: depth,
    ).radius;

    Widget letterTile(int index) => used.contains(index)
        ? Container(
            width: tile,
            height: height,
            margin: EdgeInsets.only(top: depth),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2244),
              borderRadius: BorderRadius.circular(tile * .27),
            ),
          )
        : DepthPressableButton(
            key: ValueKey('karty-letter-$index'),
            width: tile,
            height: height,
            radius: tile * .27,
            shadowOffset: depth,
            backgroundColor: _tile.$1,
            shadowColor: _tile.$2,
            fontSize: tile * .52,
            enabled: enabled,
            onPressed: () => onTap(index),
            child: SizedBox.expand(
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: FaceGlossPainter(radius: glossRadius),
                  ),
                ),
                Text(
                  letters[index],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tile * .52,
                    fontWeight: AppTypography.word,
                    fontFamily: AppTypography.family,
                    height: 1,
                  ),
                ),
              ]),
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var start = 0; start < count; start += perRow) ...[
          if (start > 0) SizedBox(height: 14 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = start; i < math.min(start + perRow, count); i++) ...[
                if (i > start) SizedBox(width: gap),
                letterTile(i),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
