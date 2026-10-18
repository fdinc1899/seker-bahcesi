# Şeker Bahçesi V2 – Paket 4 | Gerçek müzik ve patlama sesleri

Bu paket bir önceki V2 Paket 3'ün **tam proje güncellemesidir**. İçinde önceki sürümlerin 60 bölüm, özel şeker, engel ve kayıt motoru korunmuştur.

## Sesler artık gerçekten var

- Oyuna girince otomatik başlayıp tekrar eden **özgün neşeli arka plan müziği** (`assets/audio/seker_bahcesi_muzik.wav`).
- Kaydırma/tıklama, üçlü patlama, özel şeker, zincirleme kombo, kazanma ve kaybetme için **7 ayrı WAV ses efekti**.
- Sağ üstteki hoparlör simgesi müzik **ve** efektleri birlikte açar/kapatır; tercihin eskisi gibi `sound` anahtarına kaydedilir.
- Uygulama arka plandayken müzik durur, geri gelince devam eder.
- Bu sesler dış bağlantıdan yüklenmez, çevrimdışı da oynar. Sesler bu paket için üretilmiş, telifsiz özgün sentezlerdir.

## Daha görünür patlamalar

Her eşleşmede ışıklı büyüyen halkalar, beyaz parıltı, dışarı saçılan renkli parçacıklar, kısa flaş ve hafif ekran sarsıntısı gösterilir. Zincirleme kombolar farklı ses çıkarır; mevcut şeker akış animasyonu korunmuştur.

## APK

Github Actions → en yeni yeşil derleme → Artifacts → `seker-bahcesi-v2-paket4-ses-patlama-apk`.

## Güvenlik

Kelime Çemberi'ne dokunmaz. İlerleme kayıt biçimini değiştirmez. Mevcut APK'yı kaldırmadan önce verilerini yedekle; Android farklı imzalı APK'yı güncelleme olarak kabul etmeyebilir.

## Kurulum

Önce `flutter pub get`, sonra `flutter test`, sonra `flutter build apk --debug`. GitHub Actions bu adımları otomatik yapar.

# Şeker Bahçesi 🍬 — Flutter Match-3 Oyunu (V2 Paket 3)

Android ve iOS için tasarlanan, özgün çizimli Türkçe eşleştirme oyunu. **Candy Crush Saga'nın bir kopyası değildir:** King'e ait isim, grafik veya sesler bu projede kullanılmaz.

## V2 Paket 3: Buz, çikolata ve kilitli kareler

- **3. bölümden itibaren buz:** aynı karenin üzerinde yapılan iki eşleşme/patlama ile kırılır (kalın buz → çatlak buz → açık kare).
- **5. bölümden itibaren çikolata:** üzerine sürükleme yapılamaz; komşu eşleşmeler veya doğrudan patlamayla temizlenir. Her başarılı hamle sonunda hiç çikolata kırılmadıysa en fazla 6 kareye kadar yayılabilir.
- **7. bölümden itibaren kilit:** kilitli şeker sürüklenemez; komşu eşleşme veya özel patlamayla kilidi çözülür.
- Her engelin oyun tahtası üzerinde ayrı simgesi, altında **buz / çikolata / kilit sayacı** vardır. Bölüm 1–2 mevcut öğretici akışla aynıdır.
- Mevcut 60 bölüm, özel şekerler, güçlendiriciler, puan hedefi ve yıldız sistemi korunur. Engeller şimdilik mevcut bölüm hedeflerine **ek kazanma şartı değildir**.
- Eski kayıtlarda `obstacles` alanı yoksa boş olarak okunur; yeni kayıtlar katmanları taşır. Önceden başlamış ileri bölüm oturumlarına yeni engel sonradan zorla eklenmez.
- Yedi engel testi eklendi, `flutter_launcher_icons` iOS kapalı kalır. **Bu ortamda Flutter SDK yok; APK ve Flutter testleri GitHub Actions üzerinden doğrulanmalıdır.**

> Bu güncelleme yeni özel ses kayıtlarını, farklı bölüm hedefleri veya çok katmanlı Jelly mekaniklerini henüz içermez. Çikolata ve kilit ilk oynanış prototipidir; zorluk dengesi gerçek cihazda test edilmelidir.

## Hazır özellikler

- 8×8 tahta; **parmakla kaydırma veya yan yana iki şekere dokunma**
- Gerçek yatay/dikey üçlü eşleştirme; dörtlüde çizgili, beşlide renk bombası ve zincir kombolar
- Yanlış eşleşmeyi geri alma; yerçekimi, şeker yenileme, hamle kalmadığında karıştırma
- Kaydırma / patlama / düşme animasyonları, parıltı efektleri
- 60 bölüm, artan hedefler, puan veya şeker toplama görevleri, yıldızlar
- Üç güçlendirici: çekiç, satır patlatıcı, karıştırma
- Her hamle sonunda **yerel oyun kaydı**, kapanınca kaldığın yerden devam
- Türkçe öğretici, başlangıç ekranı, bölüm haritası, ses/haptik aç-kapat
- Özgün vektörel şeker çizimleri ve özel uygulama ikonu
- Google Play reklamı, satın alma, sunucu, hesap veya veri toplama **yok**

