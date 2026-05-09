# CariFlow Monorepo

CariFlow, cari (musteri) bakiyesi, borc / tahsilat hareketleri ve dashboard ozetini yoneten full-stack bir projedir. Repo iki ana paketi icerir:

| Klasor | Aciklama |
|--------|----------|
| `cari-backend/` | Node.js + Express + MongoDB REST API, JWT auth, Swagger |
| `cari_flutter/` | Flutter istemci (Riverpod, Dio, GoRouter) |

## Ozellikler (ozet)

- **Auth**: Kayit / giris, access + refresh JWT, guvenli token saklama
- **Kullanici**: `GET/PATCH /users/me`, sifre degisimi, kurum / vergi alanlari
- **Musteriler**: CRUD, liste, detay, pasif cari
- **Hareketler**: Borclandirma (`debt`) ve odeme (`payment`), liste, **duzenleme ve silme** (bakiye ile uyumlu)
- **Dashboard**: Toplam alacak / borc ozeti
- **Flutter**: Profil, ayarlar (tema, API, Swagger linki, sunucu sagligi), guvenlik (root/jailbreak tespiti)

## Hizli baslangic

### 1) Backend

```bash
cd cari-backend
cp .env.example .env
# .env icinde MONGO_URI, JWT_SECRET, JWT_REFRESH_SECRET degerlerini doldurun
npm install
npm run seed:reset   # ilk kurulumda onerilir
npm run dev
```

- API: `http://localhost:3000`
- Saglik: `http://localhost:3000/health`
- Swagger: `http://localhost:3000/api-docs/`

### 2) Flutter

```bash
cd cari_flutter
flutter pub get
flutter run
```

- **Web**: API varsayilan `http://localhost:3000/api`
- **Android emulator**: `http://10.0.2.2:3000/api` (`api_constants.dart`)

## Demo hesaplar (seed)

Tum demo kullanicilar ayni sifreyi kullanir: `Demo12345!`

- `demo1@cariflow.local`
- `demo2@cariflow.local`
- `demo3@cariflow.local`

Seed, her kullanici icin **ticari profil** (sirket adi, vergi dairesi, vb.) ve **10 adet ornek musteri** (bir tanesi pasif), farkli **bakiye senaryolari** ile hareketler uretir. Ayrintilar: `cari-backend/README.md`.

## Dokumantasyon

- [Backend README](cari-backend/README.md) — API, ortam, seeder, is kurallari
- [Flutter README](cari_flutter/README.md) — calistirma, tema, baglanti, guvenlik

## Is kurallari (API)

- `debt`: Musterinin cari bakiyesi **artar** (size borcu / alacak kaydi).
- `payment`: Tahsilat; bakiye **azalir**.
- Dashboard: `totalReceivable` pozitif bakiyelerin toplami; `totalPayable` negatif bakiyelerin mutlak toplami.
