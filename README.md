# Şeker Bahçesi 🍬 – V2 Paket 6: Günlük Hediye ve Görevler

Bu paket **V2 Paket 5'in üzerine kurulu tam Flutter kaynak projesidir**. Önceki 60 bölüm, ses ve müzik, patlama animasyonları, 4-5 şeker özel yetenekleri, buz/çikolata/kilit, bölüm sonuç ekranı ve +1 Karıştır üç yıldız ödülü korunur.

## Yenilikler

- Ana ekranın sol üstünde **hediye simgesi**. Açınca günlük hediye ve üç görev gösterilir.
- **Giriş hediyesi:** yerel takvime göre günde en fazla bir defa. Her gün değişen Çekiç / Satır / Karıştır ödülü; 7 günlük tekrarlanan ödül döngüsü. Arka arkaya günlerde seri yükselir.
- **Günlük görevler:** 5 geçerli eşleşme, 2 özel şeker oluşturma, 1 bölüm kazanma. Her biri tamamlanınca yalnızca bir kere ek güçlendirici alınır.
- Görev ilerlemesi ve ödül alma durumu `dailyProgressV2` anahtarında kaydedilir. Gün değişince görev sayaçları sıfırlanır; önceki `stars`, `unlocked`, `session`, `hammers`, `lineBlasts`, `shuffles` ve `sound` anahtarları aynen korunur.
- Tamamlanmış görevlerde ödülü **ÖDÜLÜ AL** tuşuna basarak alırsın.

## GitHub / test

`main` dalına yükleme GitHub Actions üzerinden `flutter pub get`, `flutter test` ve `flutter build apk --debug` çalıştırır. Başarılı olunca `seker-bahcesi-v2-paket6-gunluk-odul-apk` adlı indirilebilir artifact oluşur. **Bu ortamda Flutter SDK olmadığından testlerin sonuçları GitHub'da doğrulanmalıdır.**

## Önemli

- Bu bir çevrimdışı prototip; ödüller cihazın yerel tarihine göre ilerler. Saat değişikliğiyle oynanması tamamen engellenmiş değildir; sunucuya bağlı güvenli ekonomi sisteminin alternatifi değildir.
- Var olan APK'yı silmeden yeni sürümü güncelleyin; telefonun yerel kayıtlarının korunması için aynı imza ve paket adı gerekir.
- Eski GitHub paketlerini ayrı ayrı yüklemek zorunda değilsiniz: bu ZIP tam projeyi içerir.