> Bu bir **ilk oynanabilir sürüm**dür; Candy Crush Saga ölçüsünde prodüksiyon, binlerce elle tasarlanmış bölüm, özel müzik, hesap senkronizasyonu, monetizasyon veya mağaza yayını dahil değildir. Gerçek cihazdaki derleme/oyun testi yapılmalıdır.

## GitHub'dan APK al (bilgisayar gerektirmez)

1. ZIP'i telefonda aç ve içindeki **dosya ve klasörleri** yeni bir GitHub deposuna yükle. *ZIP dosyasının kendisini yüklemek yeterli değildir.* `.github` gizli klasörünü de dahil et.
2. GitHub deposunu **Public veya Private** oluştur, varsayılan dal `main` olsun.
3. Üst menüden **Actions → Android APK oluştur → Run workflow**'a dokun (ilk yüklemede otomatik de çalışır).
4. Yeşil onay geldikten sonra çalışmaya gir, **Artifacts** altında `seker-bahcesi-v2-paket3-test-apk` dosyasını indir.
5. Artifact ZIP'ini çıkar, içindeki `app-debug.apk`'yi Android telefona kur. Telefon izin isterse yalnızca kendi oluşturduğun APK için kurulum izni ver.

> Bu APK geliştirici test sürümüdür. **Google Play'e doğrudan yüklenmez.** Mağaza için eşsiz paket adı, ikon, tanıtım görselleri, gizlilik bilgileri, uygulama imzası ve imzalı `.aab` gerekir.

## Bilgisayarda çalıştır

Flutter SDK (Dart >=3.4) kurulu bir bilgisayarda:

```bash
flutter create --platforms=android,ios --project-name seker_bahcesi .
flutter pub get
# iOS ikon üretimi için pubspec.yaml içindeki ios: false değerini true yap
dart run flutter_launcher_icons
flutter test
flutter run
```

- macOS / Xcode olmadan **iOS uygulaması derlenemez**; bu kaynak kodu iOS'a uygundur, iOS projesini Mac üzerinde oluşturup imzalaman gerekir.
- `flutter create` tarafından üretilen varsayılan `com.example.seker_bahcesi` paket kimliğini mağaza yayını öncesi değiştir.
- Android için hedefleme/sürüm imzalama ve son kontroller gerekir.

## Kod düzeni

- `lib/game_engine.dart`: saf Dart eşleştirme ve puanlama motoru
- `lib/candy_art.dart`: bağımsız vektör şeker ve arka plan çizimleri
- `lib/main.dart`: animasyonlar, ekranlar, kayıt ve kontroller
- `test/game_engine_test.dart`, `test/special_candy_test.dart`, `test/obstacle_test.dart`: tahta, hamle, kayıt ve güç patlatma testleri
- `.github/workflows/android-apk.yml`: otomatik Android test APK derleme

### Bilinmesi gerekenler

- Ses düğmesi şu an cihazın **sistem tıklama / titreşim geri bildirimini** kontrol eder. Ayrı bestelenmiş arka plan müziği ve profesyonel ses efektleri sonraki üretim aşamasına aittir.
- Güçlendiriciler ilk oyunda 3/2/3 adet verilir; şu sürümde yenilenmez.
- Kayıt yalnızca bu cihazdadır; Google hesabına bulut kaydı yapılmaz.
- Üretim sürümünden önce farklı telefon boyutları, erişilebilirlik, denge ve uygulama güvenliği testleri yapılmalıdır.

## V2 güncelleme ve kayıt güvenliği

V2, V1 ile aynı oyun ilerleme anahtarlarını (`unlocked`, `stars`, `session`, güçler)
kullanır. **Ancak GitHub Actions'ın her çalıştırmada yeniden imzaladığı debug APK'lar**
Android tarafından farklı sertifikalı görülebilir: güncelleme sırasında
`Uygulama yüklenmedi` hatası oluşursa **oyunu silmeyin**; cihazdaki kayıtlar
silinebilir. Önce mevcut kurulumun yedeği/uygun imzalama yolu belirlenmelidir.
İmzalı sürümler için kalıcı bir güvenli imzalama altyapısı gereklidir.

V2 paketinde motor ve `shared_preferences` anahtarları değiştirilmemiştir.
Bu, aynı imzayla güncelleme yapılabildiği durumlarda mevcut kayıtların korunmasını sağlar.

## Telefonunda V2 Paket 3 güncellemesi

1. ZIP dosyasını telefonun `Download` klasörüne kaydet.
2. Termux'ta mevcut `~/seker-bahcesi` Git deposuna yeni sürüm dosyalarını kopyala ve `main` dalına gönder.
3. GitHub Actions yeni `seker-bahcesi-v2-paket2-test-apk` artifact'i oluşturacak.
4. Uygulama güncellemesi imza uyuşmazlığı verirse eski kurulumu silmeyin; yerel kayıtlar kaybolabilir.

**Not:** Önceki V1/V2 uygulama verileri bu yeni kod tarafından okunabilir, ancak Android'in kuruluma izin vermesi mevcut APK ile yeni APK'nın imzalarının aynı olmasına bağlıdır.
