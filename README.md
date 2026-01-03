# Masjid Al-Anwar - Sistem Manajemen Keuangan

Aplikasi Flutter untuk manajemen keuangan Masjid Al-Anwar yang memungkinkan pencatatan uang masuk dan keluar dengan fitur laporan yang lengkap.

## Fitur Utama

### 🏠 Dashboard
- Tampilan saldo total masjid
- Ringkasan uang masuk dan keluar
- Transaksi terbaru
- Navigasi cepat ke fitur utama

### 💰 Manajemen Transaksi
- **Uang Masuk**: Pencatatan donasi, infaq, sedekah, zakat, wakaf, dll.
- **Uang Keluar**: Pencatatan pengeluaran operasional, pemeliharaan, kegiatan, dll.
- Kategori transaksi yang dapat disesuaikan
- Format mata uang Rupiah dengan pemisah ribuan
- Catatan tambahan untuk setiap transaksi

### 📊 Laporan Keuangan
- **Ringkasan**: Total pemasukan, pengeluaran, dan saldo
- **Per Kategori**: Analisis berdasarkan kategori transaksi
- **Bulanan**: Laporan harian dalam satu bulan
- Filter berdasarkan bulan

### 📱 Riwayat Transaksi
- Daftar semua transaksi dengan filter
- Tampilan berdasarkan tanggal
- Opsi hapus transaksi
- Pencarian dan filter berdasarkan jenis transaksi

## Kategori Transaksi

### Uang Masuk
- Infaq
- Sedekah
- Zakat
- Wakaf
- Donasi Umum
- Kotak Amal
- Kegiatan Masjid
- Lainnya

### Uang Keluar
- Listrik
- Air
- Pemeliharaan
- Renovasi
- Kegiatan
- Operasional
- Gaji/Upah
- Bahan Makanan
- Transportasi
- Lainnya

## Teknologi yang Digunakan

- **Flutter**: Framework UI untuk aplikasi mobile
- **SharedPreferences**: Penyimpanan data lokal
- **Intl**: Formatting mata uang dan tanggal
- **UUID**: Generate ID unik untuk transaksi

## Instalasi dan Menjalankan

1. Pastikan Flutter sudah terinstall di sistem Anda
2. Clone repository ini
3. Masuk ke direktori project:
   ```bash
   cd masjid_alanwar
   ```
4. Install dependencies:
   ```bash
   flutter pub get
   ```
5. Jalankan aplikasi:
   ```bash
   flutter run
   ```

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/
│   └── transaction.dart     # Model data transaksi
├── services/
│   └── storage_service.dart # Service untuk penyimpanan data
└── screens/
    ├── home_screen.dart     # Dashboard utama
    ├── add_income_screen.dart    # Form uang masuk
    ├── add_expense_screen.dart   # Form uang keluar
    ├── reports_screen.dart       # Laporan keuangan
    └── transactions_screen.dart  # Riwayat transaksi
```

## Cara Penggunaan

1. **Menambah Transaksi Uang Masuk**:
   - Tap tombol "Tambah Uang Masuk" di dashboard
   - Isi jumlah uang, deskripsi, kategori, dan tanggal
   - Tambahkan catatan jika diperlukan
   - Tap "Simpan Transaksi"

2. **Menambah Transaksi Uang Keluar**:
   - Tap tombol "Tambah Uang Keluar" di dashboard
   - Isi detail transaksi seperti uang masuk
   - Simpan transaksi

3. **Melihat Laporan**:
   - Tap "Laporan Keuangan" di dashboard
   - Pilih tab yang diinginkan (Ringkasan, Kategori, Bulanan)
   - Gunakan kalender untuk memilih bulan tertentu

4. **Melihat Riwayat**:
   - Tap "Riwayat Transaksi" di dashboard
   - Gunakan filter untuk melihat transaksi tertentu
   - Tap menu pada transaksi untuk menghapus

## Tampilan Aplikasi

Aplikasi menggunakan tema hijau Islami dengan desain yang clean dan mudah digunakan. Semua teks menggunakan bahasa Indonesia dan format mata uang Rupiah.

## Lisensi

Aplikasi ini dibuat khusus untuk Masjid Al-Anwar. Silakan hubungi pengembang untuk penggunaan di tempat lain.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
