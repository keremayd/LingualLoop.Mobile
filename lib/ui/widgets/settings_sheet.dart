import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingualloop/services/GameFeedbackService.dart';
import 'package:lingualloop/services/PronunciationService.dart';
import 'package:lingualloop/ui/app_typography.dart';
import 'package:lingualloop/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:lingualloop/ui/widgets/Buttons/secondary_action_button.dart';
import 'package:lingualloop/ui/widgets/app_shape_style.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

enum SettingsAction { terms, privacy, signOut, deleteAccount }

/// Profildeki çarkın penceresi. Seri penceresinin kalıbıyla alttan açılır.
/// Ses ve titreşim pencerede değişir; diğer seçimler pencereyi kapatır ve
/// eylemi çağıran yürütür (çıkış ve silme sayfayı değiştiriyor).
Future<SettingsAction?> showSettingsSheet(BuildContext context) async {
  final pronunciation = context.read<PronunciationService>();
  final feedback = context.read<GameFeedbackService>();
  final version = await _appVersion();
  if (!context.mounted) return null;
  return showModalBottomSheet<SettingsAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (sheetContext) => SettingsSheetPanel(
      soundMuted: pronunciation.isMuted,
      onSoundMuted: pronunciation.setMuted,
      vibrationOn: feedback.vibrationEnabled,
      onVibration: feedback.setVibrationEnabled,
      version: version,
      onSelected: (action) => Navigator.of(sheetContext).pop(action),
    ),
  );
}

Future<String?> _appVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return 'Sürüm ${info.version} (${info.buildNumber})';
  } catch (error) {
    if (kDebugMode) debugPrint('Sürüm okunamadı: $error');
    return null;
  }
}

class SettingsSheetPanel extends StatelessWidget {
  const SettingsSheetPanel({
    super.key,
    required this.soundMuted,
    required this.onSoundMuted,
    required this.vibrationOn,
    required this.onVibration,
    required this.onSelected,
    this.version,
  });

  /// Oyundaki hoparlör düğmesiyle aynı ayar (`PronunciationService`).
  final ValueListenable<bool> soundMuted;
  final ValueChanged<bool> onSoundMuted;
  final ValueListenable<bool> vibrationOn;
  final ValueChanged<bool> onVibration;
  final ValueChanged<SettingsAction> onSelected;
  final String? version;

  static const _bg = Color(0xFF041227);
  static const _lip = Color(0xFF0B2143);
  static const _handle = Color(0xFF163258);
  static const _muted = Color(0xFF8FA0B5);
  static const _danger = Color(0xFFF52A2A);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = size.width / 750;
    final radius = Radius.circular(56 * s);
    final width = 670 * s;

    Widget row(String label, SettingsAction action, {bool opens = false}) =>
        _SettingsRow(
          label: label,
          scale: s,
          width: width,
          onTap: () => onSelected(action),
          trailing: opens
              ? Icon(Icons.chevron_right, color: _muted, size: 44 * s)
              : null,
        );

