# CariFlow Flutter

CariFlow mobil ve web istemcisi: JWT oturumu, musteri / hareket yonetimi, dashboard, profil ve cihaz guvenligi.

## Gereksinimler

- Flutter SDK `>=3.9.2`
- Calisan `cari-backend` (yerel veya erisilebilir adres)

## Calistirma

```bash
flutter pub get
flutter run
```

## Backend adresi

`lib/core/constants/api_constants.dart` icinde:

- Web / masaustu: `http://localhost:3000/api`
- Android emulator: `http://10.0.2.2:3000/api`

Sunucu kok adresi `serverOrigin`, saglik (`healthUrl`) ve Swagger (`swaggerUrl`) bu degerden turetilir.

## Mimari

- Riverpod: state ve servis provider'lari
- Dio + interceptor: bearer ekleme, 401'de tek seferlik refresh
- GoRouter + `AppShell`: dashboard / musteriler / islem / profil / ayarlar
- `flutter_secure_storage`: access + refresh token
- `flutter_jailbreak_detection`: root / jailbreak tespitinde blok ekrani

## Kalite

```bash
flutter analyze
flutter test
```

## Release (Android ornegi)

```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```
