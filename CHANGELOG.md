# Ändringslogg

Alla betydande AlteKamerer-releaser dokumenteras här.

## 1.2.0

En uppdatering med bättre stöd för användning utan nätverk, förbättrad
länkhantering, bakgrundsuppdatering och snabbare återkoppling i appen.

### Offline och cache

- Kalender och aktivitetsdetaljer kan visas från lokalt sparad data när
  AKCore inte kan nås.
- Aktivitetsdetaljer visas från cache direkt när sådan data finns och
  uppdateras därefter mot AKCore.
- Cachad aktivitetsinformation kan uppdateras manuellt genom att dra nedåt
  i aktivitetsvyn.
- Cachad medlemsdata förblir skrivskyddad när appen är offline; anmälningar
  kräver fortsatt bekräftelse från AKCore.
- En tidigare verifierad session kan ge tillgång till cachad information i
  upp till 24 timmar utan nätverksanslutning.

### Länkar och navigering

- Förbättrad hantering av länkar till aktiviteter.
- Länkar hanteras mer tillförlitligt även när appen behöver startas eller
  återställa sin session innan aktiviteten kan öppnas.

### Uppdatering

- Appen uppdaterar relevant data när den återgår till aktiv användning.
- Öppnade aktivitetsdetaljer kan uppdateras efter återgång till appen utan
  att användaren först behöver navigera tillbaka till kalendern.

### Prestanda och nätverk

- Startgränssnittet visas tidigare medan notifieringar och session
  initieras i bakgrunden.
- Nätverksanrop har en begränsad väntetid och avbryts när tidsgränsen nås.
- Befintliga HTTP-anslutningar återanvänds och onödiga väntetider vid
  nätverksfel har minskats.
- Befintlig cache används tidigare i flödet för att ge snabbare
  återkoppling.

## 1.1.1

En mindre funktions- och kvalitetsuppdatering med förbättrade inställningar,
kalenderpresentation och lokal diagnostik.

### Kalender

- Förenklad filtrering av kalenderaktiviteter och tydligare presentation av
  aktiva filter.
- Förbättrad kalenderpresentation utan att ändra AKCores befintliga semantik
  för aktiviteter eller synlighet.

### Inställningar

- Inställningar kan exporteras till och importeras från en lokal säkerhetskopia.
- Importerade säkerhetskopior kan innehålla delar av inställningarna utan att
  övriga lokala inställningar skrivs över.
- Ny sektion med information om AlteKamerer, appversion och utvecklingsprojekt.
- Länkar till AlteKamerers och AKCores källkod.

### Diagnostik

- Ny användartillgänglig diagnostik med appversion, buildnummer, plattform och
  serverinformation.
- Lokala applikationsfel kan visas, kopieras som en diagnostikrapport och
  rensas från enheten.
- Diagnostikloggen är lokalt lagrad och begränsad i storlek.
- Lösenord, autentiseringstokens, sessionsidentifierare och andra hemligheter
  ska inte lagras i diagnostikloggen.
- Ingen diagnostik eller telemetri skickas automatiskt till en extern tjänst.

### Android

- Korrigerat applikationsnamnet som visas i Androids launcher.

## 1.1.0

Den första funktionsuppdateringen efter AlteKamerer 1.0 med utökad kalender,
språkstöd, förbättrad tillgänglighet och förbättringar av Android-upplevelsen.

### Språk

- Stöd för svenska och engelska i applikationens gränssnitt.
- Språk kan väljas i inställningarna och valet sparas lokalt.
- Datum och kalenderpresentation följer valt språk där det är relevant.

### Kalender

- Utökade kalendervyer för enklare navigering och överblick.
- Filtrering av kalenderaktiviteter.
- Sökning bland kalenderaktiviteter.
- Konfigurerbar datumvisning med kompakt, numeriskt eller skrivet format.
- Valbar lokaliserad veckodagsförkortning.
- Konfigurerbar 24- eller 12-timmarsvisning.
- Kalenderns visningsinställningar sparas lokalt och tillämpas direkt.
- Befintlig AKCore-semantik för aktiviteter, sortering, synlighet och
  anmälningar är oförändrad.

### Aktivitetsanmälan

- Förbättrat gränssnitt och återkoppling vid aktivitetsanmälan.
- Tydligare presentation av aktuell anmälningsstatus och tillgängliga val.

### Tillgänglighet

- Förbättrad hantering av större textstorlekar.
- Förbättrade semantiska etiketter och stöd för hjälpmedel.
- Förbättrad layout för innehåll som behöver mer utrymme.

### Android

- Förbättrad Android-anpassning och visuellt beteende.
- Förbättrad hantering av systemets status- och navigationsytor.
- Förbättrad integration med Androids visuella systembeteende.

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