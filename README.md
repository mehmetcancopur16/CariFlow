# CariFlow Monorepo

CariFlow, cari/musteri bakiyesi ve tahsilat takibini yoneten full-stack bir projedir.
Bu repo iki ana uygulamayi barindirir:

- `cari-backend`: Node.js + Express + MongoDB API
- `cari_flutter`: Flutter mobil istemci

## Proje Yapisi

- `cari-backend/` : API, auth, clients, transactions, swagger, seed
- `cari_flutter/` : Riverpod + Dio + GoRouter tabanli mobil uygulama

## Hizli Baslangic

### 1) Backend

```bash
cd cari-backend
cp .env.example .env
npm install
npm run seed:reset
npm run dev
```

API varsayilan olarak `http://localhost:3000` adresinde calisir.
Swagger: `http://localhost:3000/api-docs`

### 2) Flutter

```bash
cd cari_flutter
flutter pub get
flutter run
```

Android emulator icin backend base URL: `http://10.0.2.2:3000/api`

## Demo Giris Bilgileri (Seed)

- `demo1@cariflow.local` / `Demo12345!`
- `demo2@cariflow.local` / `Demo12345!`
- `demo3@cariflow.local` / `Demo12345!`

## Diger Dokumanlar

- Backend ayrintilari: `cari-backend/README.md`
- Mobil ayrintilar: `cari_flutter/README.md`
