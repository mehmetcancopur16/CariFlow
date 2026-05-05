# CariFlow Mobile (Flutter)

Flutter istemcisi; auth, musteri listesi/detay, islem ekleme, dashboard ozeti ve temel cihaz guvenlik kontrolu (root/jailbreak) icerir.

## Kurulum

```bash
flutter pub get
```

## Calistirma

```bash
flutter run
```

## Backend Baglantisi

Varsayilan API base URL:

- Android emulator: `http://10.0.2.2:3000/api`

Gerekirse `lib/core/constants/api_constants.dart` icindeki `baseUrl` degerini ortama gore guncelleyin.

## Temel Ozellikler

- JWT auth (access + refresh)
- Client listesi ve detay ekrani
- Transaction gecmisi ve yeni islem ekleme
- Dashboard summary karti
- Root/Jailbreak tespiti ile guvenlik blok ekrani

## Dogrulama Komutlari

```bash
flutter analyze
flutter test
```

## Guvenlik (Obfuscation)

Market dagitimi oncesi tersine muhendislik riskini azaltmak icin:

```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```
