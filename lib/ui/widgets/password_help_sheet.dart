import 'package:flutter/material.dart';
import 'package:stelinda/Utils/AppNotifier.dart';
import 'package:stelinda/l10n/l10n.dart';
import 'package:stelinda/services/support_contact.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/widgets/Buttons/depth_pressable_button.dart';

/// Girişteki "Parolamı unuttum". Şifre sıfırlama e-postası henüz yok (giden
/// e-posta hizmeti kurulmadı); o zamana kadar destek adresine yazılır.
/// Bağlantı bir şey yapmadan duramaz: App Store incelemesi çalışmayan
/// düğmeyi eksik sayar.
Future<void> showPasswordHelpSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (sheetContext) => PasswordHelpSheetPanel(
        onWrite: () async {
          final l10n = sheetContext.l10n;
          final subject = l10n.passwordHelpMailSubject;
          final copied = l10n.passwordHelpCopied;
          Navigator.of(sheetContext).pop();
          if (!await SupportContact.compose(subject: subject)) {
            AppNotifier.showMessage(copied);
          }
        },
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );

class PasswordHelpSheetPanel extends StatelessWidget {
  const PasswordHelpSheetPanel({
    super.key,
    required this.onWrite,
    required this.onClose,
  });

  final VoidCallback onWrite;
  final VoidCallback onClose;

  static const _bg = Color(0xFF041227);
  static const _lip = Color(0xFF0B2143);
  static const _handle = Color(0xFF163258);
  static const _muted = Color(0xFF8FA0B5);
  static const _text = Color(0xFFE9EEF5);
  static const _accent = Color(0xFF1CB1F5);
  static const _accentDepth = Color(0xFF1B84B5);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final s = size.width / 750;
    final width = 670 * s;
    final radius = Radius.circular(56 * s);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: _lip,
          borderRadius: BorderRadius.vertical(top: radius),
        ),
        padding: EdgeInsets.only(top: 10 * s),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: radius),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(40 * s, 22 * s, 40 * s, 30 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96 * s,
                    height: 10 * s,
                    decoration: BoxDecoration(
                      color: _handle,
                      borderRadius: BorderRadius.circular(5 * s),
                    ),
                  ),
                  SizedBox(height: 40 * s),
                  Text(
                    l10n.passwordHelpTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 46 * s,
                      fontWeight: AppTypography.heading,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 16 * s),
                  Text(
                    l10n.passwordHelpBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontFamily: AppTypography.family,
                      fontSize: 25 * s,
                      fontWeight: AppTypography.body,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 18 * s),
                  // Adres ayrı satırda: e-posta uygulaması açılmasa da
                  // okunup yazılabilsin.
                  Text(
                    SupportContact.email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _text,
                      fontFamily: AppTypography.family,
                      fontSize: 29 * s,
                      fontWeight: AppTypography.label,
                    ),
                  ),
                  SizedBox(height: 40 * s),
                  DepthPressableButton(
                    text: l10n.passwordHelpWrite,
                    width: width,
                    height: 96 * s,
                    radius: 26 * s,
                    shadowOffset: 10 * s,
                    backgroundColor: _accent,
                    shadowColor: _accentDepth,
                    fontSize: 28 * s,
                    onPressed: onWrite,
                  ),
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClose,
                      child: SizedBox(
                        width: width,
                        height: 80 * s,
                        child: Center(
                          child: Text(
                            l10n.passwordHelpClose,
                            style: TextStyle(
                              color: _muted,
                              fontFamily: AppTypography.family,
                              fontSize: 28 * s,
                              fontWeight: AppTypography.action,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
