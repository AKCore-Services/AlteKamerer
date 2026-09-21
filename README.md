# AlteKamerer

AlteKamerer är mobilapplikationen för AKCore.

Applikationen är byggd med Flutter och har Android som första målplattform.
Den använder befintliga AKCore-konton samt kalender-, aktivitets-,
anmälnings-, medlems- och behörighetsdata via AKCores mobila `/api/v1`-API.

Mobilapplikationen ansluter aldrig direkt till AKCore-databasen.

```text
AlteKamerer
    │
    ▼
AKCore /api/v1
    │
    ▼
AKCore-databasen
```

## Aktuell version

```text
1.0.0
```

Versionshistoriken finns i [CHANGELOG.md](CHANGELOG.md).

## Krav

Den verifierade utvecklingsmiljön är:

| Komponent | Version |
| --- | --- |
| Flutter | 3.47.2 |
| Dart | 3.13.2 |
| Java | 17 |
| Android SDK | API 37 |
| .NET SDK | 10.x |
| YAPF | 0.43.0 |
| clang-format | 14 |

Flutter innehåller den Dart SDK som krävs.

.NET, YAPF och clang-format behövs framför allt när hela AKCore-repot
valideras. För utveckling av själva Flutter-/Android-applikationen krävs
Flutter, Java och Android SDK.

## Flutter

Installera Flutter 3.47.2 och se till att dess `bin`-katalog finns i `PATH`.

Verifiera installationen:

```bash
flutter --version
dart --version
```

Verifierade versioner:

```text
Flutter 3.47.2
Dart 3.13.2
```

## Java

Android-byggen använder Java 17.

Verifiera aktiv Java-version:

```bash
java -version
```

Om Flutter använder fel JDK kan den konfigureras uttryckligen:

```bash
flutter config --jdk-dir /path/to/java-17
```

## Android SDK

Installera Android SDK och sätt `ANDROID_HOME` till dess sökväg.

AlteKamerer kompileras för närvarande mot Android API 37.

Installera plattformen med `sdkmanager`:

```bash
sdkmanager "platforms;android-37"
```

Acceptera Android SDK-licenserna:

```bash
flutter doctor --android-licenses
```

Verifiera Flutter-/Android-miljön:

```bash
flutter doctor -v
```

Android-delen ska rapporteras som fungerande innan applikationen byggs.

## Installera beroenden

Från repots rot:

```bash
flutter pub get
```

`pubspec.lock` är versionshanterad så att CI och lokal utveckling använder
samma upplösta paketversioner.

Applikationen använder bland annat:

- `http`
- `flutter_secure_storage`
- `flutter_local_notifications`
- `shared_preferences`
- `cupertino_icons`

För utveckling används bland annat:

- `flutter_test`
- `flutter_lints`

## API-konfiguration

AlteKamerer kommunicerar med AKCores mobila API.

Standardadress:

```text
https://www.altekamereren.org
```

Adressen kan ersättas vid körning eller bygge med:

```text
API_BASE_URL
```

Exempel:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://example.invalid
```

Värdet måste vara en absolut HTTP- eller HTTPS-adress.

Den vanliga produktionsapplikationen ska inte behöva någon override.

Det mobila API:t implementeras i det separata [AKCore-repot](https://github.com/LudHag/AKCore).

API-funktionaliteten i 1.0 omfattar autentisering, information om aktuell medlem,
kalenderdata, aktivitetsdetaljer, aktivitetsanmälan och registrering av mobila
enheter.

## Köra applikationen

Anslut en Android-enhet eller starta en Android-emulator:

```bash
flutter run
```

Mot en annan API-miljö:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://example.invalid
```

## Tester och statisk analys

Från AlteKamerer-katalogen:

```bash
flutter test --reporter compact
flutter analyze
```

Båda ska gå igenom innan mobilrelaterade ändringar slås samman.

## Formatering

Formatera Dart-källkoden med `dart format lib test`.

Verifiera formatering med `dart format --output=none --set-exit-if-changed lib test` och `git diff --check`.

## Debug-APK

Bygg en debug-APK med:

```bash
flutter build apk --debug
```

APK-filen skapas i:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Byggresultat versionshanteras inte.

