# Yanyana (ciftapp) 💕

Uzak mesafede ya da aynı evde yaşayan çiftler için ortak alan uygulaması (Flutter).
İki partner bir davet koduyla eşleşir; anılar, planlar, hayaller, notlar ve
cevaplar Firebase üzerinden gerçek zamanlı paylaşılır.

## Özellikler

- **Eşleşme:** `CFT-XXXXXX` davet kodu, paylaşılabilir davet bağlantısı (`docs/davet.html`)
- **Uzak mesafe modu:** çift saat (IANA saat dilimi, partnerden otomatik), buluşma geri sayımı,
  "Seni düşünüyorum" sinyali (partnere push bildirimi)
- **Birlikte yaşıyoruz modu:** ortak takvim, görevler ve alışveriş listesi
- **Anı defteri:** çoklu fotoğraf, ruh hali, konum, etiket, favoriler; sayaçlar
- **Hayaller ve aşk kapsülü:** hayal listesi, tarihe kadar kilitli zaman kapsülü notları
- **Birlikte:** günün sorusu (iki taraf cevaplayınca açılır), "Beni ne kadar tanıyorsun?",
  "Hangimiz daha...?" paketleri, ortak izleme listesi
- **Premium (RevenueCat):** aylık/yıllık abonelik, "1 üyelik = 2 kişi"
- **TR / EN** dil desteği, karanlık mod

### Ücretsiz / Premium

Sınırlar `lib/core/premium/limits.dart` içinde tek yerden yönetilir ve aynı anahtar
adlarıyla Firebase Remote Config'ten değiştirilebilir.

| Özellik | Ücretsiz | Premium |
|---|---|---|
| Anılar | 20 anı, anı başına 3 foto | Sınırsız, anı başına 20 foto |
| Seni düşünüyorum | Günde 5 | Sınırsız |
| Zaman kapsülü | Ayda 1 | Sınırsız |
| Soru paketleri | Başlangıç paketleri | Tüm paketler |
| Günün sorusu arşivi | Son 7 gün | Son 1 yıl |

## Mimari

- `lib/core/services/couple_sync_service.dart` — eşleşme, çift belgesi, davet kodları
- `lib/core/services/couple_data_store.dart` + `synced_list.dart` — `couples/{id}/{koleksiyon}`
  senkronu, yerel önbellek (çevrimdışı açılış)
- `lib/core/providers/` — Provider tabanlı durum; içerik provider'ları aktif çift alanına
  `ChangeNotifierProxyProvider` ile bağlanır
- `lib/core/services/purchase_service.dart` — RevenueCat (`PurchaseGateway` arayüzü)
- `functions/` — Cloud Functions: RevenueCat webhook (çift premium'u), push bildirimleri,
  zaman kapsülü bildirimi, silinen kullanıcı temizliği
- `firestore.rules`, `storage.rules` — yalnızca çift üyeleri erişebilir

### Firestore yapısı

```
invites/{davetKodu}        { coupleId, ownerId, ownerName }
couples/{coupleId}         { memberIds[1..2], user1/2 Id+Name, tokens{uid}, langs{uid}, tz{uid},
                             mode, startDate, reunionDate, premiumUntil (yalnızca sunucu) }
couples/{coupleId}/memories|countdowns|events|tasks|shopping|bucket|notes|watchlist/{id}
couples/{coupleId}/answers|quiz|whoMore/{soruId}   { <uid>: cevap }
users/{uid}                { premiumUntil }   (yalnızca sunucu yazar)
```

## Geliştirme

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run

flutter analyze
flutter test                      # birim + widget testleri
cd functions && npm test          # Cloud Functions yardımcı testleri
cd security-tests && npm install && npm test   # güvenlik kuralları (emülatör, JDK 21+)
```

## Yayın öncesi kurulum (bir kez)

1. **Firebase kuralları ve index'ler:** `firebase deploy --only firestore,storage`
2. **Cloud Functions** (Blaze planı gerekir):
   ```bash
   firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH   # webhook için rastgele bir değer
   firebase functions:secrets:set REVENUECAT_SECRET_KEY     # RevenueCat > API keys > sk_...
   firebase deploy --only functions
   ```
3. **RevenueCat:** Integrations > Webhooks → URL: `rcWebhook` fonksiyonunun adresi,
   Authorization: `REVENUECAT_WEBHOOK_AUTH` değeri. Ürünler `premium` entitlement'ına bağlı,
   `default` offering'de monthly/annual paketleri olmalı.
4. **iOS push:** Apple Developer'da APNs Authentication Key oluşturup Firebase Console >
   Project settings > Cloud Messaging'e yükleyin. (Push yetkisi `ios/Runner/Runner.entitlements`.)
5. **App Check** (önerilir): Firebase Console'dan Firestore/Storage için App Check'i açın.
6. **Hesap yedekleme (Apple / Google ile giriş):**
   - Firebase Console > Authentication > Sign-in method: **Apple** ve **Google** sağlayıcılarını açın.
   - Apple Developer'da App ID için *Sign in with Apple* yetkisini açın (yetki `Runner.entitlements` içinde).
   - Android için debug/release SHA-1 ve SHA-256 parmak izlerini Firebase'e ekleyin.
   - `flutterfire configure` ile `firebase_options.dart`, `google-services.json` ve
     `GoogleService-Info.plist` dosyalarını yeniden üretin; iOS'ta `REVERSED_CLIENT_ID` değerini
     Info.plist'e URL scheme olarak ekleyin. İstemci kimlikleri yoksa Google butonu gizli kalır.
7. **Davet sayfası:** App Store'da yayınlandıktan sonra `docs/davet.html` içindeki
   `APP_STORE_ID` değerini girin.

## Lisans

Bu proje özel mülkiyet altındadır. Tüm hakları saklıdır.
