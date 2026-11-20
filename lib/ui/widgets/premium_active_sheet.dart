import 'package:flutter/material.dart';
import 'package:stelinda/Utils/AppNotifier.dart';
import 'package:stelinda/l10n/l10n.dart';
import 'package:stelinda/services/subscription_management.dart';
import 'package:stelinda/ui/app_typography.dart';
import 'package:stelinda/ui/widgets/Buttons/depth_pressable_button.dart';
import 'package:stelinda/ui/widgets/premium_ticket_mark.dart';

/// Premium üyeye satış ekranı yerine açılır: üyeliğin etkin olduğunu ve
/// aboneliğin mağazadan yönetildiğini söyler (alt menüdeki ∞ bilet, üst
/// şeritteki bilet).
Future<void> showPremiumActiveSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      isScrollControlled: true,
      builder: (sheetContext) => PremiumActiveSheetPanel(
        onManage: () async {
          final failed = sheetContext.l10n.premiumManageFailed;
          Navigator.of(sheetContext).pop();
          if (!await SubscriptionManagement.open()) {
            AppNotifier.showMessage(failed);
          }
        },
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );

class PremiumActiveSheetPanel extends StatelessWidget {
  const PremiumActiveSheetPanel({
    super.key,
    required this.onManage,
    required this.onClose,
  });

  final VoidCallback onManage;
  final VoidCallback onClose;

  static const _bg = Color(0xFF041227);
  static const _lip = Color(0xFF0B2143);
  static const _handle = Color(0xFF163258);
  static const _muted = Color(0xFF8FA0B5);
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
                  PremiumTicketMark(width: 170 * s),
                  SizedBox(height: 30 * s),
                  Text(
                    l10n.premiumActiveTitle,
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
                    l10n.premiumActiveBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontFamily: AppTypography.family,
                      fontSize: 25 * s,
                      fontWeight: AppTypography.body,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 40 * s),
                  DepthPressableButton(
                    text: l10n.premiumManage,
                    width: width,
                    height: 96 * s,
                    radius: 26 * s,
                    shadowOffset: 10 * s,
                    backgroundColor: _accent,
                    shadowColor: _accentDepth,
                    fontSize: 28 * s,
                    onPressed: onManage,
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
                            l10n.premiumActiveClose,
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
