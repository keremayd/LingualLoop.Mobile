import 'package:lingualloop/ui/app_typography.dart';
import 'package:flutter/material.dart';

import '../widgets/Buttons/depth_pressable_button.dart';
import '../widgets/Buttons/secondary_action_button.dart';
import '../widgets/mascot_mark.dart';

/// Hoş geldin ekranı — uygulamanın **ilk** ekranı.
///
/// Önceki hâli 44 satırdı: varsayılan beyaz `AppBar` ve iki yeşil buton.
/// Logo yok, tek satır metin yok, zemin bile ayarlanmamıştı — uygulamanın
/// koyu lacivert dilinin tamamen dışında duran tek yüzeydi.
///
/// ## Dikey bütçe
///
/// Diğer ekranlar gibi tasarım birimi kullanıyor (`genişlik / 750`). 430px
/// bir cihazda ekran yüksekliği ≈ 1626 birim; blokların toplamı bunun altında
/// kalıyor ve artan yer maskota gidiyor (`Expanded`), yani daha uzun bir
/// ekranda görsel büyüyor, kısa ekranda küçülüyor — metin ve butonlar sabit.
///
/// ## Maskot yuvası
///
/// Görsel şeffaf zeminli. Yuva 430px bir cihazda **375 × 545px** (oran
/// ≈ 0.69, dikey); `mascot_hello.png` bundan daha kare olduğu için `contain`
/// genişlikten sınırlanıyor ve dikeyde nefes payı kalıyor — istenen bu.
///
/// Poz seçimi ölçülerek yapıldı: önceki yer tutucu (`mascot_flex.png`,
/// şimşeği havaya kaldıran poz) kart boyutunda sevimli okunuyordu ama
/// kahraman boyutunda **ürkütücüydü** — alındaki bant çatık kaş oluşturuyor,
/// açık ağız ve dişler kükreme gibi duruyordu.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _background = Color(0xFF041227);
  static const _text = Color(0xFFE9EEF5);
  static const _muted = Color(0xFF8FA0B5);

  /// Giriş butonunun yeşili (§2.2) — kayıt birincil eylem olduğu için onda.
  static const _primary = Color(0xFF98DE25);
  static const _primaryShadow = Color(0xFF6EA51C);

  /// Sahnenin ekran yüksekliğine oranı.
  ///
  /// 0.62'den 0.73'e çıkarıldı: sönümün bittiği yer ile başlık arasında boş
  /// bir bant kalıyordu. Yuva uzayınca sahne metne kadar iniyor ve bant
  /// kapanıyor — sönüm zaten yumuşak olduğu için metnin okunurluğu etkilenmiyor.
  static const _sceneHeight = 0.73;

  /// Görselin ekran genişliğine göre çizim ölçeği. Kaynağın kendi kadrajında
  /// bol boşluk var; 1.0'da özne yuvada küçük kalıyor.
  static const _sceneZoom = 1.20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          // Sahne ekranın **üstünü baştan başa** kaplıyor ve aşağı doğru
          // sayfa zeminine eriyor. Kesilmiş bir figür ortada dururken
          // kompozisyon kurulamıyordu — kompoze edilecek bir şey yok.
          // Sönüm kartlardakiyle aynı teknik (`ShaderMask` + `dstIn`),
          // yalnız ekseni dikey.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: MediaQuery.of(context).size.height * _sceneHeight,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                    stops: [0.62, 1.0],
                  ).createShader(rect),
                  // Görselin kendi kadrajında üstte %26, altta %22 boşluk
                  // var; yuvaya olduğu gibi konunca özne küçük kalıyordu.
                  // Kartlardaki yöntemin aynısı: yakınlaştır, taşanı kırp.
                  child: ClipRect(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      // Yatayda sola yaslı: yakınlaştırma kırpması eşit
                      // dağıtılınca maskotun sol kolu kesiliyordu (kaynakta
                      // %7'den başlıyor). Kırpma sağdan alınıyor, orada
                      // kartın düz kenarı var.
                      alignment: const Alignment(-0.5, -0.1),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * _sceneZoom,
                        child: Image.asset(
                          'assets/scenes/welcome_hero.png',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = constraints.maxWidth / 750;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    48 * scale,
                    24 * scale,
                    48 * scale,
                    34 * scale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _wordmark(scale),

                      // Sahnenin kapladığı yer; metin onun altından başlıyor.
                      Expanded(child: Container()),

                      // Metin **görselin üstünde**: onboarding'de önce ne
                      // olduğu okunur, sonra karaktere bakılır. Bir tur altta
                      // denendi; maskotun altına sıkışıp ekranın tepesinde
                      // 300px ölü alan bıraktı.
                      Text(
                        'Almancayı oyunlarla öğren',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _text,
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 48 * scale,
                          fontWeight: AppTypography.heading,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 16 * scale),
                      Text(
                        'Günde birkaç dakika yeter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontFamily: AppTypography.family,
                          fontSize: 26 * scale,
                          fontWeight: AppTypography.body,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: 44 * scale),
                      DepthPressableButton(
                        text: 'Ücretsiz başla',
                        width: 654 * scale,
                        height: 96 * scale,
                        radius: 26 * scale,
                        shadowOffset: 10 * scale,
                        backgroundColor: _primary,
                        shadowColor: _primaryShadow,
                        fontSize: 28 * scale,
                        fontWeight: AppTypography.action,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                      ),
                      SizedBox(height: 20 * scale),
                      SecondaryActionButton(
                        text: 'Zaten hesabım var',
                        scale: scale,
                        width: 654 * scale,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signin'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Loop şimşeği + kelime işareti. Şimşek **painter** (`MascotBolt`), görsel
  /// değil: her boyutta net kalıyor ve modelin uydurduğu standart ⚡ formuyla
  /// karışma riski yok.
  Widget _wordmark(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MascotBolt(size: 62 * scale),
        SizedBox(width: 14 * scale),
        Text(
          'LingualLoop',
          style: TextStyle(
            color: _text,
            fontFamily: AppTypography.displayFamily,
            fontSize: 34 * scale,
            fontWeight: AppTypography.heading,
            letterSpacing: 0.4 * scale,
          ),
        ),
      ],
    );
  }
}
