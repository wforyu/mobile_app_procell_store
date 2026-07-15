<div align="center">
  <h1>📱 ProCell Store — Mobile App</h1>
  <p><strong>Aplikasi Mobile Toko Sparepart & Aksesoris HP</strong></p>
  <p>Flutter · Dart · Material 3</p>
</div>

---

## ✨ Fitur

### 🛍️ Storefront Mobile
- **Splash screen** — gradient amber→orange, logo PC, slogan "Solusi Sparepart HP Terpercaya", fade animation
- **Beranda** — banner slider, kategori grid icon vertikal, produk terbaru, quick actions
- **Live Search** — saran real-time saat mengetik (debounce 300ms)
- Detail produk dengan gallery gambar, harga, stok, wishlist toggle, compare, quantity
- **Compare Produk** — bandingkan hingga 4 produk side-by-side
- **Paket Bundling** — paket hemat produk dengan diskon spesial
- **Live Chat** — chat real-time dengan admin (polling 5 detik)
- Keranjang belanja + **badge counter merah** + Checkout lengkap (kurir, pembayaran)
- Wishlist produk favorit (toggle + tab)
- Retur barang + upload foto bukti
- Halaman statis (Tentang Kami, Syarat & Ketentuan, Kebijakan Privasi) — HTML rendered proper

### 👤 Akun & Profil
- Login / Register dengan token-based auth (Sanctum)
- Profil dengan header gradient, avatar, membership tier badge
- Statistik: jumlah pesanan, total belanja, poin
- Menu akun: Riwayat Pesanan, Wishlist, Paket Bundling, Pusat Bantuan
- Edit profil (nama, telepon, alamat)
- Logout

### 📱 Navigasi
- Bottom navigation: Beranda, Pesanan, Wishlist, Profil — **tab switching fresh data** (non-IndexedStack)
- Overflow menu (3 titik) di pojok kanan: akses cepat ke semua fitur
- **Tidak ada global 401 redirect** — lazy auth per-screen, push LoginScreen + await result

---

## 🚀 Cara Menjalankan

```bash
# Clone repositori
git clone https://github.com/wforyu/mobile_app_procell_store.git
cd procell_app

# Install dependencies
flutter pub get

# Jalankan di emulator/device (pastikan backend Laravel nyala)
flutter run
```

## 🔧 Konfigurasi

Edit `lib/config.dart` untuk mengubah base URL API backend:

```dart
static const String baseUrl = 'http://192.168.100.7:8000/api';
```

> **Catatan:** Jika backend di localhost, pake IP komputer (bukan `127.0.0.1`) biar device fisik bisa akses.
> Image URL otomatis di-rewrite oleh `AppConfig.imageUrl()` — `localhost` di path gambar bakal diganti ke host `baseUrl`.

## 🔨 Build APK

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

## 🧪 Analisis Kode

```bash
flutter analyze
# Output: 0 errors, 0 warnings
```

### Akun Demo

| Role | Email | Password |
|------|-------|----------|
| Customer | `customer@procell.com` | `customer123` |
| Admin | `admin@procell.com` | `admin123` |

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                       # Entry point + SplashScreen
├── config.dart                     # AppConfig (baseUrl, imageUrl)
├── models/                         # Data models
│   ├── product.dart                # Product + CategoryInfo
│   ├── category.dart               # Category
│   ├── banner.dart                 # BannerModel
│   ├── order.dart                  # Order
│   ├── user.dart                   # User
│   └── cart.dart                   # CartItem
├── screens/                        # Semua halaman (18 screen)
│   ├── splash_screen.dart          # Branded splash + slogan + transition
│   ├── home_screen.dart            # Beranda + bottom nav (tab switcher)
│   ├── login_screen.dart           # Login
│   ├── register_screen.dart        # Register
│   ├── product_detail_screen.dart  # Detail + compare + wishlist + cart
│   ├── cart_screen.dart            # Keranjang belanja
│   ├── checkout_screen.dart        # Checkout
│   ├── orders_screen.dart          # Daftar pesanan
│   ├── order_detail_screen.dart    # Detail pesanan
│   ├── wishlist_screen.dart        # Wishlist produk
│   ├── profile_screen.dart         # Profil + membership + menu
│   ├── compare_screen.dart         # Perbandingan produk
│   ├── chat_list_screen.dart       # Daftar chat
│   ├── chat_detail_screen.dart     # Detail chat
│   ├── bundles_screen.dart         # Paket bundling
│   ├── bundle_detail_screen.dart   # Detail bundling
│   ├── return_screen.dart          # Pengajuan retur
│   └── page_screen.dart            # Halaman statis (HTML rendered)
├── services/                       # API & Auth services
│   ├── api_service.dart            # HTTP client + semua endpoint
│   └── auth_service.dart           # Auth login/register/profile
├── helpers/                        # Utility
│   ├── theme.dart                  # Tema amber (#F59E0B) + AppColors
│   └── price_formatter.dart        # Format Rupiah
└── widgets/                        # Widget reusable
    ├── product_card.dart           # Card produk (grid)
    ├── shimmer_loading.dart        # Shimmer loading placeholder
    └── animated_carousel.dart      # Banner slider auto-play
```

---

## 🔗 Backend

Backend Laravel 12 + Filament v5: [ProCell Store](https://github.com/wforyu/procell-store)

Screenshots & API docs: lihat README backend.
