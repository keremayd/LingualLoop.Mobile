import 'package:flutter/material.dart';

/// Ana ekrandaki seri kartının hangi **sahneyi** göstereceğine karar veren
/// kural listesi. Tek doğruluk kaynağı.
///
/// Yeni bir kart eklemek `_rules` listesine bir satır yazmaktır; ana ekran ne
/// hangi durumun özel olduğunu ne de hangi görseli çizeceğini biliyor,
/// yalnızca bağlamı verip "hangisi?" diye soruyor.
///
/// ## Neden kural listesi, düz bir `if` zinciri değil
///
/// Kartlar çoğalacak ve **koşulları örtüşecek**: bir kullanıcı aynı gün hem
/// bir kilometre taşına hem bir bağlam kartının koşuluna uyabilir.
/// Kararı `if` sırasına bırakmak bu çakışmayı görünmez kılar — hangi kartın
/// kazandığı listedeki yazım sırasına bağlı olur ve kimse fark etmez.
/// Açık `priority` alanı çakışmayı **veriye** çeviriyor: aşağıdaki tablo
/// okunarak yeni kartın nereye oturacağına karar verilebiliyor.
///
/// ## Öncelik bantları
///
/// | Bant | Ne | Gerekçe |
/// |---|---|---|
/// | 300 | Tek seferlik kilometre taşı (100, 200, 365. gün) | Hayatta bir kez yaşanır; hiçbir şeyin üstünü örtmesine izin verilmez |
/// | 200 | Tekrarlı kilometre taşı (7, 30, 50. gün) | Nadir ama tekrar eder |
/// | 100 | Davranış / bağlam kartı (hafta sonu, geç saat…) | Sık tekrarlanabilir; nadir olanın altında kalır |
/// | 0 | Sahne yok → `HomeStreakStrip` | |
///
/// **Kural: nadir olan kazanır.** Sıklık arttıkça öncelik düşer: 100. gününü
/// bir daha göremez, ama tekrarlı bir kartı yeniden görebilir.
///
/// ## Mevcut kartlar ve filtreleri
///
/// | Kart | Öncelik | Filtre |
/// |---|---|---|
/// | `gun_100` | 300 | `streak == 100` **ve** bugün oynanmış |
/// | `ritmi_koru` | 200 | `streak == 14` **ve** bugün oynanmış |
/// | `harika_gidiyorsun` | 200 | `streak == 21` **ve** bugün oynanmış — **geçici** |
/// | `hedefe_dogru` | 200 | `streak == 6` **ve** bugün oynanmış — **geçici** |
/// | `madalyani_kazan` | 200 | `streak == 15` **ve** bugün oynanmış — **geçici** |
/// | `ruzgari_yakala` | 200 | `streak == 12` **ve** bugün oynanmış — **geçici** |
/// | `istikrar_guclendirir` | 200 | `streak == 3` **ve** bugün oynanmış — **geçici** |
/// | `kendi_rekorun` | 250 | Seri kendi rekorunu geçmiş — `longestStreak` gerekiyor |
/// | `serin_korundu` | 150 | Son iki günde koruma harcanmış — `bugun_geri_don`'u yener |
/// | `bugun_geri_don` | 100 | `streak > 0` **ve** bugün oynanmamış — durum kartı |
/// | `beyni_esnet` | 100 | `streak == 0` **ve** hiç seri olmamış — henüz başlamadı |
/// | `seni_ozledik` | 100 | `streak == 0` **ve** daha önce seri olmuş — kaybetti |
///
/// "Geçici" olanların koşulu henüz kararlaştırılmadı; sayılar referans
/// kartlardan alındı, tasarım kararı değil. Karar verilince yalnız `matches`
/// değişecek.
///
/// Kilometre taşı kartları neden ayrıca "bugün oynanmış" istiyor: seri ertesi
/// sabah da aynı sayıda görünüyor (oynanana kadar artmıyor). Şart konmazsa
/// kutlama iki gün üst üste çıkar ve bir **kutlama** olmaktan çıkıp bir
/// **duruma** dönüşür.
class StreakScene {
  const StreakScene({
    required this.key,
    required this.priority,
    required this.matches,
    required this.asset,
    required this.aspect,
    required this.message,
    required this.cardColor,
    required this.sceneEdgeColor,
    this.faceOpacity = 0.45,
    this.zoom = 1.0,
    this.anchorY = 0,
    this.fadeEnd = 0.70,
  });

