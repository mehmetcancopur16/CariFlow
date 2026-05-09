# CariFlow (Flutter)

CariFlow mobil ve web istemcisi: JWT oturumu, musteri ve hareket yonetimi, dashboard, profil, ayarlar ve cihaz guvenligi.

## Gereksinimler

- Flutter SDK (proje `sdk: ^3.9.2`)
- Calisan `cari-backend` (yerel veya erisilebilir ag adresi)

## Kurulum

```bash
flutter pub get
```

## Calistirma

```bash
flutter run
```

Web veya cihaz secimini IDE / CLI uzerinden yapin.

Terminal cikisini sade tutmak icin (opsiyonel):

```bash
bash scripts/run-clean.sh
```

## Backend adresi

`lib/core/constants/api_constants.dart` icinde:

- **Web / masaustu (localhost)**: `http://localhost:3000/api`
- **Android emulator**: `http://10.0.2.2:3000/api`

Kok sunucu adresi (Swagger ve saglik kontrolu) otomatik turetilir: `serverOrigin`, `healthUrl`, `swaggerUrl`.

## Ana ozellikler

| Alan | Aciklama |
|------|----------|
| Auth | Giris / kayit, token yenileme, guvenli depolama |
| Dashboard | Ozet kartlari (alacak / borc) |
| Musteriler | Liste, detay, duzenleme, silme |
| Hareketler | Ekleme, **duzenleme**, **silme**, liste |
| Profil | `GET /users/me` ile kurum bilgileri, `PATCH` kayit, sifre degisimi |
| Ayarlar | **Tema** (sistem / acik / koyu, `shared_preferences`), API adresi, **sunucu sagligi** (`GET /health`), Swagger acma, surum bilgisi (`package_info_plus`), profil kisayolu |
| Guvenlik | Kok / jailbreak tespitinde blok ekrani |

## Tema

`themeModeProvider` uygulama genelinde `MaterialApp.themeMode` ile baglidir; kullanici tercihi kalici saklanir.

## Dogrulama

```bash
flutter analyze
flutter test
```

## Release / obfuscation (Android ornegi)

```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```

## Bagimlilik notlari

- **Dio**: REST istekleri
- **GoRouter**: `AppShell` ile alt navigasyon (dashboard, musteriler, islem, profil, ayarlar)
- **url_launcher**: Ayarlardan Swagger URL acma
- **shared_preferences**: Tema modu
- **package_info_plus**: Uygulama surumu
