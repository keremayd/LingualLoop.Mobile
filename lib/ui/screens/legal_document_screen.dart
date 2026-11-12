import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/app_icon_control_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/auth_back_button.dart';

enum LegalDocument {
  terms('Kullanım koşulları', 'assets/legal/kullanim_kosullari.md'),
  privacy('Gizlilik politikası', 'assets/legal/gizlilik_politikasi.md');

  const LegalDocument(this.title, this.asset);

  final String title;
  final String asset;
}

/// Kullanım koşulları ve gizlilik politikası. Metin asset'ten okunur:
/// `## ` bölüm başlığı, `- ` madde; boş satır paragrafları ayırır.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.document, this.text});

  final LegalDocument document;

  /// Önizleme ve test için: verilirse asset okunmaz.
  final String? text;

  static Future<void> open(BuildContext context, LegalDocument document) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(document: document),
      ));

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  static const _muted = Color(0xFF8FA0B5);
  static const _text = Color(0xFFE9EEF5);

  late final Future<String> _content = widget.text != null
      ? Future.value(widget.text)
      : rootBundle.loadString(widget.document.asset);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 750;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF041227),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 16 * scale),
            SizedBox(
              // Sütun genişliği gevşek veriyor; tam genişlik olmazsa geri
              // düğmesi başlığın üstüne biner.
              width: double.infinity,
              height: AppIconControlButton.outerHeightForScale(scale),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 20 * scale,
                    child: AuthBackButton(
                      scale: scale,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Text(
                    widget.document.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 42 * scale,
                      fontWeight: AppTypography.heading,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: _content,
                builder: (context, snapshot) {
                  final content = snapshot.data;
                  if (content == null) return const SizedBox.shrink();
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      40 * scale,
                      30 * scale,
                      40 * scale,
                      60 * scale + bottomInset,
                    ),
                    children: _blocks(content, scale),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _blocks(String content, double scale) {
    final body = TextStyle(
      color: _muted,
      fontFamily: AppTypography.family,
      fontSize: 26 * scale,
      fontWeight: AppTypography.body,
      height: 1.45,
    );
    final widgets = <Widget>[];
    for (final block in content.trim().split(RegExp(r'\n\s*\n'))) {
      final lines = block.trim().split('\n');
      if (lines.first.startsWith('## ')) {
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 18 * scale, bottom: 14 * scale),
          child: Text(
            lines.first.substring(3),
            style: TextStyle(
              color: _text,
              fontFamily: AppTypography.family,
              fontSize: 30 * scale,
              fontWeight: AppTypography.label,
            ),
          ),
        ));
        lines.removeAt(0);
        if (lines.isEmpty) continue;
      }
      if (lines.every((line) => line.startsWith('- '))) {
        for (final line in lines) {
          widgets.add(Padding(
            padding: EdgeInsets.only(bottom: 12 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 30 * scale, child: Text('•', style: body)),
                Expanded(child: Text(line.substring(2), style: body)),
              ],
            ),
          ));
        }
        widgets.add(SizedBox(height: 12 * scale));
      } else {
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 24 * scale),
          child: Text(lines.join('\n'), style: body),
        ));
      }
    }
    return widgets;
  }
}