  /// Kayıt anahtarı — hata ayıklama ve test için.
  final String key;

  /// Büyük olan kazanır. Bantlar için sınıf açıklamasına bak.
  final int priority;

  final bool Function(StreakSceneContext context) matches;

  /// Güne özel görsel. §2.12 yoğunluk varyantlarıyla (`2.0x/`, `3.0x/`).
  final String asset;

  /// Kaynak görselin en/boy oranı. **Sahneyle birlikte gelmeli**: kartın
  /// çizim geometrisi buna bağlı ve her görselde farklı
  /// (gun_100 1540×1021, ritmi_koru 1774×887). Kodda sabitlenirse ikinci
  /// sahne sessizce esner.
  final double aspect;

  final String message;

  /// Kartın metin tarafındaki rengi.
  ///
  /// **§2.2 sapması, bilinçli.** Kaplama katmanında palet dışı renk
  /// yasaktır; bu kart istisna çünkü zemin bir kaplama değil sahnenin
  /// devamı — görselin kendi renginden örneklenir ve ona karışır. Renk
  /// uydurulmuyor, ölçülüyor.
  final Color cardColor;

  /// Sahnenin sol kenarının rengi; zemin gradyanı bu tona varıyor.
  final Color sceneEdgeColor;

  /// Yüzün opaklığı. Sahneye göre değişmek **zorunda**: parlak mavi bir uzay
  /// sahnesi %45'te okunuyor, doymuş bir yeşil aynı oranda lacivert zeminde
  /// çamura döner.
  final double faceOpacity;

  /// Sahnenin kart yüksekliğine göre çizim ölçeği.
  ///
  /// Sahneye göre değişmek zorunda çünkü **kaynak oranları farklı**: 2.0
  /// oranlı geniş bir banner kart yüksekliğinde zaten kutuyu dolduruyor
  /// (236 × 2.0 = 472 > 362), 1.5 oranlı kare bir sahne dolduramıyor ve
  /// büyütülmesi gerekiyor. Ölçek çok yükseğe çekilirse taşan kısım üstten
  /// kırpılır ve maskotun antenleri gider.
  final double zoom;

  /// Görsel karttan yüksek olduğunda **hangi dikey kesitin** görüneceği
  /// (`-1` üst kenar, `+1` alt kenar sabit).
  ///
  /// Sahneye göre değişmek zorunda çünkü özne her görselde farklı yerde:
  /// ay sahnesinde zemin altta kalmalı (`+0.85`, kırpma üstteki boş
  /// gökyüzünden gider), fidan sahnesinde maskotun hem antenleri hem
  /// ayakları kadrajda kalmalı, yani kırpma **iki taraftan** dengeli
  /// paylaşılmalı.
  final double anchorY;

  /// Sönümün tamamlandığı nokta (kart oranı). Sahneye göre değişmek zorunda:
  /// rampa **öznenin soluna** bitmeli, yoksa özne yarı saydam kalır.
  ///
  /// Fidan sahnesinde sulanan fidan sönümün ortasına düşüp belirsizleşmişti;
  /// kaynağın sol %40'ı zaten düz yeşil olduğu için rampa sola çekilebiliyor
  /// (kutu genişliyor, kırpma azalıyor) ve fidan tam opak kalıyor.
  final double fadeEnd;

