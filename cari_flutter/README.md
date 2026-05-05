# CariFlow - Cari Bakiye Takip Sistemi

CariFlow, kucuk ve orta olcekli isletmeler icin cari takibi, bakiye yonetimi ve islem kayitlarini tek bir platformda sunan bir uygulamadir.

## Kurulum ve Calistirma

### Backend (Node.js)
1. Backend dizinine gir:
   - `cd cari-backend`
2. Bagimliliklari kur:
   - `npm install`
3. Ortam degiskenlerini ayarla (`.env`):
   - `PORT=3000`
   - `MONGO_URI=...`
   - `JWT_SECRET=...`
4. Gelistirme modunda calistir:
   - `npm run dev`

### Flutter (Mobil)
1. Flutter dizinine gir:
   - `cd cari_flutter`
2. Bagimliliklari kur:
   - `flutter pub get`
3. Uygulamayi baslat:
   - `flutter run`

## Guvenlik (Obfuscation)
Market dagitimi oncesi tersine muhendislik riskini azaltmak icin APK'yi obfuscation ile alin:

`flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols`
