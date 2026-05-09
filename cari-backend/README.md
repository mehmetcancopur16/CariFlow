# CariFlow Backend

Node.js + Express API: JWT kimlik dogrulama, musteri ve hareket yonetimi, kullanici profili, dashboard ozeti, rate limiting, Swagger.

## Gereksinimler

- Node.js 20+
- MongoDB (yerel veya Atlas; transaction / tutarlilik icin replica set ortami onerilir)

## Kurulum

```bash
npm install
cp .env.example .env
```

## Ortam degiskenleri (`.env`)

| Degisken | Ornek | Aciklama |
|----------|-------|----------|
| `PORT` | `3000` | HTTP portu |
| `MONGO_URI` | `mongodb://127.0.0.1:27017/cariflow` | Mongo baglanti dizesi |
| `JWT_SECRET` | guclu rastgele | Access token imzasi |
| `JWT_REFRESH_SECRET` | guclu rastgele | Refresh token imzasi |

## Calistirma

```bash
npm run dev
```

Sessiz nodemon loglari:

```bash
npm run dev:clean
```

Production:

```bash
npm start
```

## Saglik ve dokumantasyon

- `GET /health` — `{ "status": "OK" }` (API prefix disinda, kok sunucuda)
- Swagger UI: `http://localhost:3000/api-docs/`
- Alias: `http://localhost:3000/swagger` → yonlendirme

## API rotalari (ozet)

| Prefix | Icerik |
|--------|--------|
| `/api/auth` | Register, login, refresh |
| `/api/users` | `GET/PATCH /me`, `POST /change-password` (auth gerekli) |
| `/api/clients` | Musteri CRUD, `GET /:id/transactions` |
| `/api/transactions` | Olusturma, `PUT /:id`, `DELETE /:id`, `GET /dashboard/summary` |

Hareket **guncelleme** ve **silme**, `balance.service` icinde oturum ile musteri `currentBalance` degerini tutarli sekilde yeniden hesaplar.

## Seeder

Gelistirme ve demo icin zengin veri:

```bash
npm run seed
```

Var olan demo kullanicilari silmeden profilleri gunceller; musteriler isim bazinda zaten varsa atlanir.

Tam sifirlama + yeniden olusturma:

```bash
npm run seed:reset
```

### Seed icerigi

- **3 demo kullanici** (`demo1..3@cariflow.local`), sifre: `Demo12345!`
- Her kullanici icin **dolu kurum alanlari** (unvan, vergi dairesi, vergi no, telefon, adres)
- Kullanici basina **10 musteri**; her 11. seri **pasif** (`isActive: false`) ve hareketsiz
- Aktif musteriler icin **5 farkli senaryo** (guclu alacak, odeme fazlasi / negatif bakiye, sifira yakin, buyuk borc + kismi odeme, karisik zaman cizelgesi)
- Turkce aciklamali hareketler ve gecmis tarihler

## Swagger

- `http://localhost:3000/api-docs/`
