# Şeker Bahçesi 🍬 — Flutter Match-3 Oyunu (V2 Paket 2)

Android ve iOS için tasarlanan, özgün çizimli Türkçe eşleştirme oyunu. **Candy Crush Saga'nın bir kopyası değildir:** King'e ait isim, grafik veya sesler bu projede kullanılmaz.

## V2 Paket 2: Özel şekerler ve kombo zincirleri

- **4'lü yatay eşleşme** yatay çizgili şeker üretir; dikey eşleşme dikey çizgili şeker üretir.
- **5'li yatay/dikey eşleşme** renk bombası üretir; yanındaki normal şekerle değiştirilince onun rengindeki taşları temizler.
- Çizgili şeker normal eşleşmeyle tetiklenince kendi satır/sütununu temizler.
- **İki çizgili şeker**, **renk bombası + çizgili şeker** ve **iki renk bombası** birleştirilebilir.
- Özel şekerler ekranda ayırt edilebilir çizgili veya gökkuşağı benekli görseller kullanır.
- Zincir patlamalarında mevcut V2 parçacık ve düşüş animasyonları korunur.
- Eski V1/V2 kayıtlarıyla uyumlu: yeni `special` alanı isteğe bağlıdır, önceki kayıt anahtarları değişmez.
- 60 bölüm korunmuştur; hedef, puan, hamle ve güçlendirici mantığı değişmemiştir.
- **Buz, çikolata, kilitli kareler ve yeni ses paketi bu pakete dahil değildir.** Yeni bölüm hedefleriyle birlikte ayrıca geliştirilebilir.

> Kaynak kodu ve 7 yeni mantık testi ve görsel test hazırlanmıştır. Bu çalışma ortamında Flutter SDK bulunmadığı için gerçek `flutter test` ve APK derlemesi burada çalıştırılamadı. GitHub Actions yeniden derleme/test yapacaktır; sonuç garanti değildir.

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
4. Yeşil onay geldikten sonra çalışmaya gir, **Artifacts** altında `seker-bahcesi-v2-test-apk` dosyasını indir.
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
- `test/game_engine_test.dart`, `test/special_candy_test.dart`: tahta, hamle, kayıt ve güç patlatma testleri
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

## Telefonunda V2 Paket 2 güncellemesi

1. ZIP dosyasını telefonun `Download` klasörüne kaydet.
2. Termux'ta mevcut `~/seker-bahcesi` Git deposuna yeni sürüm dosyalarını kopyala ve `main` dalına gönder.
3. GitHub Actions yeni `seker-bahcesi-v2-paket2-test-apk` artifact'i oluşturacak.
4. Uygulama güncellemesi imza uyuşmazlığı verirse eski kurulumu silmeyin; yerel kayıtlar kaybolabilir.

**Not:** Önceki V1/V2 uygulama verileri bu yeni kod tarafından okunabilir, ancak Android'in kuruluma izin vermesi mevcut APK ile yeni APK'nın imzalarının aynı olmasına bağlıdır.
