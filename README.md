# CariFlow

Cari (musteri) bakiyesi, borc/tahsilat hareketleri ve dashboard ozetini yoneten full-stack monorepo.

## Yapi

- `cari-backend/` — Node.js + Express + MongoDB REST API (JWT, Swagger)
- `cari_flutter/` — Flutter istemci (Riverpod, Dio, GoRouter)

## Hizli baslangic

Backend:

```bash
cd cari-backend
cp .env.example .env   # JWT_SECRET, JWT_REFRESH_SECRET, MONGO_URI doldur
npm install
npm run seed:reset
npm run dev
```

API: `http://localhost:3000` · Saglik: `/health` · Swagger: `/api-docs/`

Flutter:

```bash
cd cari_flutter
flutter pub get
flutter run
```

Android emulator API adresi `http://10.0.2.2:3000/api` (bkz. `lib/core/constants/api_constants.dart`).

## Demo hesaplar

Seed sonrasi olusan kullanicilar (ortak sifre: `Demo12345!`):

- `demo1@cariflow.local`
- `demo2@cariflow.local`
- `demo3@cariflow.local`

## Is kurallari

- `debt`: Musterinin bakiyesi **artar** (alacak).
- `payment`: Tahsilat; bakiye **azalir**.
- Dashboard `totalReceivable` = pozitif bakiyelerin toplami; `totalPayable` = negatif bakiyelerin mutlak toplami.

## Dokumantasyon

- [Backend](cari-backend/README.md)
- [Flutter](cari_flutter/README.md)
