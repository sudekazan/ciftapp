# ÇiftApp (Couple App) 💕

Modern, zarif ve çiftler için özel olarak tasarlanmış mobil ilişki asistanı uygulaması (Flutter).

Hem **Uzak Mesafe İlişkisi (Long Distance)** yaşayan hem de **Birlikte Yaşayan (Co-Living)** çiftlerin günlük iletişimini, anılarını, planlarını ve sevgilerini canlı tutmak için geliştirilmiştir.

---

## ✨ Özellikler

### 1. 👫 Çift Modları (Tek Tıkla Geçiş)
- **Uzak Mesafe Modu (Long Distance):**
  - İki şehir/ülke arası çift saat göstergesi (Dual Time Zone).
  - Bir sonraki buluşma geri sayım sayacı ("Büyük Buluşma ✈️").
  - "Seni Düşünüyorum" anlık titreşim/dokunma pulsası.
- **Birlikte Yaşıyoruz Modu (Co-Living):**
  - Ortak ev işleri ve görev paylaşımı (Temizlik, yemek, faturalar).
  - Ortak market ve alışveriş listesi (Anlık işaretlenebilir).
  - Ev bütçesi ve günün planı.

### 2. 🚀 3 Adımlı Sadeleştirilmiş Kurulum (Onboarding)
- **1. Adım:** Kullanıcının adı veya takma adı ("Seni nasıl çağıralım?").
- **2. Adım:** Birlikte olmaya başlama tarihi ("Ne zamandır birliktesiniz? 💍") ve canlı gün sayacı.
- **3. Adım:** Çift alanı kurulumu ("Partnerimin kodu var 🔑" veya "Yeni alan başlat ✨").

### 3. 📸 Genişletilmiş Anı Defteri (Memory Book)
- Anılara **birden fazla fotoğraf** ekleme desteği.
- Fotoğraflara tıklandığında açılan tam ekran kaydırılabilir galeri (`MemoryDetailScreen`), küçük resim önizleme çubuğu ve fotoğraf sayacı.
- Duygu durumu (Mood) rozetleri, konum etiketleri ve romantik notlar.

### 4. 🎮 Birlikte Vakit Geçirme & Oyunlar
- **Günün Sorusu (Daily Question):** Her iki taraf da cevap verene kadar yanıtlar kilitli kalır.
- **Hangimiz Daha...? (Who's More Likely To...?):** Çiftler birbirlerini oylar, uyum yüzdesi anlık hesaplanır.
- **Beni Ne Kadar Tanıyorsun?** Çift bilgi yarışması.
- **Ortak İzleme Listesi:** Beraber izlenecek film ve diziler.

### 5. 💬 Çift Sohbeti & Sürprizler
- Zengin mesajlaşma (Metin, ses dalgası, fotoğraflar).
- **Zaman Kilitli Sürpriz Mesajlar:** Belirlenen tarihe kadar açılamayan gizemli aşk mektupları.

### 6. 💎 ÇiftApp Premium & Paywall
- Apple App Store & Google Play uyumlu 7 günlük ücretsiz denemeli abonelik ekranı.
- Çiftler için sınırsız anı saklama, sesli notlar ve özel temalar.

---

## 🛠️ Teknoloji Yığını

- **Framework:** Flutter 3.x (Dart)
- **State Management:** Provider (`MultiProvider`, `ChangeNotifier`)
- **Tasarım & UI:** Özel Rose/Coral tema paleti (`#E25B6C`), Google Fonts (Poppins, Plus Jakarta Sans)
- **Lokalizasyon:** Türkçe (TR) ve İngilizce (EN) tam dil desteği
- **Yerel Depolama:** `shared_preferences`
- **Çoklu Ortam & Paylaşım:** `image_picker`, `share_plus`
- **Mimari:** Feature-first, temiz katmanlı mimari (Core / Features / Services)

---

## 🚀 Başlarken

### Gereksinimler
- Flutter SDK 3.24+
- iOS Simulator (macOS / Xcode) veya Android Emulator

### Kurulum Adımları
```bash
# Depoyu klonlayın
git clone https://github.com/sudekazan/ciftapp.git
cd ciftapp

# Bağımlılıkları yükleyin
flutter pub get

# iOS Pods kurulumu (macOS için)
cd ios && pod install && cd ..

# Uygulamayı başlatın
flutter run
```

### Testleri Çalıştırma
```bash
flutter test
flutter analyze
```

---

## 📄 Lisans
Bu proje özel mülkiyet altındadır. Tüm hakları saklıdır.
