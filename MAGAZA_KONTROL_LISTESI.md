# Yayın Öncesi Mağaza Kontrol Listesi

Koddan bağımsız, konsollarda yapılması gereken adımlar. Teknik kurulum (kurallar, Functions,
gizli anahtarlar, App Check, Apple/Google girişi) için `README.md` > "Yayın öncesi kurulum".

## RevenueCat
- [ ] `yanyana_monthly` ve `yanyana_yearly` ürünleri `premium` entitlement'ına bağlı
- [ ] `default` offering'de **monthly** ve **annual** paketleri var (isteğe bağlı: **lifetime**)
- [ ] Webhook: `rcWebhook` adresi + Authorization değeri (`REVENUECAT_WEBHOOK_AUTH`) girildi, "Send test event" 200 dönüyor
- [ ] App Store Connect App-Specific Shared Secret / In-App Purchase Key ve Play servis hesabı RevenueCat'e bağlı

## App Store Connect
- [ ] Ürünler **aynı abonelik grubunda**; 7 günlük ücretsiz deneme "Introductory Offer" olarak tanımlı
- [ ] Paid Apps sözleşmesi, banka ve vergi bilgileri tamam (eksikse ürünler uygulamada hiç yüklenmez)
- [ ] Uygulama açıklamasına Kullanım Şartları/EULA ve Gizlilik bağlantıları eklendi:
  - https://sudekazan.github.io/ciftapp/terms.html
  - https://sudekazan.github.io/ciftapp/privacy.html
- [ ] Destek URL'si (https://sudekazan.github.io/ciftapp/support.html) ve `destek@yanyana.app` gerçekten çalışıyor
- [ ] Yaş derecelendirme anketi 17+ ile tutarlı dolduruldu
- [ ] App Privacy etiketleri (aşağıdaki tabloyla ve `ios/Runner/PrivacyInfo.xcprivacy` ile aynı)
- [ ] İnceleme notu: iki test cihazı/hesabıyla eşleşme nasıl denenir (inceleme ekibi tek cihazla deniyor; davet kodu
      girilecek ikinci bir hesap/alan hazırlayın) ve sandbox ile Premium nasıl açılır
- [ ] Capabilities: Push Notifications, Sign in with Apple, App Attest açık

## Google Play Console
- [ ] Abonelik ürünleri ve temel planlar aktif; ücretsiz deneme teklifi tanımlı
- [ ] Ödeme profili tamam
- [ ] **Veri güvenliği formu** aşağıdaki tabloya göre dolduruldu (veriler aktarımda şifreli: Evet; silme talebi: Evet, uygulama içinden)
- [ ] Hesap silme URL'si istenirse: uygulama içi Profil > Hesabı ve Verileri Sil (destek sayfasında da anlatılmalı)
- [ ] İçerik derecelendirmesi anketi dolduruldu
- [ ] Release imza anahtarının SHA-1/SHA-256 değerleri Firebase'e eklendi (Google girişi ve App Check için)

## Beyan tablosu (App Privacy / Data safety)

| Veri | Toplanıyor | Kullanıcıyla ilişkili | Amaç | Paylaşım (3. taraf) |
|---|---|---|---|---|
| Ad / takma ad | Evet | Evet | Uygulama işlevi | Hayır (yalnızca partner) |
| Fotoğraflar | Evet | Evet | Uygulama işlevi | Hayır |
| Diğer kullanıcı içeriği (anı, not, plan, cevap) | Evet | Evet | Uygulama işlevi | Hayır |
| Kullanıcı kimliği (Firebase uid) | Evet | Evet | Uygulama işlevi, analitik | Hayır |
| Cihaz kimliği (FCM token) | Evet | Evet | Uygulama işlevi (bildirim) | Hayır |
| Satın alma geçmişi | Evet | Evet | Uygulama işlevi | Hayır |
| Ürün etkileşimi (analitik olaylar) | Evet | Evet | Analitik | Hayır |
| Çökme verisi | Evet | Hayır | Uygulama işlevi | Hayır |
| Konum, kişiler, sağlık, finans | Hayır | – | – | – |

Takip (tracking / reklam kimliği): **Hayır**. Hizmet sağlayıcılar (Google Firebase, RevenueCat) "işleyen" sayılır,
"paylaşım" kapsamına girmez.

## Son uçtan uca test (TestFlight / kapalı test, iki cihaz)
- [ ] Cihaz A eşleşmeden önce: kurulumdan sonra paywall açılmaz; kalp, saat, günün sorusu ve testler davet gösterir, sinyal hakkı düşmez
- [ ] Cihaz A alan oluşturur, cihaz B davet bağlantısı/koduyla eşleşir; iki cihazda da paywall bir kez "Bağlandınız!" mesajıyla açılır
- [ ] Anı (fotoğraflı), görev, not, kapsül, günün sorusu iki tarafta da görünür
- [ ] "Seni düşünüyorum" ve günün sorusu bildirimleri karşı cihaza gelir (uygulama kapalıyken de)
- [ ] A satın alır → B de Premium olur (webhook); eşleşme sonlanınca B'nin Premium'u kapanır
- [ ] Ücretsiz sınırlar (20 anı, 3 foto, 5 sinyal, 1 kapsül) paywall açar
- [ ] Hesap silme: partnerli ve partnersiz senaryolar
- [ ] Apple/Google ile hesap bağlama → uygulamayı silip yeniden kurma → "Zaten hesabım var" ile geri yükleme
- [ ] TR ve EN dilinde ekranlar, karanlık mod, küçük ekranda taşma kontrolü
