import 'package:flutter/material.dart';

/// Karty kartının malzemesi: patikadaki yan durak karosu (11 Kas 2026,
/// kullanıcı onayı).
///
/// Yüz nötr lacivert. Uygulama cinsiyeti renkle öğretiyor (der mavi, die
/// kırmızı, das turuncu); kartın yüzü bunlardan biri olsaydı her kelime o
/// artikelle hafızaya yazılırdı. Büyük, parlak bir yüzey de göz yoruyordu.
/// Renk yalnız hapta, cevapta ve durumda.
///
/// Destedeki kartlar ön kartla aynı tonda: her kartın açık yüzü öndekinin
/// koyu kalınlığından ayrılır. Geriye doğru kademeli koyulaşan deste
/// (`0C2244`, `07182F`) şeritleri birbirine kattı ve tek kalın blok gibi
/// okundu (kullanıcı, 11 Kas 2026); derinliği daralan genişlikler verir.
abstract final class KartyCardMaterial {
  static const face = Color(0xFF163258);
  static const base = Color(0xFF0B2143);

  /// Doğru cevapta yüz değil yalnız kalınlık bandı yeşerir (§5 geri
  /// bildirim hiyerarşisi).
  static const correctBase = Color(0xFF628C22);

  /// Süre dolunca kart söner: kapalı durağın tonları.
  static const dimFace = Color(0xFF0C2244);
  static const dimBase = Color(0xFF07182F);

  /// Üst kenarın cam parlaması; seri kartındakiyle aynı ton.
  static const rim = Color(0xFF40527E);

  /// Kalınlık bandı, tasarım biriminde.
  static const depth = 16.0;
}
