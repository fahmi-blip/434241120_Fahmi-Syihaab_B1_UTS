# E-Ticketing Helpdesk Backend (Express.js & PostgreSQL)

Ini adalah backend REST API server untuk aplikasi E-Ticketing Helpdesk. Project ini dibangun menggunakan **Node.js** dengan web framework **Express.js** dan database **PostgreSQL**.

---

## 🛠️ Tech Stack & Dependencies

- **Framework**: Express.js
- **Database Driver**: `pg` (node-postgres)
- **Authentication**: `jsonwebtoken` (JWT)
- **Security**: `bcryptjs` (Hashing password)
- **ID Generator**: `uuid`

---

## ⚙️ Persyaratan Awal (Prerequisites)

1. **Node.js** (Versi >= 18)
2. **PostgreSQL Server** (Terinstal dan berjalan di komputer Anda)
3. **Database Kosong**: Buatlah sebuah database kosong di PostgreSQL Anda. Contoh nama database: `eticketing_db`.
   ```sql
   CREATE DATABASE eticketing_db;
   ```

---

## 🚀 Cara Menjalankan Backend

1. **Masuk ke folder backend**:
   Buka terminal di root workspace lalu pindah ke folder backend:
   ```bash
   cd backend
   ```

2. **Instal dependencies**:
   ```bash
   npm install
   ```

3. **Konfigurasi Environment (.env)**:
   Buka file `.env` di dalam folder `backend/` dan sesuaikan kredensial PostgreSQL Anda:
   ```env
   PORT=3000
   JWT_SECRET=supersecretkeyforeticketinghelpdesk123!
   
   # Konfigurasi database PostgreSQL lokal Anda
   DB_USER=postgres
   DB_PASSWORD=your_password_here
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=eticketing_db
   ```

4. **Jalankan server dalam mode development**:
   ```bash
   npm run dev
   ```
   *Saat pertama kali dijalankan, server akan mendeteksi database kosong dan otomatis menjalankan `schema.sql` untuk membuat tabel serta melakukan seeding data user default.*

---

## 👥 Akun Uji Coba Default (Seeded Users)

Setelah inisialisasi database berhasil, Anda dapat langsung melakukan login menggunakan kredensial berikut:

| Nama | Email | Password | Role |
| :--- | :--- | :--- | :--- |
| **John Customer** | `user@example.com` | `password123` | `user` |
| **Sarah Support** | `support@example.com` | `password123` | `support` |
| **Alex Admin** | `admin@example.com` | `password123` | `admin` |

---

## 📑 Endpoint REST API

Semua endpoints diawali dengan base path `/api`. Endpoints yang diproteksi memerlukan header `Authorization: Bearer <token_jwt>`.

### 1. Authentication (`/api/auth`)
* `POST /api/auth/register` - Pendaftaran user baru
* `POST /api/auth/login` - Login untuk mendapatkan token JWT
* `POST /api/auth/logout` - Logout (token invalidation)
* `POST /api/auth/reset-password` - Kirim email password reset (mock response)
* `GET /api/auth/me` - Ambil info user aktif (Memerlukan Token)
* `PUT /api/auth/profile` - Update profil user aktif (Memerlukan Token)

### 2. Tickets (`/api/tickets`)
*(Semua endpoint tiket memerlukan Token JWT)*
* `GET /api/tickets` - Ambil daftar tiket (Mendukung filter: `status`, `priority`, `category`, `search`, `assigned_to` & pagination: `limit`, `offset`)
  * *Catatan RLS: Role `user` hanya melihat tiket miliknya sendiri. Role `admin`/`support` melihat semua tiket.*
* `GET /api/tickets/:id` - Ambil detail tiket lengkap beserta komentar, riwayat, dan attachment.
* `POST /api/tickets` - Buat tiket baru (Otomatis menghasilkan nomor tiket seperti `TKT-001` dan mencatat history)
* `PUT /api/tickets/:id` - Update status/prioritas/assignee tiket (Otomatis mencatat audit log perubahan ke tabel history)
* `DELETE /api/tickets/:id` - Hapus tiket (Hanya diizinkan untuk Admin, atau pembuat tiket jika statusnya masih `open`)
* `POST /api/tickets/:id/comments` - Menambah komentar atau catatan internal tiket
* `GET /api/tickets/:id/comments` - Ambil daftar komentar untuk tiket tertentu

---

## 📱 Cara Menghubungkan Flutter Frontend ke Express REST API

Karena Flutter frontend Anda saat ini memanggil Supabase SDK langsung, jika Anda ingin memigrasikan Flutter ke REST API ini:
1. Ganti package `supabase_flutter` dengan `dio` atau `http` di `pubspec.yaml`.
2. Ubah implementasi di `lib/data/datasources/api/auth_api_service.dart` dan `lib/data/datasources/api/ticket_api_service.dart` untuk melakukan request HTTP (`POST`, `GET`, `PUT`, `DELETE`) ke `http://localhost:3000/api/...` daripada memanggil method Supabase client.
3. Kirimkan token yang didapat saat login di header request:
   ```dart
   options.headers['Authorization'] = 'Bearer $token';
   ```