  static const _rules = <StreakScene>[
    StreakScene(
      key: 'gun_100',
      priority: 300,
      matches: _isDay100,
      asset: 'assets/scenes/gun_100.png',
      aspect: 1540 / 1021,
      message: 'Galaksi seviyesindesin!',
      // Ölçüldü: bayrağın mavisi ve gökyüzünün sol kenarı.
      cardColor: Color(0xFF004AF4),
      sceneEdgeColor: Color(0xFF000845),
      // 1.5 oranlı sahne kart yüksekliğinde 354 birim kalıyor, 362 birimlik
      // kutuyu dolduramıyor; ayrıca gerçek boyutta maskot okunmuyordu.
      zoom: 1.30,
      anchorY: 0.85,
      fadeEnd: 0.70,
    ),
    StreakScene(
      key: 'ritmi_koru',
      priority: 200,
      matches: _isDay14,
      asset: 'assets/scenes/ritmi_koru.png',
      aspect: 1774 / 887,
      message: 'Ritmi koru!',
      // Ölçüldü. Referans kartın yüzü ile sahnenin sol kenarı **aynı yeşil**
      // (`#18B386` / `#16B183`) — sahne zaten düz bir zeminle başlıyor, o
      // yüzden geçiş kusursuz. Buradaki değer %88 opaklıkta sayfa zemininin
      // üstünde referans yüzeyi veriyor.
      cardColor: Color(0xFF26CB96),
      sceneEdgeColor: Color(0xFF1FB687),
      // Yeşil doymuş bir renk; %45'te lacivert zeminde çamura dönüyor.
      faceOpacity: 0.88,
      // Kaynakta maskot y %11.5–77.8, toprak %84.6'ya iniyor (ölçüldü):
      // üstte %11.5, altta %15.4 kırpılabilir pay var. Toplam %26.9 pay
      // 1.37 ölçeğe kadar yetiyor; 1.28 güvenli tarafta kalıyor.
      zoom: 1.28,
      // Kırpma iki taraftan **payların oranında** paylaşılıyor
      // (11.5 / 15.4), yoksa antenler ya da ayaklar gidiyor.
      anchorY: -0.15,
      // Fidan kaynağın %55'inde; bu ayarla kart üzerinde %59'a düşüyor,
      // yani rampa (%26 → %50) bitmiş oluyor.
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'harika_gidiyorsun',
      priority: 200,
      // **Geçici filtre.** Hangi koşulda çıkacağı henüz kararlaştırılmadı;
      // referans kart 21 gün gösteriyor, o alındı. Karar verilince
      // `_isDay21` değişecek, kartın geri kalanına dokunulmayacak.
      matches: _isDay21,
      asset: 'assets/scenes/harika_gidiyorsun.png',
      aspect: 1672 / 941,
      message: 'Harika gidiyorsun!',
      // Ölçüldü: referans kartın yüzü `#FA822E`, sahnenin sol kenarı
      // `#FD8B36`. Turuncu neredeyse doygunluk tavanında olduğu için
      // saydamlık geri hesaplanınca kırmızı kanalı 255'i aşıyor; %95'te
      // kompozit `#F2822E` çıkıyor, referanstan gözle ayırt edilmiyor.
      cardColor: Color(0xFFFF882E),
      sceneEdgeColor: Color(0xFFFD8B36),
      faceOpacity: 0.95,
      // Kaynakta kupa y %10'dan, maskotun ayakları %86'dan başlıyor:
      // üstte %10, altta %14 pay var, 1.32 ölçeğe kadar yetiyor.
      // 1.22 hem güvenli hem kutuyu dolduruyor (496 birim gerekiyor,
      // 512 çıkıyor).
      zoom: 1.22,
      anchorY: -0.15,
      // Kupa kaynağın %51'inde; bu ayarla kart üzerinde %63'e düşüyor,
      // rampanın (%26 → %50) dışında kalıyor.
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'hedefe_dogru',
      priority: 200,
      // **Geçici filtre**, referans karttaki sayıdan alındı.
      matches: _isDay6,
      asset: 'assets/scenes/hedefe_dogru.png',
      aspect: 1672 / 941,
      message: 'Haydi yüksel!',
      // Bu sahnenin zemini **çapraz gradyan** (sol üstte koyu mavi, sağ altta
      // camgöbeği) — diğerleri gibi düz değil. Kartın kendi yatay gradyanı
      // bunu iyi yaklaşıyor: sol uç sahnenin sol kenarı, sağ uç sönümün
      // ortasında görünen ton.
      //
      // Referans kartın yüzü `#339DF5`; mavi kanal doygunluk tavanına yakın
      // olduğu için saydamlık geri hesaplanınca 255'e dayanıyor. %95'te
      // kompozit `#329DF4` çıkıyor — referansla neredeyse birebir.
      cardColor: Color(0xFF35A4FF),
      sceneEdgeColor: Color(0xFF2EA2F1),
      faceOpacity: 0.95,
      // En üstteki özne kâğıt uçak (y %11.3), en alttaki maskotun ayakları
      // (~%82): üstte %11, altta %18 pay var, 1.41 ölçeğe kadar yetiyor.
      zoom: 1.25,
      // Kırpma payların oranında (11 / 18).
      anchorY: -0.25,
      // Uçak kaynağın %56'sında; kart üzerinde %66'ya düşüyor, rampanın
      // (%26 → %50) dışında.
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'beyni_esnet',
      // Kilometre taşı değil **durum** kartı: "serin yok, başla". Bu yüzden
      // davranış/bağlam bandında — bir kilometre taşıyla çakışması zaten
      // mümkün değil (seri 0 iken kilometre taşı olmaz) ama bant anlamı
      // doğru kalsın.
      priority: 100,
      matches: _isNoStreak,
      asset: 'assets/scenes/beyni_esnet.png',
      aspect: 1774 / 887,
      message: 'Beyni esnetme zamanı!',
      // Referans kartın yüzü `#6542B9`; %88 opaklıkta tam o çıkıyor.
      cardColor: Color(0xFF7249CD),
      sceneEdgeColor: Color(0xFF652FB4),
      faceOpacity: 0.88,
      // Maskot y %17.4–77.8: üstte %17.4, altta %22.2 pay var, 1.66 ölçeğe
      // kadar yetiyor. 1.25'te matara (kaynağın %52'si) kart üzerinde
      // %58'e düşüyor, rampanın (%26 → %50) dışında kalıyor; şeridin bittiği
      // %52 noktası ise kaynağın %45.5'ine denk geliyor, orası düz mor.
      zoom: 1.25,
      anchorY: -0.12,
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'madalyani_kazan',
      priority: 200,
      // **Geçici filtre**, referans karttaki sayıdan alındı.
      matches: _isDay15,
      asset: 'assets/scenes/madalyani_kazan.png',
      aspect: 1659 / 948,
      message: 'Madalyanı kazan!',
      // Sahne baştan sona **yatay gradyan**: `#7429F8` (sol) → `#01C9F8`
      // (sağ). Kartın kendi gradyanı bu eksende çalıştığı için birebir
      // örtüşüyor — `hedefe_dogru`'daki çapraz gradyandan daha kolay.
      //
      // Referans kartın sol yüzü `#753FF5`; mavi kanal doygunluk tavanında
      // olduğu için %95 opaklık gerekti, kompozit `#753FF4`.
      cardColor: Color(0xFF7B41FF),
      sceneEdgeColor: Color(0xFF573CF7),
      faceOpacity: 0.95,
      // Maskot y ~%17–82: üstte %17, altta %18 pay, 1.54 ölçeğe kadar
      // yetiyor. 1.30'da madalya (kaynağın %51.8'i) kart üzerinde %61'e
      // düşüp rampanın (%26 → %50) dışında kalıyor; şeridin bittiği %52
      // noktası kaynağın %40'ına denk geliyor, orası düz gradyan.
      zoom: 1.30,
      // Paylar neredeyse eşit (17 / 18), kırpma da öyle.
      anchorY: -0.04,
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'bugun_geri_don',
      // Kilometre taşı değil **durum** kartı: seri ayakta ama bugün henüz
      // kurtarılmadı. `beyni_esnet` ile aynı bantta ve onunla çakışmıyor
      // (o seri sıfırken, bu sıfırdan büyükken çıkıyor).
      priority: 100,
      matches: _isTodayPending,
      asset: 'assets/scenes/bugun_geri_don.png',
      aspect: 1672 / 941,
      message: 'Bugün geri dön!',
      // Referans kartın sol yüzü `#6E3FE8`; %92 opaklıkta tam o çıkıyor.
      cardColor: Color(0xFF7743F9),
      sceneEdgeColor: Color(0xFF7353F1),
      faceOpacity: 0.92,
      // **En dar çerçeveleme payı olan sahne.** En üstteki özne yağmur
      // bulutu (y %6), en alttaki maskotun ayakları (~%88): üstte yalnız
      // %6, altta %12 pay var, yani ölçek 1.22'yi geçemiyor. Alt sınır da
      // var: kutuyu doldurmak için en az 1.18 gerekiyor. Aralık dar,
      // 1.20 seçildi.
      zoom: 1.20,
      // Kırpma payların oranında (6 / 12) — üstten yalnız 16 birim
      // kırpılıyor, bulutun tepesi 17 birim yukarıda.
      anchorY: -0.32,
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'istikrar_guclendirir',
      priority: 200,
      // **Geçici filtre**, referans karttaki sayıdan alındı.
      matches: _isDay3,
      asset: 'assets/scenes/istikrar_guclendirir.png',
      aspect: 1672 / 941,
      // Referans kart iki satır yazıyor ("Harika! İstikrarın seni
      // güçlendiriyor!") ama kartta ikinci satıra yer yok — mesaj y 92'de
      // başlıyor, gün etiketleri 148'de. "Harika!" kısmı bilgi taşımıyor,
      // atıldı.
      message: 'İstikrarın seni güçlendiriyor!',
      // Referans kartın sol yüzü `#1575E6`; %92 opaklıkta tam o çıkıyor.
      cardColor: Color(0xFF167EF7),
      sceneEdgeColor: Color(0xFF2691F0),
      faceOpacity: 0.92,
      // Antenler y ~%16, ayaklar ~%87: üstte %16, altta %13 pay,
      // 1.41 ölçeğe kadar yetiyor. 1.28'de takvimin sol kenarı (kaynağın
      // %45.6'sı) kart üzerinde %56'ya düşüp rampanın dışında kalıyor.
      zoom: 1.28,
      // Kırpma payların oranında (16 / 13) — bu sefer **üstten** daha çok.
      anchorY: 0.09,
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'seni_ozledik',
      priority: 100,
      matches: _isStreakLost,
      asset: 'assets/scenes/seni_ozledik.png',
      aspect: 1870 / 841,
      message: 'Seni özledik!',
      // Referans kartın sol yüzü `#7D5CC7` — sahnenin sol kenarından
      // (`#B193F2`) belirgin koyu; mockup'ın kendi gradyanı. %88 opaklıkta
      // referans yüzü çıkıyor.
      cardColor: Color(0xFF8D66DD),
      sceneEdgeColor: Color(0xFFB093F1),
      faceOpacity: 0.88,
      // En üstteki özne yağmur bulutu (y %6.4), en alttaki ayaklar (%86.6):
      // pay yalnız %19.8, ölçek 1.25'i geçemiyor. Kaynak 2.22 oranında
      // olduğu için alt sınır yok (kutuyu 0.95'te bile dolduruyor).
      zoom: 1.15,
      // Kırpma payların oranında (6.4 / 13.4).
      anchorY: -0.37,
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'ruzgari_yakala',
      priority: 200,
      // **Geçici filtre**, referans karttaki sayıdan alındı.
      matches: _isDay12,
      asset: 'assets/scenes/ruzgari_yakala.png',
      aspect: 1672 / 941,
      message: 'Rüzgarı yakala!',
      // Referans kartın sol yüzü `#2289F2`; mavi kanal doygunluk tavanına
      // yakın, %95 opaklıkta tam o çıkıyor.
      cardColor: Color(0xFF248FFD),
      sceneEdgeColor: Color(0xFF2195F1),
      faceOpacity: 0.95,
      // **En dar aralıklı sahne.** En üstteki özne uçurtma (y %6.8), en
      // alttaki ayaklar (~%89): pay yalnız %17.8, üst sınır 1.216. Kutuyu
      // doldurmak için alt sınır 1.183. Aralık 1.183–1.216, seçilen 1.20 —
      // `bugun_geri_don`'dan bile dar.
      zoom: 1.20,
      // Kırpma payların oranında (6.8 / 11).
      anchorY: -0.23,
      fadeEnd: 0.50,
    ),
    StreakScene(
      key: 'serin_korundu',
      // **100 bandının üstünde.** O an `bugun_geri_don`'un koşulu da
      // sağlanıyor (seri var, bugün oynanmadı) ve ikisi çakışıyor. Koruma
      // harcamak günlük "bugün dönmedin" durumundan çok daha nadir, bu
      // yüzden kazanmalı — "nadir olan kazanır" ilkesi.
      priority: 150,
      matches: _isFreezeUsed,
      asset: 'assets/scenes/serin_korundu.png',
      aspect: 1774 / 887,
      message: 'Serin korundu!',
      // **Bu sahnenin kart mockup'ı yok**, renk ölçülecek referans yüzey de
      // yok. Zemin ölçüldü (`#53C6FD`) ama parlaklığı 171 — beyaz metin o
      // tonda okunmuyor. Opaklık %68'e indirilerek kompozit `#398CB7`'ye
      // çekildi (parlaklık 120, diğer kartların bandı). `seni_ozledik`'te
      // de referans kartın yüzü sahneden belirgin koyuydu; aynı kalıp.
      cardColor: Color(0xFF53C6FD),
      sceneEdgeColor: Color(0xFF5ACBFE),
      faceOpacity: 0.68,
      // Buz bloğu kaynağın **%48.4**'ünden başlıyor, şerit ise kartın
      // %52'sinde bitiyor — binişme var. Ölçek yükseldikçe buz sola
      // kayıyor (sağa yaslı çizildiği için konumu yalnız çizim genişliğine
      // bağlı), 1.15'te kart üzerinde %58'e oturuyor ve rampanın (%32 →
      // %56) dışında kalıyor.
      zoom: 1.15,
      // Kaynakta buzun üstünde %30 boş alan var, altta yalnız %12; kırpma
      // neredeyse tamamen üstten yapılıyor ki sahne kartın tabanına otursun.
      anchorY: 0.9,
      fadeEnd: 0.56,
    ),
    StreakScene(
      key: 'kendi_rekorun',
      // Kilometre taşlarının (200) üstünde: sabit bir sayıya değil
      // kullanıcının **kendi** geçmişine bağlı, o yüzden daha nadir ve daha
      // kişisel. 300 tek seferliklere ayrılmış.
      priority: 250,
      matches: _isPersonalRecord,
      asset: 'assets/scenes/kendi_rekorun.png',
      aspect: 1774 / 887,
      message: 'En uzun serindesin!',
      // **`cardColor`'ın üçüncü türetme yolu.** Diğer ikisi: referans kartın
      // yüzeyine eşitle (çoğu sahne) ya da kontrasttan hesapla
      // (`serin_korundu`). Burada ikisi de işlemiyor: kart mockup'ı yok ve
      // sahne baştan sona neredeyse siyah (`#010B1F`, parlaklık **9**) —
      // sayfa zemininden (parlaklık 16) bile koyu. Olduğu gibi alınsa kart
      // sayfada bir **delik** gibi okunurdu.
      //
      // Yüz bu yüzden sahnenin **kendi tonundan** alınıp görünür bir
      // parlaklığa (≈46) kaldırıldı. Gerekçesi sahnenin kendi aydınlatması:
      // ışık ateşten geliyor, ondan uzaklaştıkça sönüyor. Yani gradyan
      // uydurma değil, sahnenin ışık düşüşünün devamı.
      cardColor: Color(0xFF1A3467),
      sceneEdgeColor: Color(0xFF010B1F),
      faceOpacity: 0.88,
      // Alev y %12.4–92: üstte %12.4, altta %8 pay — ölçek 1.26'yı geçemiyor.
      zoom: 1.15,
      anchorY: 0.2,
      // Alevin sol kenarı kaynağın %50'sinde; 1.15 ölçekte kart üzerinde
      // %60'a düşüyor, rampanın (%32 → %56) dışında kalıyor.
      fadeEnd: 0.56,
    ),
  ];

