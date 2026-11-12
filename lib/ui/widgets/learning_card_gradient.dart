import 'package:flutter/material.dart';

/// Rövanş durağının simgesindeki kartın yüzü (illüstrasyon katmanı, §2.2):
/// Hallo ve Fertig sahnelerindeki kartın renkleri, `karty_review_complete.png`
/// üzerinden ölçüldü; soldan sağa maviden mora gider. Oyundaki Karty kartı
/// 11 Kas 2026'dan beri lacivert (`KartyCardMaterial`); simge lacivert
/// karonun üstünde okunsun diye renkli kaldı.
const learningCardGradient = LinearGradient(
  begin: Alignment(-1, -.3),
  end: Alignment(1, .3),
  colors: [Color(0xFF0A74FB), Color(0xFF4E3CF4), Color(0xFFA64DF9)],
  stops: [0, .5, 1],
);
