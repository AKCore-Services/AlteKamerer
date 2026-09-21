# Ändringslogg

Alla betydande AlteKamerer-releaser dokumenteras här.

## 1.0.0

Första stabila Android-releasen av AlteKamerer, mobilapplikationen för AKCore.

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
- Navigering från kalenderposter till aktivitetsdetaljer.

### Aktiviteter

- Vy för aktivitetsdetaljer.
- AKCore-information om aktiviteter exponeras genom ett uttryckligt mobilt API.
- Navigering från kalenderposter och notiser till motsvarande aktivitet.

### Aktivitetsanmälan

- Anmälan genom mobilapplikationen.
- Stöd för `Hålan`, `Direkt` och `Kan inte komma`.
- Anmälningsbeteendet följer AKCores befintliga regler.
- Dubblettanmälningar förhindras mellan mobilapplikationen och webbplatsen.
- Inaktiverade och passerade aktiviteter hanteras enligt AKCores regler.
- Ändringar sparas i samma AKCore-data som webbplatsen använder.
- Ändringar som görs i appen och på webbplatsen visas i båda klienterna.

### Notiser

- Registrering av mobila enheter.
- Notisrelevans baserad på medlems-, aktivitets- och anmälningsdata.
- Relevans för orkesterrep, balettrep och övriga stödda reptyper.
- Relevans för aktiviteter som medlemmen är anmäld till.
- `Kan inte komma` fungerar som uttryckligt avstående från notiser för
  aktiviteten.
- Spårning av notisleveranser.
- Backend-integration med Firebase Cloud Messaging.
- Navigering från notis till motsvarande aktivitet.
- Förvalda påminnelser 5 timmar och 1 timme före aktivitet.
- Inställningar för valfria påminnelsetider.
- Stöd för flera eller inga påminnelser.
- Notisinställningar sparas lokalt och ändringar synkroniserar schemalagda
  notiser direkt.

### Android-applikation

- Flutter-applikation för Android.
- AKCores logotyp, färger, terminologi och visuella identitet.
- Adaptiv Android-appikon som följer launcher-enhetens ikonmask.
- Säker lagring av autentiseringsuppgifter.
- Gränssnitt för kalender, aktivitet, anmälan, notiser och inställningar.
- Navigeringsmeny för kalender, inställningar och utloggning.
- Stöd för debug- och signerade release-APK:er.

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
- Separata CI-jobb för validering och debug-APK.
- Taggstyrda signerade Android-releasebyggen.
- Versionskontroll mellan release-taggar och `pubspec.yaml`.
- Versionsmärkta APK-filer.
- Automatisk uppladdning av signerad APK till motsvarande GitHub Release.

### Releasevalidering

Version 1.0.0 validerades mot en faktisk AKCore-miljö med bland annat:

- installation av release-APK;
- giltig och ogiltig inloggning;
- beständig session och utloggning;
- kalender och aktivitetsdetaljer;
- samtliga stödda anmälningsalternativ;
- synkronisering mellan webbplats och app;
- relevanta aktivitets- och repnotiser;
- notisundantag för `Kan inte komma`;
- navigering från notis till aktivitet;
- regression av befintlig AKCore-webbplats;
- signerad Android-release via CI.