  static bool _isDay100(StreakSceneContext c) =>
      c.playedToday && c.streak == 100;

  static bool _isDay14(StreakSceneContext c) => c.playedToday && c.streak == 14;

  static bool _isDay21(StreakSceneContext c) => c.playedToday && c.streak == 21;

  static bool _isDay6(StreakSceneContext c) => c.playedToday && c.streak == 6;

  static bool _isDay15(StreakSceneContext c) => c.playedToday && c.streak == 15;

  static bool _isDay3(StreakSceneContext c) => c.playedToday && c.streak == 3;

  static bool _isDay12(StreakSceneContext c) =>
      c.playedToday && c.streak == 12;

  /// Seri, kullanıcının **kendi en uzun serisini** geçmiş.
  static bool _isPersonalRecord(StreakSceneContext c) => c.isPersonalRecord;

  /// Son iki günde koruma harcanmış. Kart kutlama değil **rahatlama**:
  /// "az kalsın gidiyordu ama kurtuldu".
  static bool _isFreezeUsed(StreakSceneContext c) => c.freezeUsedRecently;

  /// Seri ayakta ama bugün henüz oynanmamış. Kartın işi kutlamak değil
  /// **geri çağırmak**.
  static bool _isTodayPending(StreakSceneContext c) =>
      c.streak > 0 && !c.playedToday;