## Release-APK

Bygg en release-APK med:

```bash
flutter build apk --release
```

Android-signering för release konfigureras genom:

```text
android/key.properties
```

Exempel på lokal konfiguration:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=<key alias>
storeFile=<path to keystore>
```

Signeringskonfiguration och nycklar ska inte versionshanteras.

Följande ignoreras av Git:

```text
android/key.properties
*.keystore
*.jks
```

Signeringsnycklar, lösenord, autentiseringstokens, service account-uppgifter
och maskinspecifik SDK-konfiguration får aldrig committas.

När `key.properties` finns använder Gradle den konfigurerade release-nyckeln.

När filen saknas faller den nuvarande Gradle-konfigurationen tillbaka på
debug-signering. En distribuerbar release måste därför byggas med korrekt
release-signering konfigurerad.

## Releaseflöde

Det taggstyrda releaseflödet finns i:

```text
.github/workflows/release.yml
```

Release-taggar använder formatet:

```text
altekamerer-vX.Y.Z
```

Exempel:

```text
altekamerer-v1.0.0
```

Releaseflödet:

1. återställer release-signeringen från CI-hemligheter;
2. verifierar att taggens version stämmer med `pubspec.yaml`;
3. bygger Android-applikationens signerade release-APK;
4. döper om den till `AlteKamerer-X.Y.Z.apk`;
5. laddar upp APK-filen till motsvarande GitHub Release.

För version 1.0.0 blir filnamnet:

```text
AlteKamerer-1.0.0.apk
```

Releasebygget är separat från den vanliga valideringen på `main`.

## Utvecklingsflöde

AlteKamerer utvecklas i det separata repot `AKCore-Services/AlteKamerer`.

`main` är projektets huvudgren. Feature- och fix-grenar skapas från `main` och slås samman via pull request efter validering.

Backend- och API-förändringar görs separat i [AKCore](https://github.com/LudHag/AKCore).

## Kontinuerlig integration

Repo-valideringen definieras i:

```text
.github/workflows/validation.yml
```

Pull requests och pushar till `main` kör två separata jobb.

### Tester och analys

Valideringsjobbet kör projektets valideringsskript:

```text
./scripts/validate-ci.sh
```

Det omfattar bland annat Flutter-tester, statisk analys och övriga
repo-kontroller.

### Debug-APK

Ett separat CI-jobb bygger:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

och publicerar den som en GitHub Actions-artifact.

Debug-APK-bygget och test-/analysjobbet körs separat.

Signerade releasebyggen hanteras av det separata taggstyrda
releaseflödet.

AKCore-backenden och dess tester valideras separat i AKCore-repot.

## Pushnotiser

AKCore-backenden innehåller serverinfrastruktur för:

- bedömning av notisrelevans;
- leveransspårning;
- registrering av mobila enheter;
- Firebase Cloud Messaging.

Servern kräver:

```text
MobilePush:ProjectId
```

för att identifiera Firebase-projektet.

Firebase Admin använder Google Application Default Credentials. Vid
driftsättning kan en service account-nyckel anges genom:

```text
GOOGLE_APPLICATION_CREDENTIALS
```

Credential-filer får aldrig committas.

Notisreglerna använder befintliga medlems-, anmälnings- och aktivitetsdata i
AKCore.

## Applikationsstruktur

Flutter-källkoden finns under:

```text
lib/
```

Viktiga områden:

```text
lib/core/config
lib/core/network
lib/core/storage
lib/core/theme

lib/features/auth
lib/features/calendar
lib/features/event_details
lib/features/event_registration
lib/features/notifications
lib/features/settings
lib/features/shell
```

Tester finns under:

```text
test/
```

Android-specifika projektfiler finns under:

```text
android/
```

## Förhållande till AKCore

AKCore är fortsatt källan till sanning för befintligt applikationsbeteende.

AlteKamerer använder uttryckliga mobila API-kontrakt och är inte direkt
beroende av webbplatsens controllers eller databasen.

Ändringar i det mobila API:ts beteende ska bevara motsvarande befintliga
AKCore-semantik om inte en beteendeförändring uttryckligen är avsedd och
granskad.
