import 'package:flutter/material.dart';
import 'package:stelinda/l10n/l10n.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:stelinda/ui/widgets/Buttons/secondary_action_button.dart';

/// Sıralamada başka birine dokununca seçilen eylem. App Store kuralı 1.2:
/// kullanıcıların birbirine gösterdiği içerik (ad, fotoğraf) bildirilebilmeli,
/// kişi engellenebilmeli.
sealed class LeagueMemberAction {
  const LeagueMemberAction();
}

/// Sebep sunucunun beklediği anahtar: name, photo ya da other.
class LeagueMemberReport extends LeagueMemberAction {
  const LeagueMemberReport(this.reason);

  final String reason;
}

class LeagueMemberBlock extends LeagueMemberAction {
  const LeagueMemberBlock();
}

/// Ayarlar penceresinin kalıbıyla alttan açılır. Önce Bildir / Engelle,
/// sonra sebep ya da engel onayı; kapatılırsa null döner.
Future<LeagueMemberAction?> showLeagueMemberSheet(
  BuildContext context, {
  required String name,
}) =>
    showModalBottomSheet<LeagueMemberAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (sheetContext) => LeagueMemberSheetPanel(
        name: name,
        onDone: (action) => Navigator.of(sheetContext).pop(action),
      ),
    );

enum _Step { choose, report, block }

class LeagueMemberSheetPanel extends StatefulWidget {
  const LeagueMemberSheetPanel({
    super.key,
    required this.name,
    required this.onDone,
  });

  final String name;
  final ValueChanged<LeagueMemberAction?> onDone;

  @override
  State<LeagueMemberSheetPanel> createState() => _LeagueMemberSheetPanelState();
}

class _LeagueMemberSheetPanelState extends State<LeagueMemberSheetPanel> {
  static const _bg = Color(0xFF041227);
  static const _lip = Color(0xFF0B2143);
  static const _handle = Color(0xFF163258);
  static const _muted = Color(0xFF8FA0B5);
  static const _danger = Color(0xFFF52A2A);
  static const _dangerDepth = Color(0xFF9A1414);

  var _step = _Step.choose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final s = size.width / 750;
    final width = 670 * s;
    final radius = Radius.circular(56 * s);

    Widget option(String text, VoidCallback onTap) => Padding(
          padding: EdgeInsets.only(bottom: 18 * s),
          child: SecondaryActionButton(
            text: text,
            scale: s,
            width: width,
            onPressed: onTap,
          ),
        );

    final (String title, String? body, List<Widget> options) = switch (_step) {
      _Step.choose => (
          widget.name,
          null,
          [
            option(l10n.leagueMemberReport,
                () => setState(() => _step = _Step.report)),
            option(l10n.leagueMemberBlock,
                () => setState(() => _step = _Step.block)),
          ],
        ),
      _Step.report => (
          l10n.leagueReportTitle,
          null,
          [
            option(l10n.leagueReportReasonName,
                () => widget.onDone(const LeagueMemberReport('name'))),
            option(l10n.leagueReportReasonPhoto,
                () => widget.onDone(const LeagueMemberReport('photo'))),
            option(l10n.leagueReportReasonOther,
                () => widget.onDone(const LeagueMemberReport('other'))),
          ],
        ),
      _Step.block => (
          l10n.leagueBlockTitle(widget.name),
          l10n.leagueBlockBody,
          [
            Padding(
              padding: EdgeInsets.only(bottom: 18 * s),
              child: DepthPressableButton(
                text: l10n.leagueMemberBlock,
                width: width,
                height: 96 * s,
                radius: 26 * s,
                shadowOffset: 10 * s,
                backgroundColor: _danger,
                shadowColor: _dangerDepth,
                fontSize: 28 * s,
                onPressed: () => widget.onDone(const LeagueMemberBlock()),
              ),
            ),
          ],
        ),
    };

    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
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
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 46 * s,
                      fontWeight: AppTypography.heading,
                      height: 1.1,
                    ),
                  ),
                  if (body != null) ...[
                    SizedBox(height: 16 * s),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontFamily: AppTypography.family,
                        fontSize: 25 * s,
                        fontWeight: AppTypography.body,
                        height: 1.3,
                      ),
                    ),
                  ],
                  SizedBox(height: 36 * s),
                  ...options,
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onDone(null),
                      child: SizedBox(
                        width: width,
                        height: 80 * s,
                        child: Center(
                          child: Text(
                            l10n.leagueMemberCancel,
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
