# CarPlay Frame-Pump POC

Amaç: IPTV/video görüntüsünü CarPlay'e **resmi olmayan görüntü kanalından**
(now playing artwork) basarak, hareket halinde akıcı görüntü alınıp alınamayacağını
ölçmek. Ses `AVPlayer`'dan doğal akar; görüntü kareleri `AVPlayerItemVideoOutput`
ile yakalanıp artwork olarak güncellenir. Hız tavanı Apple tarafından
dokümante edilmediği için bu POC deneysel ölçüm içindir.

## Araştırma durumu (Kasım 2026)

- Resmi "Video in Car" kanalını Kasım 2026 itibarıyla **hiçbir üretici açmamış**
  (Apple bile uyumlu araç listesi yayınlamıyor). Yani CarScreen/Carvia/APTV
  ailesinin görüntüsü kesin olarak resmi olmayan bir kanaldan gidiyor.
- Apple iOS 27.2 döneminde bu "workaround" ailesini kapatmaya başladı:
  APTV 23 Ekim 2026'da App Store'dan çekildi; döndüğünde tarayıcı/CarPlay video
  özelliği çıkartılmıştı. CarScreen de aynı ailedendir → ömrü belirsiz.
- Bu POC **kişisel kullanım** için yazılıyor: App Store'da olmadığı için
  Apple'ın temizlik kampanyasının hedefi değil; yalnızca iOS tarafındaki
  framework değişiklikleri kırabilir.

## Dosyalar

| Dosya/Yol | Görev |
|---|---|
| `Sources/AppDelegate.swift` | Giriş noktası, audio session kurulumu |
| `Sources/PhoneSceneDelegate.swift` | Telefon arayüzü (SwiftUI hosting) |
| `Sources/CarPlaySceneDelegate.swift` | CarPlay bağlantısı, kanal listesi |
| `Sources/PlayerEngine.swift` | AVPlayer + frame pump + artwork push + fps ölçüm |
| `Sources/ContentView.swift` | Kontrol paneli (URL, parametreler, fps) |
| `Info.plist` | Scene manifest + arka plan audio + ATS |
| `project.yml` | XcodeGen: Mac olmadan .xcodeproj üretimi |
| `codemagic.yaml` | Codemagic: bulut derleme + TestFlight yayını |

## Mac'siz derleme hattı (plan)

Senin makinen Windows; iOS derlemesi Apple donanımı ister. Zincir:

1. **GitHub repo** aç, bu klasörün içeriğini yükle (Sources/, Info.plist,
   project.yml, codemagic.yaml).
2. **Apple Developer Program** ($99/yıl) — TestFlight ve CarPlay entitlement
   başvurusu buna bağlı.
3. **Codemagic** (ücretsiz 500 dk/ay): GitHub reposunu bağla →
   App Store Connect API anahtarını ekle → build başlat.
   Build şöyle çalışır: XcodeGen .xcodeproj üretir → imzalı IPA →
   App Store Connect'e yüklenir.
4. **TestFlight (internal)**: iPhone'daki TestFlight uygulamasından kur
   (internal test için App Review yoktur; build'ler 90 gün geçerlidir,
   yeniden build etmen gerekir).
5. **Aşama A ölçümü** (CarPlay'siz, hemen): uygulamayı aç, test HLS'ini
   oynat, ekranı kilitle → artwork alanında video akıyor mu?
   `Gönderilen fps` sayacı + gözlem akıcılığı kaydet.
6. **CarPlay entitlement**: `com.apple.developer.carplay-audio` için
   Apple'ın "CarPlay Contact Us" formuna başvur → onay gelince
   CarPlay scene'i gerçek arabada bağlanır → Aşama B (araçta Now Playing
   ekranı + hareket halinde gözlem).

### Neden Aşama A'yı beklemek?

Artwork kanalının fps tavanı hiçbir yerde dokümante değil; tek yol ölçüm.
Gönderilen fps yüksek ama kilit ekranı donuk = iOS tarafında throttle var
(o zaman liste-görsel/grid kanalını deneriz).

## Parametre taraması (her ayarda ~20 sn)

| Pump | Genişlik | Gönderilen fps | Kilit ekranı gözlemi |
|---|---|---|---|
| 16 ms (~60 Hz) | 1280 | | |
| 33 ms (~30 Hz) | 800 | | |
| 50 ms (~20 Hz) | 800 | | |
| 66 ms (~15 Hz) | 480 | | |

## Notlar

- `codemagic.yaml` henüz uzaktan test edilemedi (Mac'im yok); ilk build'de
  hata verirse log'un tamamını getir, düzeltilir.
- CarPlay Simulator gerçek iPhone + USB ister; bulut Mac'te yapılamaz.
  O yüzden Aşama B gerçek araçta yapılacak (entitlement sonrası).
- Bundle ID (`com.framepoc.app`) kendi değerine değiştirilebilir;
  `project.yml` ve `codemagic.yaml` içinde senkron tut.