  /// Seri yok ve **hiç olmamış** — henüz başlamamış kullanıcı.
  /// `playedToday` aranmıyor: kart bir kutlama değil çağrı.
  static bool _isNoStreak(StreakSceneContext c) =>
      c.streak == 0 && !c.hasEverStreaked;

  /// Seri yok ama **bir zamanlar vardı** — kaybedilmiş seri.
  ///
  /// İki durum ayrı kartı hak ediyor: biri henüz kaybetmemiş ("haydi
  /// başla"), diğeri kaybetmiş ("seni özledik"). Aynı kovaya konsalardı
  /// yeni kullanıcıya kaybetmiş gibi davranılırdı.
  static bool _isStreakLost(StreakSceneContext c) =>
      c.streak == 0 && c.hasEverStreaked;

  /// Bağlama uyan **en yüksek öncelikli** sahne; yoksa `null`.
  static StreakScene? resolve(StreakSceneContext context) {
    StreakScene? best;
    for (final rule in _rules) {
      if (!rule.matches(context)) continue;
      if (best == null || rule.priority > best.priority) best = rule;
    }
    return best;
  }

  /// Anahtarla doğrudan erişim — yalnız hata ayıklama ve önizleme için.
  static StreakScene byKey(String key) =>
      _rules.firstWhere((rule) => rule.key == key);
}

