import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sv'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AlteKamerer'**
  String get appTitle;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which language AlteKamerer uses.'**
  String get languageDescription;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @swedish.
  ///
  /// In en, this message translates to:
  /// **'Swedish'**
  String get swedish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @akCommonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get akCommonClose;

  /// No description provided for @akCommonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get akCommonPassword;

  /// No description provided for @akCommonUserName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get akCommonUserName;

  /// No description provided for @akCommonComing.
  ///
  /// In en, this message translates to:
  /// **'Coming'**
  String get akCommonComing;

  /// No description provided for @akCommonNotComing.
  ///
  /// In en, this message translates to:
  /// **'Not coming'**
  String get akCommonNotComing;

  /// No description provided for @akCommonGatherInHole.
  ///
  /// In en, this message translates to:
  /// **'Gather at hålan'**
  String get akCommonGatherInHole;

  /// No description provided for @akCommonGatherThere.
  ///
  /// In en, this message translates to:
  /// **'Gather there'**
  String get akCommonGatherThere;

  /// No description provided for @akCommonConcertStarts.
  ///
  /// In en, this message translates to:
  /// **'Concert starts'**
  String get akCommonConcertStarts;

  /// No description provided for @akCommonAtRehersalPlace.
  ///
  /// In en, this message translates to:
  /// **'At rehersal place'**
  String get akCommonAtRehersalPlace;

  /// No description provided for @akCommonPlayDuration.
  ///
  /// In en, this message translates to:
  /// **'Play duration'**
  String get akCommonPlayDuration;

  /// No description provided for @akCommonSignUpNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can not sign up to this gig anymore. For more info, contact the board members'**
  String get akCommonSignUpNotAllowed;

  /// No description provided for @akCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get akCountdownDays;

  /// No description provided for @akCountdownHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get akCountdownHours;

  /// No description provided for @akCountdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get akCountdownMinutes;

  /// No description provided for @akCountdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get akCountdownSeconds;

  /// No description provided for @akInstrumentAltsax.
  ///
  /// In en, this message translates to:
  /// **'Alto sax'**
  String get akInstrumentAltsax;

  /// No description provided for @akInstrumentBalett.
  ///
  /// In en, this message translates to:
  /// **'Ballet'**
  String get akInstrumentBalett;

  /// No description provided for @akInstrumentBanjo.
  ///
  /// In en, this message translates to:
  /// **'Banjo'**
  String get akInstrumentBanjo;

  /// No description provided for @akInstrumentBarytonsax.
  ///
  /// In en, this message translates to:
  /// **'Baritone sax'**
  String get akInstrumentBarytonsax;

  /// No description provided for @akInstrumentDragspel.
  ///
  /// In en, this message translates to:
  /// **'Accordion'**
  String get akInstrumentDragspel;

  /// No description provided for @akInstrumentEuphonium.
  ///
  /// In en, this message translates to:
  /// **'Euphonium'**
  String get akInstrumentEuphonium;

  /// No description provided for @akInstrumentFlojt.
  ///
  /// In en, this message translates to:
  /// **'Flute'**
  String get akInstrumentFlojt;

  /// No description provided for @akInstrumentHorn.
  ///
  /// In en, this message translates to:
  /// **'Horn'**
  String get akInstrumentHorn;

  /// No description provided for @akInstrumentKlarinett.
  ///
  /// In en, this message translates to:
  /// **'Clarinet'**
  String get akInstrumentKlarinett;

  /// No description provided for @akInstrumentOboe.
  ///
  /// In en, this message translates to:
  /// **'Oboe'**
  String get akInstrumentOboe;

  /// No description provided for @akInstrumentSlagverk.
  ///
  /// In en, this message translates to:
  /// **'Drums'**
  String get akInstrumentSlagverk;

  /// No description provided for @akInstrumentTenorsax.
  ///
  /// In en, this message translates to:
  /// **'Tenor sax'**
  String get akInstrumentTenorsax;

  /// No description provided for @akInstrumentTrombon.
  ///
  /// In en, this message translates to:
  /// **'Trombone'**
  String get akInstrumentTrombon;

  /// No description provided for @akInstrumentTrumpet.
  ///
  /// In en, this message translates to:
  /// **'Trumpet'**
  String get akInstrumentTrumpet;

  /// No description provided for @akInstrumentTuba.
  ///
  /// In en, this message translates to:
  /// **'Tuba'**
  String get akInstrumentTuba;

  /// No description provided for @akLoginLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get akLoginLogIn;

  /// No description provided for @akMailboxMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get akMailboxMessageSent;

  /// No description provided for @akMailboxSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get akMailboxSubject;

  /// No description provided for @akMailboxMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get akMailboxMessage;

  /// No description provided for @akMailboxSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get akMailboxSend;

  /// No description provided for @akMemberlistSearchHere.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get akMemberlistSearchHere;

  /// No description provided for @akMemberlistSearchForInstruments.
  ///
  /// In en, this message translates to:
  /// **'Search for instruments'**
  String get akMemberlistSearchForInstruments;

  /// No description provided for @akMemberlistAdressRegister.
  ///
  /// In en, this message translates to:
  /// **'Address register'**
  String get akMemberlistAdressRegister;

  /// No description provided for @akMusicShowAlbums.
  ///
  /// In en, this message translates to:
  /// **'Show albums'**
  String get akMusicShowAlbums;

  /// No description provided for @akMusicSearchSongs.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get akMusicSearchSongs;

  /// No description provided for @akMusicSearchHere.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get akMusicSearchHere;

  /// No description provided for @akMusicAlbumFromGpt.
  ///
  /// In en, this message translates to:
  /// **'Album description generated by ChatGPT'**
  String get akMusicAlbumFromGpt;

  /// No description provided for @akProfileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get akProfileFirstName;

  /// No description provided for @akProfileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get akProfileLastName;

  /// No description provided for @akProfileProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get akProfileProfileUpdated;

  /// No description provided for @akProfileUserName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get akProfileUserName;

  /// No description provided for @akProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get akProfileEmail;

  /// No description provided for @akProfilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get akProfilePhoneNumber;

  /// No description provided for @akProfileInstrument.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get akProfileInstrument;

  /// No description provided for @akProfileSelectInstrument.
  ///
  /// In en, this message translates to:
  /// **'Select instrument'**
  String get akProfileSelectInstrument;

  /// No description provided for @akProfileOtherInstruments.
  ///
  /// In en, this message translates to:
  /// **'Other instruments'**
  String get akProfileOtherInstruments;

  /// No description provided for @akProfileUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get akProfileUpdateProfile;

  /// No description provided for @akProfileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get akProfileChangePassword;

  /// No description provided for @akProfilePasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get akProfilePasswordUpdated;

  /// No description provided for @akProfileNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get akProfileNewPassword;

  /// No description provided for @akProfileConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get akProfileConfirmPassword;

  /// No description provided for @akProfileUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get akProfileUpdatePassword;

  /// No description provided for @akProfileRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get akProfileRoles;

  /// No description provided for @akProfilePosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get akProfilePosts;

  /// No description provided for @akProfileLatestMedal.
  ///
  /// In en, this message translates to:
  /// **'Latest medal'**
  String get akProfileLatestMedal;

  /// No description provided for @akProfileLatestMedalGiven.
  ///
  /// In en, this message translates to:
  /// **'Latest medal given'**
  String get akProfileLatestMedalGiven;

  /// No description provided for @akProfileUserInfo.
  ///
  /// In en, this message translates to:
  /// **'User info'**
  String get akProfileUserInfo;

  /// No description provided for @akProfileStatisticsHeader.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get akProfileStatisticsHeader;

  /// No description provided for @akProfileStatisticsPreamble.
  ///
  /// In en, this message translates to:
  /// **'Statistics for your performances the last year'**
  String get akProfileStatisticsPreamble;

  /// No description provided for @akProfileHalan.
  ///
  /// In en, this message translates to:
  /// **'Performances where you came via Hålan'**
  String get akProfileHalan;

  /// No description provided for @akProfileDirect.
  ///
  /// In en, this message translates to:
  /// **'Performances where you came directly'**
  String get akProfileDirect;

  /// No description provided for @akProfileCantCome.
  ///
  /// In en, this message translates to:
  /// **'Performances where you couldn\'t come'**
  String get akProfileCantCome;

  /// No description provided for @akProfileCar.
  ///
  /// In en, this message translates to:
  /// **'Performances where you drove a car'**
  String get akProfileCar;

  /// No description provided for @akProfileInstrumentOwn.
  ///
  /// In en, this message translates to:
  /// **'Performances where you brought your own instrument'**
  String get akProfileInstrumentOwn;

  /// No description provided for @akProfileComment.
  ///
  /// In en, this message translates to:
  /// **'Performances where you left a comment'**
  String get akProfileComment;

  /// No description provided for @akProfileTotalGigs.
  ///
  /// In en, this message translates to:
  /// **'Total number of performances'**
  String get akProfileTotalGigs;

  /// No description provided for @akProfileNoSignup.
  ///
  /// In en, this message translates to:
  /// **'Performances you haven\'t signed up for/signed up absence to'**
  String get akProfileNoSignup;

  /// No description provided for @akSignupShowInfo.
  ///
  /// In en, this message translates to:
  /// **'Show information'**
  String get akSignupShowInfo;

  /// No description provided for @akSignupEditSignups.
  ///
  /// In en, this message translates to:
  /// **'Edit signups'**
  String get akSignupEditSignups;

  /// No description provided for @akSignupNeedInstrumentTransport.
  ///
  /// In en, this message translates to:
  /// **'Needs instrument transport'**
  String get akSignupNeedInstrumentTransport;

  /// No description provided for @akSignupHasCar.
  ///
  /// In en, this message translates to:
  /// **'Has car'**
  String get akSignupHasCar;

  /// No description provided for @akSignupComingTo.
  ///
  /// In en, this message translates to:
  /// **'Coming to'**
  String get akSignupComingTo;

  /// No description provided for @akSignupHalan.
  ///
  /// In en, this message translates to:
  /// **'Hålan'**
  String get akSignupHalan;

  /// No description provided for @akSignupDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get akSignupDirect;

  /// No description provided for @akSignupCantCome.
  ///
  /// In en, this message translates to:
  /// **'Can\'t come'**
  String get akSignupCantCome;

  /// No description provided for @akSignupBringsInstrument.
  ///
  /// In en, this message translates to:
  /// **'Pack my instrument, please. I will describe my case in the comment below (if no nametag is present).'**
  String get akSignupBringsInstrument;

  /// No description provided for @akSignupComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get akSignupComment;

  /// No description provided for @akSignupSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get akSignupSignUp;

  /// No description provided for @akSignupInstrument.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get akSignupInstrument;

  /// No description provided for @akSignupNoInstrument.
  ///
  /// In en, this message translates to:
  /// **'No instrument'**
  String get akSignupNoInstrument;

  /// No description provided for @akUpcomingSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get akUpcomingSignUp;

  /// No description provided for @akUpcomingSignedUp.
  ///
  /// In en, this message translates to:
  /// **'Signed up'**
  String get akUpcomingSignedUp;

  /// No description provided for @akUpcomingAboutEvent.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get akUpcomingAboutEvent;

  /// No description provided for @akUpcomingTypeOfPlay.
  ///
  /// In en, this message translates to:
  /// **'Type of concert'**
  String get akUpcomingTypeOfPlay;

  /// No description provided for @akUpcomingFikaAndClean.
  ///
  /// In en, this message translates to:
  /// **'Fika and cleaning'**
  String get akUpcomingFikaAndClean;

  /// No description provided for @akUpcomingIcalLink.
  ///
  /// In en, this message translates to:
  /// **'iCal-link'**
  String get akUpcomingIcalLink;

  /// No description provided for @akUpcomingList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get akUpcomingList;

  /// No description provided for @akUpcomingMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get akUpcomingMonth;

  /// No description provided for @akUpcomingAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All rehearsals'**
  String get akUpcomingAllFilter;

  /// No description provided for @akUpcomingBalletFilter.
  ///
  /// In en, this message translates to:
  /// **'Ballet rehearsals'**
  String get akUpcomingBalletFilter;

  /// No description provided for @akUpcomingOrchestraFilter.
  ///
  /// In en, this message translates to:
  /// **'Orchestra rehearsals'**
  String get akUpcomingOrchestraFilter;

  /// No description provided for @akUpcomingNoConcerts.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately we have no planned public concerts in the upcoming weeks'**
  String get akUpcomingNoConcerts;

  /// No description provided for @akUpcomingRep.
  ///
  /// In en, this message translates to:
  /// **'Orchestra rehearsal'**
  String get akUpcomingRep;

  /// No description provided for @akUpcomingKarhusrep.
  ///
  /// In en, this message translates to:
  /// **'Student union building rehearsal'**
  String get akUpcomingKarhusrep;

  /// No description provided for @akUpcomingBalettrep.
  ///
  /// In en, this message translates to:
  /// **'Ballet rehearsal'**
  String get akUpcomingBalettrep;

  /// No description provided for @akUpcomingAthenrep.
  ///
  /// In en, this message translates to:
  /// **'Athen rehearsal'**
  String get akUpcomingAthenrep;

  /// No description provided for @akUpcomingSamlingsrep.
  ///
  /// In en, this message translates to:
  /// **'Collective rehearsal'**
  String get akUpcomingSamlingsrep;

  /// No description provided for @akUpcomingFikarep.
  ///
  /// In en, this message translates to:
  /// **'Fika rehearsal'**
  String get akUpcomingFikarep;

  /// No description provided for @akVideosSearchVideos.
  ///
  /// In en, this message translates to:
  /// **'Search for video'**
  String get akVideosSearchVideos;

  /// No description provided for @akVideosShowAllVideos.
  ///
  /// In en, this message translates to:
  /// **'Show all videos'**
  String get akVideosShowAllVideos;

  /// No description provided for @akServiceCommonFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get akServiceCommonFirstName;

  /// No description provided for @akServiceCommonLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get akServiceCommonLastName;

  /// No description provided for @akServiceCommonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get akServiceCommonEmail;

  /// No description provided for @akServiceCommonPhone.
  ///
  /// In en, this message translates to:
  /// **'Telephone number'**
  String get akServiceCommonPhone;

  /// No description provided for @akServiceCommonSelectInstrument.
  ///
  /// In en, this message translates to:
  /// **'Select instrument'**
  String get akServiceCommonSelectInstrument;

  /// No description provided for @akServiceCommonGigs.
  ///
  /// In en, this message translates to:
  /// **'Upcoming gigs'**
  String get akServiceCommonGigs;

  /// No description provided for @akServiceCommonUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get akServiceCommonUpcoming;

  /// No description provided for @akServiceCommonContinueContent.
  ///
  /// In en, this message translates to:
  /// **'Skip to content'**
  String get akServiceCommonContinueContent;

  /// No description provided for @akServiceWidgetsHireUs.
  ///
  /// In en, this message translates to:
  /// **'Do you want to hire us?'**
  String get akServiceWidgetsHireUs;

  /// No description provided for @akServiceWidgetsJoinUs.
  ///
  /// In en, this message translates to:
  /// **'Do you want to play or dance with us?'**
  String get akServiceWidgetsJoinUs;

  /// No description provided for @akServiceWidgetsAnswerWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Answer with a number'**
  String get akServiceWidgetsAnswerWithNumber;

  /// No description provided for @akServiceWidgetsBotQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is 1 + 2?'**
  String get akServiceWidgetsBotQuestion;

  /// No description provided for @akServiceWidgetsJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get akServiceWidgetsJoin;

  /// No description provided for @akServiceWidgetsHire.
  ///
  /// In en, this message translates to:
  /// **'Hire us'**
  String get akServiceWidgetsHire;

  /// No description provided for @akServiceHeaderLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get akServiceHeaderLogIn;

  /// No description provided for @akServiceHeaderLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get akServiceHeaderLogOut;

  /// No description provided for @akServiceHeaderUnreadInterested.
  ///
  /// In en, this message translates to:
  /// **'unread interested'**
  String get akServiceHeaderUnreadInterested;

  /// No description provided for @akServiceHeaderLoggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as'**
  String get akServiceHeaderLoggedInAs;

  /// No description provided for @akServiceErrorWrongPage.
  ///
  /// In en, this message translates to:
  /// **'Hello, this is the wrong page you nitwit'**
  String get akServiceErrorWrongPage;

  /// No description provided for @akServiceErrorNothingToSee.
  ///
  /// In en, this message translates to:
  /// **'Nothing to see here...'**
  String get akServiceErrorNothingToSee;

  /// No description provided for @akServiceInstrumentAccordion.
  ///
  /// In en, this message translates to:
  /// **'Accordion'**
  String get akServiceInstrumentAccordion;

  /// No description provided for @akServiceInstrumentAltsax.
  ///
  /// In en, this message translates to:
  /// **'Alto sax'**
  String get akServiceInstrumentAltsax;

  /// No description provided for @akServiceInstrumentBalett.
  ///
  /// In en, this message translates to:
  /// **'Ballet'**
  String get akServiceInstrumentBalett;

  /// No description provided for @akServiceInstrumentBanjo.
  ///
  /// In en, this message translates to:
  /// **'Banjo'**
  String get akServiceInstrumentBanjo;

  /// No description provided for @akServiceInstrumentBarytonsax.
  ///
  /// In en, this message translates to:
  /// **'Baritone sax'**
  String get akServiceInstrumentBarytonsax;

  /// No description provided for @akServiceInstrumentEuphonium.
  ///
  /// In en, this message translates to:
  /// **'Euphonium'**
  String get akServiceInstrumentEuphonium;

  /// No description provided for @akServiceInstrumentFlute.
  ///
  /// In en, this message translates to:
  /// **'Flute'**
  String get akServiceInstrumentFlute;

  /// No description provided for @akServiceInstrumentHorn.
  ///
  /// In en, this message translates to:
  /// **'Horn'**
  String get akServiceInstrumentHorn;

  /// No description provided for @akServiceInstrumentKlarinett.
  ///
  /// In en, this message translates to:
  /// **'Clarinet'**
  String get akServiceInstrumentKlarinett;

  /// No description provided for @akServiceInstrumentOboe.
  ///
  /// In en, this message translates to:
  /// **'Oboe'**
  String get akServiceInstrumentOboe;

  /// No description provided for @akServiceInstrumentSlagverk.
  ///
  /// In en, this message translates to:
  /// **'Drums'**
  String get akServiceInstrumentSlagverk;

  /// No description provided for @akServiceInstrumentTenorsax.
  ///
  /// In en, this message translates to:
  /// **'Tenor sax'**
  String get akServiceInstrumentTenorsax;

  /// No description provided for @akServiceInstrumentTrombon.
  ///
  /// In en, this message translates to:
  /// **'Trombone'**
  String get akServiceInstrumentTrombon;

  /// No description provided for @akServiceInstrumentTrumpet.
  ///
  /// In en, this message translates to:
  /// **'Trumpet'**
  String get akServiceInstrumentTrumpet;

  /// No description provided for @akServiceInstrumentTuba.
  ///
  /// In en, this message translates to:
  /// **'Tuba'**
  String get akServiceInstrumentTuba;

  /// No description provided for @akServiceUpcomingPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get akServiceUpcomingPageTitle;

  /// No description provided for @akServiceUpcomingSignupPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-up'**
  String get akServiceUpcomingSignupPageTitle;

  /// No description provided for @akServiceUpcomingInvalidData.
  ///
  /// In en, this message translates to:
  /// **'Invalid data'**
  String get akServiceUpcomingInvalidData;

  /// No description provided for @akServiceUpcomingInvalidId.
  ///
  /// In en, this message translates to:
  /// **'Invalid id'**
  String get akServiceUpcomingInvalidId;

  /// No description provided for @akServiceUpcomingMustChooseWhere.
  ///
  /// In en, this message translates to:
  /// **'You must choose whether you are coming via Hålan, direct, or not at all'**
  String get akServiceUpcomingMustChooseWhere;

  /// No description provided for @akServiceUpcomingSignupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Sign-up updated'**
  String get akServiceUpcomingSignupUpdated;

  /// No description provided for @akServiceProfilePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get akServiceProfilePageTitle;

  /// No description provided for @akServiceProfileDuplicateInstrument.
  ///
  /// In en, this message translates to:
  /// **'You cannot select the same instrument as both primary and additional instrument.'**
  String get akServiceProfileDuplicateInstrument;

  /// No description provided for @akServiceProfileProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your profile was updated'**
  String get akServiceProfileProfileUpdated;

  /// No description provided for @akServiceProfilePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get akServiceProfilePasswordChanged;

  /// No description provided for @akPostsOk.
  ///
  /// In en, this message translates to:
  /// **'Chairman'**
  String get akPostsOk;

  /// No description provided for @akPostsKk.
  ///
  /// In en, this message translates to:
  /// **'Treasurer'**
  String get akPostsKk;

  /// No description provided for @akPostsSk.
  ///
  /// In en, this message translates to:
  /// **'Secretary'**
  String get akPostsSk;

  /// No description provided for @akPostsOpk.
  ///
  /// In en, this message translates to:
  /// **'Vice Chairman'**
  String get akPostsOpk;

  /// No description provided for @akPostsBallet.
  ///
  /// In en, this message translates to:
  /// **'Responsible for the ballet'**
  String get akPostsBallet;

  /// No description provided for @akPostsMusic.
  ///
  /// In en, this message translates to:
  /// **'Responsible for the artistic - conductor'**
  String get akPostsMusic;

  /// No description provided for @akPostsPub.
  ///
  /// In en, this message translates to:
  /// **'Responsible for the pub'**
  String get akPostsPub;

  /// No description provided for @akPostsSex.
  ///
  /// In en, this message translates to:
  /// **'Responsible for parties'**
  String get akPostsSex;

  /// No description provided for @akPostsArsenal.
  ///
  /// In en, this message translates to:
  /// **'Responsible for orchestras instruments and the reparations for them'**
  String get akPostsArsenal;

  /// No description provided for @akPostsBus.
  ///
  /// In en, this message translates to:
  /// **'Responsible for the pig (bus)'**
  String get akPostsBus;

  /// No description provided for @akPostsCamera.
  ///
  /// In en, this message translates to:
  /// **'Responsible for documenting AK in photo and video'**
  String get akPostsCamera;

  /// No description provided for @akPostsHug.
  ///
  /// In en, this message translates to:
  /// **'Responsible for acting like a safe contact for the members of the organisation'**
  String get akPostsHug;

  /// No description provided for @akPostsCozy.
  ///
  /// In en, this message translates to:
  /// **'Responsible for making Hålan cozy(toilet paper etc)'**
  String get akPostsCozy;

  /// No description provided for @akPostsNintendo.
  ///
  /// In en, this message translates to:
  /// **'Responsible for the computer in Hålan, AKs website, info and snack email lists'**
  String get akPostsNintendo;

  /// No description provided for @akPostsNostalgia.
  ///
  /// In en, this message translates to:
  /// **'Responsible for the orchestras collective memory'**
  String get akPostsNostalgia;

  /// No description provided for @akPostsNote.
  ///
  /// In en, this message translates to:
  /// **'Responsible for note archive'**
  String get akPostsNote;

  /// No description provided for @akPostsPr.
  ///
  /// In en, this message translates to:
  /// **'Responsible for us being heard and seen via for example posters'**
  String get akPostsPr;

  /// No description provided for @akPostsGadget.
  ///
  /// In en, this message translates to:
  /// **'Responsible for medals, t-shirts, brands etc.'**
  String get akPostsGadget;

  /// No description provided for @akPostsScrub.
  ///
  /// In en, this message translates to:
  /// **'Responsible for Hålan, for exampel light bulbs etc.'**
  String get akPostsScrub;

  /// No description provided for @akPostsSponsor.
  ///
  /// In en, this message translates to:
  /// **'Responsible for finding sponsors'**
  String get akPostsSponsor;

  /// No description provided for @akPostsBitKamerer.
  ///
  /// In en, this message translates to:
  /// **'Responsible for filming the ballet\'s new choreographies after each rehearsal and uploading them to the website'**
  String get akPostsBitKamerer;

  /// No description provided for @akPostsSyKamerer.
  ///
  /// In en, this message translates to:
  /// **'Responsible for sewing the ballet\'s uniform skirts'**
  String get akPostsSyKamerer;

  /// No description provided for @akPostsBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get akPostsBoard;

  /// No description provided for @akPostsFunctionaries.
  ///
  /// In en, this message translates to:
  /// **'Functionaries'**
  String get akPostsFunctionaries;

  /// No description provided for @akPostsOtherPosts.
  ///
  /// In en, this message translates to:
  /// **'Other posts'**
  String get akPostsOtherPosts;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @sessionCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'AlteKamerer could not verify your login with AKCore.'**
  String get sessionCheckFailed;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in with your existing AK account.'**
  String get loginDescription;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your user name.'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in…'**
  String get loggingIn;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect user name or password.'**
  String get invalidCredentials;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not log in. Try again.'**
  String get loginFailed;

  /// No description provided for @akCoreConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to AKCore. Try again.'**
  String get akCoreConnectionFailed;

  /// No description provided for @calendarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the calendar'**
  String get calendarLoadFailed;

  /// No description provided for @calendarLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'AlteKamerer could not load upcoming activities from AKCore.'**
  String get calendarLoadFailedMessage;

  /// No description provided for @calendarDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get calendarDate;

  /// No description provided for @calendarTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get calendarTime;

  /// No description provided for @calendarType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get calendarType;

  /// No description provided for @calendarPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get calendarPlace;

  /// No description provided for @calendarViewUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get calendarViewUpcoming;

  /// No description provided for @calendarViewToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarViewToday;

  /// No description provided for @calendarViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarViewWeek;

  /// No description provided for @calendarViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarViewMonth;

  /// No description provided for @calendarCurrentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarCurrentPeriod;

  /// No description provided for @calendarNoActivitiesInView.
  ///
  /// In en, this message translates to:
  /// **'No activities in this view'**
  String get calendarNoActivitiesInView;

  /// No description provided for @calendarPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get calendarPreviousWeek;

  /// No description provided for @calendarNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get calendarNextWeek;

  /// No description provided for @calendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPreviousMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @noUpcomingActivities.
  ///
  /// In en, this message translates to:
  /// **'No upcoming activities'**
  String get noUpcomingActivities;

  /// No description provided for @emptyCalendar.
  ///
  /// In en, this message translates to:
  /// **'There are no activities in the calendar right now.'**
  String get emptyCalendar;

  /// No description provided for @registeredAttending.
  ///
  /// In en, this message translates to:
  /// **'Signed up and attending'**
  String get registeredAttending;

  /// No description provided for @registeredNotAttending.
  ///
  /// In en, this message translates to:
  /// **'Signed up but not attending'**
  String get registeredNotAttending;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not signed up'**
  String get notRegistered;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get connectionFailed;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @eventLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load activity'**
  String get eventLoadFailed;

  /// No description provided for @eventLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'AlteKamerer could not load the activity from AKCore.'**
  String get eventLoadFailedMessage;

  /// No description provided for @eventDisplayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not display activity'**
  String get eventDisplayFailed;

  /// No description provided for @eventInfoMissing.
  ///
  /// In en, this message translates to:
  /// **'Activity information is missing.'**
  String get eventInfoMissing;

  /// No description provided for @eventOnSite.
  ///
  /// In en, this message translates to:
  /// **'On site'**
  String get eventOnSite;

  /// No description provided for @eventStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get eventStart;

  /// No description provided for @eventPlayDuration.
  ///
  /// In en, this message translates to:
  /// **'Play time'**
  String get eventPlayDuration;

  /// No description provided for @eventMusicStand.
  ///
  /// In en, this message translates to:
  /// **'Music stand'**
  String get eventMusicStand;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @internalInformation.
  ///
  /// In en, this message translates to:
  /// **'Internal information'**
  String get internalInformation;

  /// No description provided for @eventRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get eventRegistration;

  /// No description provided for @yourStatus.
  ///
  /// In en, this message translates to:
  /// **'Your status: {status}'**
  String yourStatus(String status);

  /// No description provided for @registrationCounts.
  ///
  /// In en, this message translates to:
  /// **'{coming} attending · {notComing} not attending'**
  String registrationCounts(int coming, int notComing);

  /// No description provided for @registrationClosed.
  ///
  /// In en, this message translates to:
  /// **'Registration is closed for this activity.'**
  String get registrationClosed;

  /// No description provided for @registrationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Registration can no longer be changed for this activity.'**
  String get registrationUnavailable;

  /// No description provided for @changeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Change registration'**
  String get changeRegistration;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @hasCar.
  ///
  /// In en, this message translates to:
  /// **'Has car'**
  String get hasCar;

  /// No description provided for @bringsOwnInstrument.
  ///
  /// In en, this message translates to:
  /// **'Bringing own instrument'**
  String get bringsOwnInstrument;

  /// No description provided for @saveRegistration.
  ///
  /// In en, this message translates to:
  /// **'Save registration'**
  String get saveRegistration;

  /// No description provided for @selectArrivalRequired.
  ///
  /// In en, this message translates to:
  /// **'You must choose how you are arriving.'**
  String get selectArrivalRequired;

  /// No description provided for @registrationSaveInvalid.
  ///
  /// In en, this message translates to:
  /// **'Registration could not be saved. Check the information and try again.'**
  String get registrationSaveInvalid;

  /// No description provided for @activityNoLongerExists.
  ///
  /// In en, this message translates to:
  /// **'The activity no longer exists.'**
  String get activityNoLongerExists;

  /// No description provided for @registrationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration could not be saved. Try again.'**
  String get registrationSaveFailed;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how long before an activity you want to be reminded.'**
  String get remindersDescription;

  /// No description provided for @noRemindersEnabled.
  ///
  /// In en, this message translates to:
  /// **'No reminders are enabled.'**
  String get noRemindersEnabled;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get addReminder;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @reminderTimeBefore.
  ///
  /// In en, this message translates to:
  /// **'Time before'**
  String get reminderTimeBefore;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @removeReminder.
  ///
  /// In en, this message translates to:
  /// **'Remove reminder'**
  String get removeReminder;

  /// No description provided for @reminderPositiveTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'All reminders must have a time greater than 0.'**
  String get reminderPositiveTimeRequired;

  /// No description provided for @duplicateReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Two reminders cannot have the same time before the activity.'**
  String get duplicateReminderTime;

  /// No description provided for @remindersSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminders saved.'**
  String get remindersSaved;

  /// No description provided for @remindersSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The reminders could not be saved. Try again.'**
  String get remindersSaveFailed;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings'**
  String get settingsLoadFailed;

  /// No description provided for @reminderSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The reminder settings could not be loaded.'**
  String get reminderSettingsLoadFailed;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Activity reminders'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders for activities in AlteKamerer'**
  String get notificationChannelDescription;

  /// No description provided for @notificationStartsInOneHour.
  ///
  /// In en, this message translates to:
  /// **'Starts in 1 hour'**
  String get notificationStartsInOneHour;

  /// No description provided for @notificationStartsInHours.
  ///
  /// In en, this message translates to:
  /// **'Starts in {hours} hours'**
  String notificationStartsInHours(int hours);

  /// No description provided for @notificationStartsInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Starts in {minutes} minutes'**
  String notificationStartsInMinutes(int minutes);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sv'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
