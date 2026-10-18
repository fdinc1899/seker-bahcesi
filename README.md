# Şeker Bahçesi 🍬 — V2 Paket 5: Kutlama ve Yıldız Ödülleri

Bu paket önceki **V2 Paket 4'ün üzerine kurulmuş tam Flutter kaynak projesidir**. Telefon üzerinde çalıştığı doğrulanmış şeker eşleştirme, özgün arka plan müziği, patlama sesleri, kombo animasyonları, buz/çikolata/kilit engelleri, 60 bölüm, seviye haritası, yerel kayıt ve güçlendiriciler korunur.

## Bu sürümde yenilikler

- **Kazanma ekranı:** arka planda uçuşan çok renkli konfetiler, sırayla açılan altın yıldızlar, puan rozeti ve animasyonlu sonuç kartı.
- **Üç yıldız ödülü:** bir bölümde *ilk kez* 3 yıldız elde edildiğinde **+1 Karıştır** güçlendiricisi. Tekrar oynayarak ödül çoğaltılamaz; mevcut `stars` kaydı kontrol edilir.
- **Kaybetme ekranı:** hedefe ulaşılmadığında tekrar deneme düğmesi ve kısa eşleştirme ipucu.
- **Geçiş:** sonuç ekranından sonraki bölüme, bölüm haritasına veya aynı bölümü yeniden oynamaya geçiş.
- **Ana ekran OYNA:** bitmiş bölüm yerine açılmış en güncel bölüme; devam eden kaydedilmiş oyun varsa ona geçer.
- **Ses:** Paket 4'ten gelen arka plan müziği, kazanma ve kaybetme sesleri aynen korunur.

## Kayıt uyumluluğu

Önceki `unlocked`, `stars`, `session`, `hammers`, `lineBlasts`, `shuffles` ve `sound` SharedPreferences anahtarları korunur; yeni bir kaydetme alanı eklenmedi. İlk 3 yıldız ödülünün bir kere verilmesi zaten kaydedilen en iyi yıldız sayısından hesaplanır. APK'ların aynı paket kimliği ve imza ile güncellenmesi gerekir; **oyunun eski kurulumunu silmeyin**; aksi hâlde cihazdaki yerel ilerleme kaybolabilir.

## GitHub'da APK alma

Depoda ana dala yükleyince `.github/workflows/android-apk.yml` otomatik olarak `flutter pub get`, `flutter test` ve `flutter build apk --debug` çalıştırır. Testler geçerse **Actions → en yeni başarılı Android APK oluştur → Artifacts → `seker-bahcesi-v2-paket5-kutlama-odul-apk`** altından APK içeren ZIP indirilir.

Bu Flutter projesinde sürüm `1.5.0+6` olarak ayarlanmıştır. **Bu ortamda Flutter SDK yok, dolayısıyla testlerin ve APK derlemesinin sonucu GitHub Actions tarafından doğrulanmalıdır.** Proje Google Play'e hazır imzalı sürüm değildir.

## Geliştirme ve kaynaklar

- `lib/main.dart` : ekranlar, ilerleme kaydı, giriş ve ses entegrasyonu
- `lib/level_result.dart` : animasyonlu yıldızlar, konfeti, ödül ve başarısızlık kartları
- `lib/reward_rules.dart` : tek seferlik 3 yıldız güçlendirici ödülü
- `lib/game_engine.dart` : eşleştirme motoru ve bölüm hedefleri
- `lib/game_audio.dart` ve `assets/audio/` : yerel özgün müzik ve sesler
- `test/level_result_test.dart` ve `test/reward_rules_test.dart` : ödül ve sonuç akışı testleri

Oyunun çizimleri ve sesleri özgündür; Candy Crush marka/varlıkları kullanılmaz. iOS kaynak uyumu korunur ama iOS ikonu (`ios: false`) yalnızca Android derlemesi sırasında bilerek kapalıdır. iOS için Mac/Xcode gerekir.