/// Kuralların baktığı bütün olgular. Yeni bir filtre gerekiyorsa **önce
/// buraya** bir alan eklenir; kurallar ham veriye değil bu bağlama bakar.
class StreakSceneContext {
  const StreakSceneContext({
    required this.streak,
    required this.playedToday,
    required this.hasEverStreaked,
    required this.freezeUsedRecently,
    required this.isPersonalRecord,
  });

  final int streak;

  /// Bugün herhangi bir oyun oynandı mı (`user_daily_activity.played`).
  final bool playedToday;

  /// Kullanıcının **daha önce** bir serisi olmuş mu (`user_streak
  /// .longest_streak > 0`). "Hiç başlamadı" ile "kaybetti" ayrımı bunda.
  ///
  /// **Şu an her zaman `false`**: ana ekranı besleyen `score-with-lives`
  /// yanıtı `longestStreak` taşımıyor. Alan eklenene kadar `seni_ozledik`
  /// yalnız debug döngüsünden görülebiliyor.
  final bool hasEverStreaked;

  /// Son iki günden biri korumayla kapatılmış mı
  /// (`user_daily_activity.frozen`).
  ///
  /// İki gün, bir gün değil: `ResolveStreakFreeze` **kaçırılan** günleri
  /// işaretliyor ve `LastActiveDate`'i düne çekiyor — yani bugün değil,
  /// dün (ve öncesi) frozen oluyor. Tek güne baksaydı kart hiç çıkmazdı.
  final bool freezeUsedRecently;

  /// `streak > user_streak.longest_streak`.
  ///
  /// **Şu an her zaman `false`** — `hasEverStreaked` ile aynı sebep:
  /// `score-with-lives` yanıtı `longestStreak` taşımıyor. Tek bir alan
  /// eklemek bu kartı ve `seni_ozledik`'i birlikte açıyor.
  final bool isPersonalRecord;

}
