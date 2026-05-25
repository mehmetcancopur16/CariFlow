# CariFlow Backend

Node.js + Express REST API: JWT auth, musteri / hareket yonetimi, dashboard ve Swagger.

## Gereksinimler

- Node.js 20+
- MongoDB 6+ (transaction kullanildigi icin replica set onerilir)

## Kurulum

```bash
npm install
cp .env.example .env
```

## Ortam degiskenleri

| Degisken | Aciklama |
|----------|----------|
| `PORT` | HTTP portu (varsayilan 3000) |
| `NODE_ENV` | `development` / `production` |
| `MONGO_URI` | Mongo baglanti dizesi |
| `JWT_SECRET` | Access token imzasi |
| `JWT_REFRESH_SECRET` | Refresh token imzasi |
| `CORS_ORIGIN` | Virgulle ayrilmis origin allowlist; `*` yalnizca dev |

Guclu secret uretmek icin: `openssl rand -hex 64`.

## Komutlar

```bash
npm run dev          # Nodemon ile gelistirme
npm start            # Production
npm run seed         # Demo veriyi olustur / guncelle
npm run seed:reset   # Tam sifirlama + yeniden seed
```

## Endpointler

| Prefix | Icerik |
|--------|--------|
| `/api/auth` | `register`, `login`, `refresh` |
| `/api/users` | `GET/PATCH /me`, `POST /change-password` |
| `/api/clients` | Musteri CRUD, `GET /:id/transactions` |
| `/api/transactions` | `POST /`, `PUT /:id`, `DELETE /:id`, `GET /dashboard/summary` |

- Saglik: `GET /health`
- Swagger UI: `GET /api-docs/`

## Guvenlik

- Helmet, HPP, JSON body limit (100 KB), `x-powered-by` kapali
- `/api` icin global rate limit; `/api/auth` icin sikilastirilmis ikinci kat
- Parola: bcrypt + min 8 karakter, buyuk/kucuk harf, rakam, ozel karakter
- Production'da sunucu hatasi mesajlari maskelenir

## Seed icerigi

- 3 demo kullanici (`demo1..3@cariflow.local`), sifre `Demo12345!`
- Her kullaniciya kurum profili + 10 musteri (1 tanesi pasif)
- 5 farkli senaryoda gercekci borc/tahsilat hareketleri