    // [on] anahtarın açık olduğu hâli verir; ses ayarı "sessiz mi" diye
    // tutulduğu için orada ters çevrilir.
    Widget toggle(String label, ValueListenable<bool> source,
            {required bool Function(bool) on,
            required ValueChanged<bool> onChanged}) =>
        ValueListenableBuilder<bool>(
          valueListenable: source,
          builder: (context, raw, _) {
            final value = on(raw);
            return Semantics(
              toggled: value,
              child: _SettingsRow(
                label: label,
                scale: s,
                width: width,
                onTap: () => onChanged(!value),
                trailing: _ToggleMark(on: value, scale: s),
              ),
            );
          },
        );

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        // Küçük ekranda ya da büyük yazıda pencere ekranı aşmasın, kaysın.
        constraints: BoxConstraints(maxHeight: size.height * 0.92),
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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(40 * s, 22 * s, 40 * s, 40 * s),
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
                  SizedBox(height: 34 * s),
                  Text(
                    'Ayarlar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 46 * s,
                      fontWeight: AppTypography.heading,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 36 * s),
                  toggle(
                    'Ses',
                    soundMuted,
                    on: (muted) => !muted,
                    onChanged: (on) => onSoundMuted(!on),
                  ),
                  SizedBox(height: 18 * s),
                  toggle(
                    'Titreşim',
                    vibrationOn,
                    on: (enabled) => enabled,
                    onChanged: onVibration,
                  ),
                  // Kümeler arası boşluk: ayarlar, metinler, hesap eylemleri.
                  SizedBox(height: 40 * s),
                  row('Kullanım koşulları', SettingsAction.terms, opens: true),
                  SizedBox(height: 18 * s),
                  row('Gizlilik politikası', SettingsAction.privacy,
                      opens: true),
                  SizedBox(height: 40 * s),
                  row('Çıkış yap', SettingsAction.signOut),
                  SizedBox(height: 18 * s),
                  // Kalıcı eylem düğme yüzü almaz, en altta kırmızı bağlantıdır;
                  // asıl onay bir sonraki pencerede istenir.
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(SettingsAction.deleteAccount),
                      child: SizedBox(
                        width: width,
                        height: 80 * s,
                        child: Center(
                          child: Text(
                            'Hesabı sil',
                            style: TextStyle(
                              color: _danger,
                              fontFamily: AppTypography.family,
                              fontSize: 28 * s,
                              fontWeight: AppTypography.action,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (version != null) ...[
                    SizedBox(height: 6 * s),
                    Text(
                      version!,
                      style: TextStyle(
                        color: _muted,
                        fontFamily: AppTypography.family,
                        fontSize: 22 * s,
                        fontWeight: AppTypography.caption,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// İkincil düğmenin yüzü ve ölçüsü (`SecondaryActionButton`); yazı sola
/// yaslı, sağda ok ya da anahtar durabilir.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.scale,
    required this.width,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final double scale;
  final double width;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => DepthPressableButton(
        width: width,
        height: 96 * scale,
        radius: 26 * scale,
        shadowOffset: 10 * scale,
        backgroundColor: const Color(0xFF0C2244),
        shadowColor: const Color(0xFF07182F),
        fontSize: 28 * scale,
        onPressed: onTap,
        child: Padding(
          padding: EdgeInsets.only(left: 36 * scale, right: 24 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFFE9EEF5),
                    fontFamily: AppTypography.family,
                    fontSize: 28 * scale,
                    fontWeight: AppTypography.action,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}

/// Açık/kapalı anahtarı. Uygulamanın biçim dili: hap değil yuvarlatılmış
/// dikdörtgen, topuz yuvayla eş merkezli. Durumu yuvanın rengi söyler;
/// topuz hep beyaz (gri bu uygulamada "kilitli" demek).
class _ToggleMark extends StatelessWidget {
  const _ToggleMark({required this.on, required this.scale});

  final bool on;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final inset = 6 * scale;
    final trackRadius = 16 * scale;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 88 * scale,
      height: 50 * scale,
      padding: EdgeInsets.all(inset),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? const Color(0xFF93D334) : const Color(0xFF07182F),
        borderRadius: BorderRadius.circular(trackRadius),
      ),
      child: Container(
        width: 38 * scale,
        height: 38 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF5),
          borderRadius: BorderRadius.circular(trackRadius - inset),
        ),
      ),
    );
  }
}

/// Hesap silme onayı. [delete] sunucuya gider; bitene kadar pencere
/// kapanmaz, olmazsa hata kartta yazar. Hesap silindiyse `true` döner.
Future<bool> confirmAccountDeletion(
  BuildContext context, {
  required Future<bool> Function() delete,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF041227).withValues(alpha: 0.86),
      builder: (_) => _AccountDeletionDialog(delete: delete),
    ) ??
    false;

class _AccountDeletionDialog extends StatefulWidget {
  const _AccountDeletionDialog({required this.delete});

  final Future<bool> Function() delete;

  @override
  State<_AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<_AccountDeletionDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    bool deleted;
    String? error;
    try {
      deleted = await widget.delete();
      if (!deleted) error = 'Hesap silinemedi. Tekrar dene.';
    } catch (_) {
      deleted = false;
      error = 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.';
    }
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
        // İstek yoldayken pencere kapanırsa sonuç kaybolur.
        canPop: !_busy,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width * 0.06,
          ),
          child: AccountDeletionCard(
            busy: _busy,
            error: _error,
            onConfirm: _confirm,
            onCancel: () => Navigator.of(context).pop(false),
          ),
        ),
      );
}

/// Hesap silme onayının kartı. Lig bilgi kartının kalıbı; durumu (bekleme,
/// hata) çağıran tutar, kart yalnız çizer.
class AccountDeletionCard extends StatelessWidget {
  const AccountDeletionCard({
    super.key,
    required this.onConfirm,
    required this.onCancel,
    this.busy = false,
    this.error,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool busy;
  final String? error;

  static const _background = Color(0xFF041227);
  static const _border = Color(0xFF0B2143);
  static const _muted = Color(0xFF8FA0B5);
  static const _danger = Color(0xFFF52A2A);
  static const _dangerDepth = Color(0xFF9A1414);

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 750;
    final radius = BorderRadius.circular(AppShapeStyle.cardRadius(34 * s));
    final buttonWidth = 594 * s;

    return Container(
      width: 662 * s,
      decoration: BoxDecoration(color: _border, borderRadius: radius),
      padding: EdgeInsets.only(bottom: AppShapeStyle.cardDepth(8 * s)),
      child: Container(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: radius,
          border: Border.all(
            color: _border,
            width: AppShapeStyle.outline(2 * s),
          ),
        ),
        padding: EdgeInsets.fromLTRB(34 * s, 38 * s, 34 * s, 34 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hesabın silinsin mi?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: AppTypography.displayFamily,
                fontSize: 46 * s,
                fontWeight: AppTypography.heading,
                height: 1,
              ),
            ),
            SizedBox(height: 20 * s),
            Text(
              'Puanın, serin, öğrendiğin kelimeler ve lig sıralaman kalıcı '
              'olarak silinir. Bu işlem geri alınamaz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontFamily: AppTypography.family,
                fontSize: 25 * s,
                fontWeight: AppTypography.body,
                height: 1.35,
              ),
            ),
            if (error != null) ...[
              SizedBox(height: 22 * s),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _danger,
                  fontFamily: AppTypography.family,
                  fontSize: 25 * s,
                  fontWeight: AppTypography.label,
                ),
              ),
            ],
            SizedBox(height: 40 * s),
            DepthPressableButton(
              width: buttonWidth,
              height: 96 * s,
              radius: 26 * s,
              shadowOffset: 10 * s,
              backgroundColor: _danger,
              shadowColor: _dangerDepth,
              fontSize: 28 * s,
              enabled: !busy,
              onPressed: onConfirm,
              child: busy
                  ? SizedBox.square(
                      dimension: 34 * s,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'HESABIMI SİL',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: AppTypography.family,
                        fontSize: 28 * s,
                        fontWeight: AppTypography.action,
                      ),
                    ),
            ),
            SizedBox(height: 20 * s),
            IgnorePointer(
              ignoring: busy,
              child: SecondaryActionButton(
                text: 'Vazgeç',
                scale: s,
                width: buttonWidth,
                onPressed: onCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
