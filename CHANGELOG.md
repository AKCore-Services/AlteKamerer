# Ändringslogg

Alla betydande AlteKamerer-releaser dokumenteras här.

## 1.0.0

Första Android-releasen av AlteKamerer, mobilapplikationen för AKCore.

### Autentisering

- Inloggning med befintliga AKCore-konton.
- Säker lagring av autentiseringsuppgifter.
- Beständiga autentiserade sessioner mellan omstarter.
- Hantering och rotation av refresh tokens.
- Utloggning med återkallning av den mobila sessionen.
- Applikationen kräver autentisering.

### Medlemsinformation

- API för aktuell medlem.
- Medlemskap, balettrelevans och instrumentinformation används där
  mobilfunktionaliteten kräver det.

### Kalender

- Autentiserad AKCore-kalender.
- Kalendersynlighet baserad på AKCores befintliga medlemssemantik.
- Mobil kalenderpresentation med AKCores visuella identitet.

### Aktiviteter

- Vy för aktivitetsdetaljer.
- AKCore-information om aktiviteter exponeras genom ett uttryckligt mobilt API.
- Navigering från kalenderposter och notiser till motsvarande aktivitet.

### Aktivitetsanmälan

- Anmälan genom mobilapplikationen.
- Stöd för `Hålan`, `Direkt` och `Kan inte komma`.
- Anmälningsbeteendet följer AKCores befintliga regler.
- Dubblettanmälningar förhindras.
- Inaktiverade och passerade aktiviteter hanteras.
- Ändringar sparas i samma AKCore-data som webbplatsen använder.

### Notiser

- Registrering av mobila enheter.
- Notisrelevans samma dag baserad på medlems- och aktivitetsdata.
- Relevans för orkesterrep, balettrep och övriga stödda reptyper.
- Relevans för aktiviteter som medlemmen är anmäld till.
- `Kan inte komma` fungerar som uttryckligt avstående från notiser för
  aktiviteten.
- Spårning av notisleveranser.
- Backend-integration med Firebase Cloud Messaging.
- Navigering från notis till motsvarande aktivitet.

### Android-applikation

- Flutter-applikation för Android.
- AKCores logotyp, färger, terminologi och visuella identitet.
- Säker lagring av autentiseringsuppgifter.
- Gränssnitt för kalender, aktivitet, anmälan och notiser.
- Stöd för att bygga Android-APK.

### Mobilt API

Version 1.0 introducerar autentiserade `/api/v1`-endpoints för:

- autentisering;
- information om aktuell medlem;
- kalender;
- aktivitetsdetaljer;
- aktivitetsanmälan;
- registrering av mobila enheter.

API:t är ett tillägg till den befintliga AKCore-webbplatsen och använder
AKCore-backenden och databasen som källa till sanning.

### Utveckling och CI

- Flutter-tester och statisk analys.
- AKCore-integrationstester för det mobila API:t.
- Formateringskontroller för repot.
- Generering av debug-APK i CI.
- Taggstyrda signerade Android-releasebyggen.
- Versionskontroll mellan release-taggar och `pubspec.yaml`.
- Versionsmärkta release-APK-artifacts.
