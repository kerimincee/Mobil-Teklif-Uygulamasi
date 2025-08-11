# 📱 Mikro Sipariş Takip Sistemi

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8+-blue.svg?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

**Modern ve kullanıcı dostu sipariş yönetim uygulaması**

[🚀 Özellikler](#-özellikler) • [📱 Ekran Görüntüleri](#-ekran-görüntüleri) • [🛠️ Kurulum](#️-kurulum) • [📖 Kullanım](#-kullanım) • [🏗️ Mimari](#️-mimari) • [🤝 Katkıda Bulunma](#-katkıda-bulunma)

</div>

---

## 🎯 Proje Hakkında

Mikro Sipariş Takip Sistemi, küçük ve orta ölçekli işletmeler için geliştirilmiş kapsamlı bir sipariş yönetim uygulamasıdır. Flutter framework'ü kullanılarak geliştirilen bu uygulama, stok yönetimi, müşteri takibi, sipariş oluşturma ve PDF teklif yönetimi gibi temel iş süreçlerini tek bir platformda birleştirir.

### 🌟 Temel Özellikler

- **📦 Stok Yönetimi**: Ürün ekleme, düzenleme ve takip
- **👥 Müşteri Yönetimi**: Cari hesap oluşturma ve yönetimi
- **🛒 Sipariş Sistemi**: Hızlı ve kolay sipariş oluşturma
- **📄 PDF Teklif Yönetimi**: Teklif oluşturma ve yönetimi
- **📱 Barkod Tarama**: QR kod ve barkod okuma
- **🔍 Arama ve Filtreleme**: Gelişmiş arama özellikleri
- **📊 Raporlama**: Detaylı raporlar ve analizler

---

## 🚀 Özellikler

### 📦 Stok Yönetimi
- ✅ Ürün ekleme ve düzenleme
- ✅ Stok kodu ve barkod desteği
- ✅ Fiyat ve kategori yönetimi
- ✅ Stok durumu takibi
- ✅ Görsel ürün yönetimi

### 👥 Müşteri Yönetimi
- ✅ Cari hesap oluşturma
- ✅ Müşteri bilgileri yönetimi
- ✅ İletişim bilgileri takibi
- ✅ Müşteri geçmişi görüntüleme

### 🛒 Sipariş Sistemi
- ✅ Hızlı sipariş oluşturma
- ✅ Ürün arama ve ekleme
- ✅ Miktar ve fiyat hesaplama
- ✅ Sipariş durumu takibi
- ✅ PDF teklif oluşturma

### 📄 PDF Yönetimi
- ✅ Teklif PDF'leri oluşturma
- ✅ PDF görüntüleme ve yönetimi
- ✅ Teklif kilitleme/açma
- ✅ PDF silme ve arşivleme
- ✅ Tarih bazlı sıralama

### 📱 Barkod Tarama
- ✅ QR kod okuma
- ✅ Barkod tarama
- ✅ Hızlı ürün bulma
- ✅ Kamera entegrasyonu

---

## 📱 Ekran Görüntüleri

<div align="center">

| Ana Sayfa | Stok Yönetimi | Sipariş Oluşturma |
|-----------|---------------|-------------------|
| ![Ana Sayfa](assets/screenshots/home.png) | ![Stok](assets/screenshots/stocks.png) | ![Sipariş](assets/screenshots/orders.png) |

| PDF Yönetimi | Barkod Tarama | Müşteri Yönetimi |
|--------------|---------------|------------------|
| ![PDF](assets/screenshots/pdf.png) | ![Barkod](assets/screenshots/barcode.png) | ![Müşteri](assets/screenshots/customers.png) |

</div>

---

## 🛠️ Kurulum

### Gereksinimler

- Flutter SDK 3.8.0 veya üzeri
- Dart SDK 3.8.0 veya üzeri
- Android Studio / VS Code
- Git

### Adım Adım Kurulum

1. **Projeyi klonlayın**
   ```bash
   git clone https://github.com/kullaniciadi/siparis_sistemi.git
   cd siparis_sistemi
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

### 🔧 Yapılandırma

1. **API URL'sini ayarlayın**
   ```dart
   // lib/pdf_list_page.dart dosyasında
   final String baseUrl = 'http://your-api-url:5000';
   ```

2. **Gerekli izinleri ekleyin**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   ```

---

## 📖 Kullanım

### 🏠 Ana Sayfa
Ana sayfa, uygulamanın tüm modüllerine hızlı erişim sağlar:
- **Stok Yönetimi**: Ürün ekleme ve yönetimi
- **Müşteri Yönetimi**: Cari hesap işlemleri
- **Sipariş Oluşturma**: Yeni sipariş oluşturma
- **PDF Yönetimi**: Teklif PDF'leri

### 📦 Stok Yönetimi
1. "Stok Yönetimi" butonuna tıklayın
2. Yeni ürün eklemek için "+" butonunu kullanın
3. Ürün bilgilerini doldurun (kod, ad, fiyat, kategori)
4. Ürün görseli ekleyebilirsiniz
5. Kaydet butonuna tıklayın

### 🛒 Sipariş Oluşturma
1. "Sipariş Oluştur" butonuna tıklayın
2. Müşteri seçin veya yeni müşteri ekleyin
3. Ürün arama ile ürünleri ekleyin
4. Miktarları belirleyin
5. PDF teklif oluşturun

### 📄 PDF Yönetimi
1. "PDF Yönetimi" bölümüne gidin
2. Açık/Kapalı teklifleri filtreleyin
3. Teklifleri görüntüleyin veya düzenleyin
4. Kilitleme/açma işlemleri yapın

---

## 🏗️ Mimari

### 📁 Proje Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── home_page.dart           # Ana sayfa
├── login_page.dart          # Giriş sayfası
├── stoklar_page.dart        # Stok listesi
├── stok_ekle_page.dart      # Stok ekleme
├── stok_detay_page.dart     # Stok detayları
├── cariler_page.dart        # Müşteri listesi
├── cari_ekle_page.dart      # Müşteri ekleme
├── siparisler_page.dart     # Sipariş listesi
├── siparis_sayfasi.dart     # Sipariş oluşturma
├── pdf_list_page.dart       # PDF yönetimi
└── barkod_okuyucu_page.dart # Barkod tarama
```

### 🔧 Kullanılan Teknolojiler

| Teknoloji | Amaç | Versiyon |
|-----------|------|----------|
| **Flutter** | UI Framework | 3.8+ |
| **Dart** | Programlama Dili | 3.8+ |
| **HTTP** | API İletişimi | ^1.4.0 |
| **Dio** | HTTP Client | ^5.2.1 |
| **PDF** | PDF İşlemleri | ^3.8.1 |
| **Printing** | PDF Yazdırma | ^5.12.0 |
| **Mobile Scanner** | Barkod Tarama | ^7.0.1 |
| **Path Provider** | Dosya Yönetimi | ^2.0.15 |
| **Intl** | Lokalizasyon | ^0.18.0 |

### 🎨 UI/UX Özellikleri

- **Material Design 3** uyumlu arayüz
- **Responsive** tasarım
- **Animasyonlu** geçişler
- **Gradient** renkler
- **Shadow** efektleri
- **Rounded corners** tasarım

---

## 🔧 API Entegrasyonu

Uygulama, RESTful API ile backend sistemine bağlanır:

### 📡 Endpoint'ler

```dart
// Stok işlemleri
GET    /stoklar/list
POST   /stoklar/ekle
PUT    /stoklar/guncelle
DELETE /stoklar/sil

// Müşteri işlemleri
GET    /cariler/list
POST   /cariler/ekle
PUT    /cariler/guncelle

// Sipariş işlemleri
GET    /siparisler/list
POST   /siparisler/ekle
PUT    /siparisler/guncelle

// PDF işlemleri
GET    /pdf/list
POST   /pdf/olustur
POST   /pdf/lock
POST   /pdf/unlock
DELETE /pdf/delete
```

---

## 🚀 Performans

- **Hızlı yükleme** süreleri
- **Optimize edilmiş** bellek kullanımı
- **Efficient** API çağrıları
- **Cached** görsel yükleme
- **Lazy loading** desteği

---

## 🛡️ Güvenlik

- **HTTPS** API iletişimi
- **Input validation** kontrolleri
- **Error handling** mekanizmaları
- **Secure storage** kullanımı
- **Permission** yönetimi

---

## 📱 Platform Desteği

| Platform | Destek | Minimum Versiyon |
|----------|--------|------------------|
| **Android** | ✅ | API 21+ |
| **iOS** | ✅ | iOS 11+ |
| **Web** | ✅ | Modern Browser |
| **Windows** | ✅ | Windows 10+ |
| **macOS** | ✅ | macOS 10.14+ |
| **Linux** | ✅ | Ubuntu 18.04+ |

---

## 🤝 Katkıda Bulunma

Projeye katkıda bulunmak için:

1. **Fork** yapın
2. **Feature branch** oluşturun (`git checkout -b feature/AmazingFeature`)
3. **Commit** yapın (`git commit -m 'Add some AmazingFeature'`)
4. **Push** yapın (`git push origin feature/AmazingFeature`)
5. **Pull Request** oluşturun

### 📋 Katkı Kuralları

- Kod standartlarına uyun
- Test yazın
- Dokümantasyon güncelleyin
- Commit mesajlarını açıklayıcı yazın

---

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

---

## 📞 İletişim

- **Geliştirici**: [Adınız]
- **Email**: [email@example.com]
- **LinkedIn**: [LinkedIn Profiliniz]
- **GitHub**: [GitHub Profiliniz]

---

## 🙏 Teşekkürler

- [Flutter](https://flutter.dev/) ekibine
- [Dart](https://dart.dev/) ekibine
- Tüm açık kaynak katkıda bulunanlara
- Test eden ve geri bildirim veren kullanıcılara

---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!**

Made with ❤️ by [Adınız]

</div>
