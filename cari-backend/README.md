# CariFlow Backend

Node.js + Express tabanli API. JWT auth, client/transaction yonetimi, dashboard ozeti ve Swagger dokumantasyonu icerir.

## Gereksinimler

- Node.js 20+
- MongoDB (transaction destegi icin replica set/Atlas onerilir)

## Kurulum

```bash
npm install
cp .env.example .env
```

## Ortam Degiskenleri

`.env` dosyasi:

- `PORT=3000`
- `MONGO_URI=mongodb://127.0.0.1:27017/cariflow`
- `JWT_SECRET=replace_with_strong_secret`
- `JWT_REFRESH_SECRET=replace_with_strong_refresh_secret`

## Calistirma

```bash
npm run dev
```

Sade terminal ciktilari icin:

```bash
npm run dev:clean
```

Production:

```bash
npm start
```

## Seeder

Demo-rich seed verisi olusturur.

```bash
npm run seed
```

Temizleyip yeniden seed:

```bash
npm run seed:reset
```

Seeder demo kullanicilari:

- `demo1@cariflow.local` / `Demo12345!`
- `demo2@cariflow.local` / `Demo12345!`
- `demo3@cariflow.local` / `Demo12345!`

## API ve Sozlesme Notlari

- `debt`: musterinin bize borcu artar (`currentBalance` artar)
- `payment`: musteri odeme yaptikca alacak azalir (`currentBalance` azalir)
- Dashboard:
  - `totalReceivable` = `currentBalance > 0` toplami
  - `totalPayable` = `currentBalance < 0` mutlak toplami

## Swagger

API dokumani:

- `http://localhost:3000/api-docs/`
- `http://localhost:3000/swagger` (alias)
