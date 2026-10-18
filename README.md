# Şeker Bahçesi 🍬 – V2 Paket 7: Kesintisiz Müzik

Bu paket **V2 Paket 6'nın üzerine kurulu tam Flutter kaynak projesidir**. Mevcut 60 bölüm, özel şekerler, buz/çikolata/kilit, günlük giriş ödülü ve görevler, kutlama animasyonları ve yerel kayıtlar korunur.

## Düzeltilen sorun

Önceki sürümde her ses oynatıcısı `audioplayers` varsayılanı olan **AndroidAudioFocus.gain** ile çalışıyordu. Patlama, dokunma ya da kombo sesi başladığında ikinci oynatıcı müzikten odak alarak arka plan müziğini durdurabiliyordu.

- Arka plan müziği tek ve bağımsız döngüsel oynatıcıda (`musicContext`, `AndroidAudioFocus.gain`) çalar.
- **Kısa efektler** (`effectContext`, `AndroidAudioFocus.none`) oyun müziğinin odağını istemez; `sonification` türü ve düşük gecikmeli oynatma kullanır.
- Beş efekt oynatıcısı farklı seslerin üst üste gelmesini sağlar. Her oynatıcı kendi ses komutlarını sıraya alır; hızlı eşleşmelerde yerel ses çakışması önlenir.
- iOS için hem efekt hem müzik aynı `mixWithOthers` ses oturumunu kullanır.
- Bir cihazda efekt odak yapılandırması başarısız olursa efekt devreye girmez; **müziği kesen varsayılan odak ayarına geri dönmez**.
- Ekran açıkken müzik sürer. Kullanıcı sesi kapattığında veya uygulama arka plana geçtiğinde müzik duraklar; uygulama tekrar öne alınınca kaldığı yerden devam eder.

## Kayıt uyumluluğu

`shared_preferences` anahtarları (`unlocked`, `stars`, `session`, `hammers`, `lineBlasts`, `shuffles`, `sound`, `dailyProgressV2`) ve oyun motorunun kayıt formatı **değiştirilmedi**. Eski APK'yı silmeyin; aynı uygulama kimliği ve APK imzasıyla mevcut uygulamanın üzerine yükleyin.

## Doğrulama

GitHub Actions sırasıyla `flutter pub get`, `flutter test`, `flutter build apk --debug` çalıştırır. Yeni test `test/audio_focus_test.dart` ile ses odağı yapılandırmasını kontrol eder. Bu ortamda Flutter SDK bulunmadığı için gerçek APK derleme ve Android'de ses karışımı **henüz doğrulanmadı**.

**Telefonda test:** Oyun sesi açıkken bir bölüme girin, ardışık 15-20 eşleşme yapın; normal patlama, çizgili şeker ve kombo sırasında arka plan müziği devam etmeli. Hoparlör simgesinden sesi kapatıp tekrar açın; oyuna geri dönün ve müziğin sürdüğünü dinleyin. Sistem çağrısı veya bildirimler Android'in kuralları gereği ayrıca sesi duraklatabilir.

## Not

GitHub'ın `Actions` sekmesindeki başarılı iş akışından `seker-bahcesi-v2-paket7-ses-kesilmesi-duzeltme-apk` artifact dosyasını indirin. ZIP'i açınca `app-debug.apk` bulunur. İlk yayın değildir; imzalı sürüm gerektiren Play Store dağıtımından ayrıdır.
