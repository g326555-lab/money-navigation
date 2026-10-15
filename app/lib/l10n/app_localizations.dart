import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

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
    Locale('th'),
  ];

  /// App name shown in the system and top of Home.
  ///
  /// In en, this message translates to:
  /// **'Money Navigation'**
  String get appName;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Fit the ATM screen inside the frame'**
  String get scanHint;

  /// No description provided for @scanShutter.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanShutter;

  /// No description provided for @scanChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get scanChoosePhoto;

  /// No description provided for @scanClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get scanClose;

  /// No description provided for @scanFlashOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on light'**
  String get scanFlashOn;

  /// No description provided for @scanFlashOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off light'**
  String get scanFlashOff;

  /// No description provided for @scanCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available right now.'**
  String get scanCameraUnavailable;

  /// No description provided for @scanCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off for Money Navigation. Turn it on in Settings, or choose a photo.'**
  String get scanCameraDenied;

  /// No description provided for @stepReadText.
  ///
  /// In en, this message translates to:
  /// **'Reading the photo'**
  String get stepReadText;

  /// No description provided for @stepReadTextDone.
  ///
  /// In en, this message translates to:
  /// **'Read on your phone in {ms} ms'**
  String stepReadTextDone(int ms);

  /// No description provided for @stepFindAtm.
  ///
  /// In en, this message translates to:
  /// **'Looking for an ATM conversion offer'**
  String get stepFindAtm;

  /// No description provided for @stepFindAtmDone.
  ///
  /// In en, this message translates to:
  /// **'ATM conversion offer found'**
  String get stepFindAtmDone;

  /// No description provided for @stepValues.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal {withdrawal} · fee {fee} · 1 USD = {rate} THB'**
  String stepValues(String withdrawal, String fee, String rate);

  /// No description provided for @stepValuesMarkup.
  ///
  /// In en, this message translates to:
  /// **'{values} · mark-up {markup}'**
  String stepValuesMarkup(String values, String markup);

  /// No description provided for @stepCompare.
  ///
  /// In en, this message translates to:
  /// **'Comparing both totals'**
  String get stepCompare;

  /// No description provided for @stepCompareDone.
  ///
  /// In en, this message translates to:
  /// **'Converting costs about {amount} more'**
  String stepCompareDone(String amount);

  /// No description provided for @stepCompareEven.
  ///
  /// In en, this message translates to:
  /// **'Both totals come out about the same'**
  String get stepCompareEven;

  /// No description provided for @scanTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get scanTryAgain;

  /// No description provided for @atmKeepLabel.
  ///
  /// In en, this message translates to:
  /// **'You keep about'**
  String get atmKeepLabel;

  /// No description provided for @atmPress.
  ///
  /// In en, this message translates to:
  /// **'Press'**
  String get atmPress;

  /// No description provided for @atmDeclineButton.
  ///
  /// In en, this message translates to:
  /// **'The option without conversion, so you pay in baht'**
  String get atmDeclineButton;

  /// No description provided for @atmReasonMarkup.
  ///
  /// In en, this message translates to:
  /// **'The ATM\'s own rate adds {markup} on top.'**
  String atmReasonMarkup(String markup);

  /// No description provided for @atmReasonNoMarkup.
  ///
  /// In en, this message translates to:
  /// **'The ATM\'s own rate charges more than the rate on its screen.'**
  String get atmReasonNoMarkup;

  /// No description provided for @atmSource.
  ///
  /// In en, this message translates to:
  /// **'From the numbers on this ATM screen · {time}'**
  String atmSource(String time);

  /// No description provided for @atmEvenTitle.
  ///
  /// In en, this message translates to:
  /// **'Either choice costs about the same'**
  String get atmEvenTitle;

  /// No description provided for @atmEvenBody.
  ///
  /// In en, this message translates to:
  /// **'The converted total matches the rate on the screen, so there is nothing to keep here.'**
  String get atmEvenBody;

  /// No description provided for @stepFindAtmFailed.
  ///
  /// In en, this message translates to:
  /// **'No currency choice or rate board in this photo'**
  String get stepFindAtmFailed;

  /// No description provided for @stepReadTextFailed.
  ///
  /// In en, this message translates to:
  /// **'No text found'**
  String get stepReadTextFailed;

  /// No description provided for @stepValuesFailed.
  ///
  /// In en, this message translates to:
  /// **'Some numbers couldn\'t be read'**
  String get stepValuesFailed;

  /// No description provided for @scanTipNoText.
  ///
  /// In en, this message translates to:
  /// **'Move closer so the screen fills most of the photo.'**
  String get scanTipNoText;

  /// No description provided for @scanTipNotAtm.
  ///
  /// In en, this message translates to:
  /// **'Point straight at the screen that offers two currencies, or at a rate board.'**
  String get scanTipNotAtm;

  /// No description provided for @scanTipLooksLikeBill.
  ///
  /// In en, this message translates to:
  /// **'This looks like a bill. You can check it here.'**
  String get scanTipLooksLikeBill;

  /// No description provided for @scanTipMissingValues.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone straight and avoid glare on the screen.'**
  String get scanTipMissingValues;

  /// No description provided for @atmBothTotals.
  ///
  /// In en, this message translates to:
  /// **'Both totals'**
  String get atmBothTotals;

  /// No description provided for @atmIfConvertDetail.
  ///
  /// In en, this message translates to:
  /// **'At the ATM\'s own rate'**
  String get atmIfConvertDetail;

  /// No description provided for @atmIfNotConvertDetail.
  ///
  /// In en, this message translates to:
  /// **'Your card\'s bank converts it'**
  String get atmIfNotConvertDetail;

  /// No description provided for @atmOnScreen.
  ///
  /// In en, this message translates to:
  /// **'On this screen'**
  String get atmOnScreen;

  /// No description provided for @atmRowWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get atmRowWithdrawal;

  /// No description provided for @atmRowFee.
  ///
  /// In en, this message translates to:
  /// **'ATM access fee'**
  String get atmRowFee;

  /// No description provided for @atmRowRate.
  ///
  /// In en, this message translates to:
  /// **'Rate shown'**
  String get atmRowRate;

  /// No description provided for @atmRowMarkup.
  ///
  /// In en, this message translates to:
  /// **'Mark-up shown'**
  String get atmRowMarkup;

  /// No description provided for @atmRateValue.
  ///
  /// In en, this message translates to:
  /// **'1 USD = {rate} THB'**
  String atmRateValue(String rate);

  /// No description provided for @atmIfConvert.
  ///
  /// In en, this message translates to:
  /// **'If you convert'**
  String get atmIfConvert;

  /// No description provided for @atmIfNotConvert.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t'**
  String get atmIfNotConvert;

  /// No description provided for @atmScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan another'**
  String get atmScanAnother;

  /// No description provided for @speakOpen.
  ///
  /// In en, this message translates to:
  /// **'Hear a price'**
  String get speakOpen;

  /// No description provided for @speakListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get speakListening;

  /// No description provided for @speakListenHint.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone toward the seller'**
  String get speakListenHint;

  /// No description provided for @speakStop.
  ///
  /// In en, this message translates to:
  /// **'Done listening'**
  String get speakStop;

  /// No description provided for @speakListenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get speakListenAgain;

  /// No description provided for @speakTypeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Check this price'**
  String get speakTypeSubmit;

  /// No description provided for @speakHeard.
  ///
  /// In en, this message translates to:
  /// **'They said'**
  String get speakHeard;

  /// No description provided for @speakMeaning.
  ///
  /// In en, this message translates to:
  /// **'{item}, {amount} {unit}'**
  String speakMeaning(String item, String amount, String unit);

  /// No description provided for @unitPerKg.
  ///
  /// In en, this message translates to:
  /// **'per kilo'**
  String get unitPerKg;

  /// No description provided for @unitEach.
  ///
  /// In en, this message translates to:
  /// **'each'**
  String get unitEach;

  /// No description provided for @unitPerPlate.
  ///
  /// In en, this message translates to:
  /// **'per plate'**
  String get unitPerPlate;

  /// No description provided for @unitPerHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get unitPerHour;

  /// No description provided for @unitPerRide.
  ///
  /// In en, this message translates to:
  /// **'per ride'**
  String get unitPerRide;

  /// No description provided for @verdictHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get verdictHigh;

  /// No description provided for @verdictFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get verdictFair;

  /// No description provided for @verdictLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get verdictLow;

  /// No description provided for @speakOverBy.
  ///
  /// In en, this message translates to:
  /// **'{amount} above the usual price'**
  String speakOverBy(String amount);

  /// No description provided for @speakFairBody.
  ///
  /// In en, this message translates to:
  /// **'This is within the usual price.'**
  String get speakFairBody;

  /// No description provided for @speakLowBody.
  ///
  /// In en, this message translates to:
  /// **'This is below the usual price.'**
  String get speakLowBody;

  /// No description provided for @speakUsualPrice.
  ///
  /// In en, this message translates to:
  /// **'Usual price'**
  String get speakUsualPrice;

  /// No description provided for @speakUsualRange.
  ///
  /// In en, this message translates to:
  /// **'{low}–{high} THB {unit}'**
  String speakUsualRange(String low, String high, String unit);

  /// No description provided for @speakAsked.
  ///
  /// In en, this message translates to:
  /// **'Asked'**
  String get speakAsked;

  /// No description provided for @speakSources.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source} other{{count} sources}} · {month}'**
  String speakSources(int count, String month);

  /// No description provided for @speakCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'Ask for'**
  String get speakCounterLabel;

  /// No description provided for @speakCounterAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} THB'**
  String speakCounterAmount(String amount);

  /// No description provided for @speakSayIt.
  ///
  /// In en, this message translates to:
  /// **'Say it in Thai'**
  String get speakSayIt;

  /// No description provided for @speakSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get speakSpeaking;

  /// No description provided for @speakNoVoice.
  ///
  /// In en, this message translates to:
  /// **'No Thai voice on this phone. Show the sentence to the seller instead.'**
  String get speakNoVoice;

  /// Said aloud to the seller in Thai in every locale. ending is the polite particle the traveler chose, or empty.
  ///
  /// In en, this message translates to:
  /// **'ลดเหลือ {amount} บาทได้ไหม{ending}'**
  String counterOfferSentence(String amount, String ending);

  /// No description provided for @speakNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'Nothing was heard'**
  String get speakNothingHeard;

  /// No description provided for @speakNothingHeardTip.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the seller and try again, or type what you heard.'**
  String get speakNothingHeardTip;

  /// No description provided for @speakNoPrice.
  ///
  /// In en, this message translates to:
  /// **'No price in what was heard'**
  String get speakNoPrice;

  /// No description provided for @speakNoPriceTip.
  ///
  /// In en, this message translates to:
  /// **'Ask the seller the price again, then listen.'**
  String get speakNoPriceTip;

  /// No description provided for @speakUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'No usual price for this yet'**
  String get speakUnknownItem;

  /// No description provided for @speakUnknownItemTip.
  ///
  /// In en, this message translates to:
  /// **'The price was {amount}. We only compare items we have sources for.'**
  String speakUnknownItemTip(String amount);

  /// No description provided for @speakUnitMismatch.
  ///
  /// In en, this message translates to:
  /// **'The price is for a different amount'**
  String get speakUnitMismatch;

  /// No description provided for @speakUnitMismatchTip.
  ///
  /// In en, this message translates to:
  /// **'The usual price is {unit}. Ask the seller for the price {unit}.'**
  String speakUnitMismatchTip(String unit);

  /// No description provided for @speakEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get speakEnterPrice;

  /// No description provided for @speakEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'What is the seller asking?'**
  String get speakEnterTitle;

  /// No description provided for @speakPickItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get speakPickItem;

  /// No description provided for @speakPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price in THB'**
  String get speakPriceLabel;

  /// No description provided for @speakEntered.
  ///
  /// In en, this message translates to:
  /// **'You entered'**
  String get speakEntered;

  /// No description provided for @speakPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting ready'**
  String get speakPreparing;

  /// No description provided for @speakUsualRangeRow.
  ///
  /// In en, this message translates to:
  /// **'Usual range'**
  String get speakUsualRangeRow;

  /// No description provided for @speakHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'{item} · {unit}'**
  String speakHeroLabel(String item, String unit);

  /// No description provided for @speakSourcesLine.
  ///
  /// In en, this message translates to:
  /// **'{hosts} · {sources}'**
  String speakSourcesLine(String hosts, String sources);

  /// No description provided for @speakMonthRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to}'**
  String speakMonthRange(String from, String to);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @speakWhichItem.
  ///
  /// In en, this message translates to:
  /// **'What are they selling?'**
  String get speakWhichItem;

  /// No description provided for @speakHeardPrice.
  ///
  /// In en, this message translates to:
  /// **'We heard {price}.'**
  String speakHeardPrice(String price);

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get tabScan;

  /// No description provided for @tabSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get tabSpeak;

  /// No description provided for @tabRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get tabRecords;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @homeKeptLabel.
  ///
  /// In en, this message translates to:
  /// **'Kept on this trip'**
  String get homeKeptLabel;

  /// No description provided for @homeKeptApprox.
  ///
  /// In en, this message translates to:
  /// **'About {amount}'**
  String homeKeptApprox(String amount);

  /// No description provided for @ratePair.
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to}'**
  String ratePair(String from, String rate, String to);

  /// No description provided for @homeRateSource.
  ///
  /// In en, this message translates to:
  /// **'{pair} on {date} · European Central Bank via Frankfurter'**
  String homeRateSource(String pair, String date);

  /// No description provided for @homeRateCached.
  ///
  /// In en, this message translates to:
  /// **'{pair} on {date} · European Central Bank via Frankfurter · last known, offline'**
  String homeRateCached(String pair, String date);

  /// No description provided for @homeRateLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting today\'s rate'**
  String get homeRateLoading;

  /// No description provided for @homeRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Today\'s {currency} rate needs a connection'**
  String homeRateUnavailable(String currency);

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent saves'**
  String get homeRecent;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeEmptyLabel.
  ///
  /// In en, this message translates to:
  /// **'Before you withdraw'**
  String get homeEmptyLabel;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the ATM screen before you press anything'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Open the scanner'**
  String get homeEmptyAction;

  /// No description provided for @saveKeptValue.
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String saveKeptValue(String amount);

  /// No description provided for @saveAtmTitle.
  ///
  /// In en, this message translates to:
  /// **'ATM conversion avoided'**
  String get saveAtmTitle;

  /// No description provided for @saveHaggleTitle.
  ///
  /// In en, this message translates to:
  /// **'{item} haggled down'**
  String saveHaggleTitle(String item);

  /// No description provided for @saveHaggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paid {paid} · {when}'**
  String saveHaggleSubtitle(String paid, String when);

  /// No description provided for @saveHaggleUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'Market price'**
  String get saveHaggleUnknownItem;

  /// No description provided for @saveToTrip.
  ///
  /// In en, this message translates to:
  /// **'Save to trip'**
  String get saveToTrip;

  /// No description provided for @savedToTrip.
  ///
  /// In en, this message translates to:
  /// **'Saved to trip'**
  String get savedToTrip;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTitle;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet. Results you save after a scan or a haggle are listed here.'**
  String get recordsEmpty;

  /// No description provided for @recordsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get recordsRemove;

  /// No description provided for @recordsFooter.
  ///
  /// In en, this message translates to:
  /// **'Swipe a row left to remove it. Saved only on this phone.'**
  String get recordsFooter;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Home currency'**
  String get settingsCurrency;

  /// No description provided for @settingsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsChange;

  /// No description provided for @settingsCurrencyFooter.
  ///
  /// In en, this message translates to:
  /// **'Totals also show in this currency at the daily rate from Frankfurter (European Central Bank).'**
  String get settingsCurrencyFooter;

  /// No description provided for @settingsSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking Thai for you'**
  String get settingsSpeaking;

  /// No description provided for @settingsEndingMale.
  ///
  /// In en, this message translates to:
  /// **'End with khrap'**
  String get settingsEndingMale;

  /// No description provided for @settingsEndingFemale.
  ///
  /// In en, this message translates to:
  /// **'End with kha'**
  String get settingsEndingFemale;

  /// No description provided for @settingsEndingNone.
  ///
  /// In en, this message translates to:
  /// **'No ending'**
  String get settingsEndingNone;

  /// No description provided for @settingsSpeakingFooter.
  ///
  /// In en, this message translates to:
  /// **'Thai speakers end a polite request with khrap (men) or kha (women).'**
  String get settingsSpeakingFooter;

  /// No description provided for @politeEndingMale.
  ///
  /// In en, this message translates to:
  /// **'ครับ'**
  String get politeEndingMale;

  /// No description provided for @politeEndingFemale.
  ///
  /// In en, this message translates to:
  /// **'คะ'**
  String get politeEndingFemale;

  /// No description provided for @currencyOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to load the list of currencies.'**
  String get currencyOffline;

  /// No description provided for @currencySource.
  ///
  /// In en, this message translates to:
  /// **'Currencies with a daily reference rate from the European Central Bank.'**
  String get currencySource;

  /// No description provided for @haggleSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'What did you pay?'**
  String get haggleSaveTitle;

  /// No description provided for @haggleSaveOffer.
  ///
  /// In en, this message translates to:
  /// **'Your offer'**
  String get haggleSaveOffer;

  /// No description provided for @haggleSaveAsked.
  ///
  /// In en, this message translates to:
  /// **'Their price'**
  String get haggleSaveAsked;

  /// No description provided for @haggleSaveOther.
  ///
  /// In en, this message translates to:
  /// **'Another amount'**
  String get haggleSaveOther;

  /// No description provided for @haggleSaveKeeps.
  ///
  /// In en, this message translates to:
  /// **'Keeps {amount}'**
  String haggleSaveKeeps(String amount);

  /// No description provided for @settingsEndingExample.
  ///
  /// In en, this message translates to:
  /// **'…ได้ไหม{ending}'**
  String settingsEndingExample(String ending);

  /// No description provided for @haggleSaveTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Enter less than {amount}, the price they asked'**
  String haggleSaveTooHigh(String amount);

  /// No description provided for @speakDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone is off'**
  String get speakDeniedTitle;

  /// No description provided for @speakDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on the microphone for Money Navigation in Settings, or enter the price yourself.'**
  String get speakDeniedBody;

  /// No description provided for @speakUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Thai listening isn\'t available'**
  String get speakUnavailableTitle;

  /// No description provided for @speakUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t recognise Thai speech. Enter the price yourself instead.'**
  String get speakUnavailableBody;

  /// No description provided for @speakOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get speakOpenSettings;

  /// No description provided for @speakAmountUnit.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit}'**
  String speakAmountUnit(String amount, String unit);

  /// No description provided for @haggleSaveChoice.
  ///
  /// In en, this message translates to:
  /// **'{label} · {amount}'**
  String haggleSaveChoice(String label, String amount);

  /// No description provided for @speakPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a number, like 150'**
  String get speakPriceInvalid;

  /// No description provided for @speakPriceTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Prices up to {amount}'**
  String speakPriceTooHigh(String amount);

  /// No description provided for @haggleSaveNothingKept.
  ///
  /// In en, this message translates to:
  /// **'Paying their price keeps nothing to save'**
  String get haggleSaveNothingKept;

  /// No description provided for @recordsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from this trip'**
  String get recordsRemoved;

  /// No description provided for @recordsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get recordsUndo;

  /// No description provided for @aiTrace.
  ///
  /// In en, this message translates to:
  /// **'Checked by {engine} · {elapsed}'**
  String aiTrace(String engine, String elapsed);

  /// No description provided for @aiVoiceCached.
  ///
  /// In en, this message translates to:
  /// **'Voice from {engine}, saved on this phone'**
  String aiVoiceCached(String engine);

  /// No description provided for @aiItemMatched.
  ///
  /// In en, this message translates to:
  /// **'{engine} matched what was heard to {item}, {confidence} sure · {elapsed}'**
  String aiItemMatched(
    String engine,
    String item,
    String confidence,
    String elapsed,
  );

  /// No description provided for @aiPlacesLine.
  ///
  /// In en, this message translates to:
  /// **'{engine} · {place} {rating} ({reviews} reviews) · {elapsed}'**
  String aiPlacesLine(
    String engine,
    String place,
    String rating,
    String reviews,
    String elapsed,
  );

  /// No description provided for @billOpen.
  ///
  /// In en, this message translates to:
  /// **'Check a bill'**
  String get billOpen;

  /// No description provided for @billStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Check a Thai bill'**
  String get billStartTitle;

  /// No description provided for @billStartBody.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the whole bill. Google Cloud Vision reads the Thai, then your phone checks that every figure adds up and shows what was added on top.'**
  String get billStartBody;

  /// No description provided for @billTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get billTake;

  /// No description provided for @billTakeAnother.
  ///
  /// In en, this message translates to:
  /// **'Another bill'**
  String get billTakeAnother;

  /// No description provided for @billChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get billChoose;

  /// No description provided for @billReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the bill'**
  String get billReading;

  /// No description provided for @billReadingBody.
  ///
  /// In en, this message translates to:
  /// **'{engine} is reading the Thai text. Your phone checks the figures next.'**
  String billReadingBody(String engine);

  /// No description provided for @billTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total on this bill'**
  String get billTotalLabel;

  /// No description provided for @billServiceChip.
  ///
  /// In en, this message translates to:
  /// **'Service charge added on top'**
  String get billServiceChip;

  /// No description provided for @billVatOnTopChip.
  ///
  /// In en, this message translates to:
  /// **'VAT added on top'**
  String get billVatOnTopChip;

  /// No description provided for @billVatInsideChip.
  ///
  /// In en, this message translates to:
  /// **'VAT already included'**
  String get billVatInsideChip;

  /// No description provided for @billNothingAddedChip.
  ///
  /// In en, this message translates to:
  /// **'Nothing added on top'**
  String get billNothingAddedChip;

  /// No description provided for @billHowBuilt.
  ///
  /// In en, this message translates to:
  /// **'How the total was built'**
  String get billHowBuilt;

  /// No description provided for @billInsideTotal.
  ///
  /// In en, this message translates to:
  /// **'Already inside the total'**
  String get billInsideTotal;

  /// No description provided for @billSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get billSubtotal;

  /// No description provided for @billItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String billItems(int count);

  /// No description provided for @billDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get billDiscount;

  /// No description provided for @billService.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get billService;

  /// No description provided for @billServicePercent.
  ///
  /// In en, this message translates to:
  /// **'Service charge {percent}%'**
  String billServicePercent(String percent);

  /// No description provided for @billVat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get billVat;

  /// No description provided for @billVatPercent.
  ///
  /// In en, this message translates to:
  /// **'VAT {percent}%'**
  String billVatPercent(String percent);

  /// No description provided for @billAddedOnTop.
  ///
  /// In en, this message translates to:
  /// **'Added on top'**
  String get billAddedOnTop;

  /// No description provided for @billAlreadyIncluded.
  ///
  /// In en, this message translates to:
  /// **'Already included, not extra'**
  String get billAlreadyIncluded;

  /// No description provided for @billTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get billTotal;

  /// No description provided for @billBeforeVat.
  ///
  /// In en, this message translates to:
  /// **'Before VAT'**
  String get billBeforeVat;

  /// No description provided for @billProof.
  ///
  /// In en, this message translates to:
  /// **'Every figure was checked against the others on this bill.'**
  String get billProof;

  /// No description provided for @billVisionTrace.
  ///
  /// In en, this message translates to:
  /// **'Read by {engine} · {lines} lines · {elapsed}'**
  String billVisionTrace(String engine, int lines, String elapsed);

  /// No description provided for @billOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get billOfflineTitle;

  /// No description provided for @billOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Reading Thai needs the internet. Connect and take the photo again.'**
  String get billOfflineBody;

  /// No description provided for @billTooLargeTitle.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large'**
  String get billTooLargeTitle;

  /// No description provided for @billTooLargeBody.
  ///
  /// In en, this message translates to:
  /// **'Take it again from this screen and a smaller copy is sent.'**
  String get billTooLargeBody;

  /// No description provided for @billNoTextTitle.
  ///
  /// In en, this message translates to:
  /// **'No text found'**
  String get billNoTextTitle;

  /// No description provided for @billNoTextBody.
  ///
  /// In en, this message translates to:
  /// **'Fill the frame with the bill, in good light, and try again.'**
  String get billNoTextBody;

  /// No description provided for @billNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify this bill'**
  String get billNoMatchTitle;

  /// No description provided for @billNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'The text was read, but its figures don\'t add up, so nothing is shown rather than a guess. Try a sharper photo of the whole bill.'**
  String get billNoMatchBody;

  /// No description provided for @billServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'The bill reader didn\'t answer'**
  String get billServiceTitle;

  /// No description provided for @billServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get billServiceBody;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'See which way to pay'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your trip records on any phone.'**
  String get authWelcomeBody;

  /// No description provided for @authContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueApple;

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @authContinueEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get authContinueEmail;

  /// No description provided for @authLookAround.
  ///
  /// In en, this message translates to:
  /// **'Look around without an account'**
  String get authLookAround;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateTitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name, if you like'**
  String get authNameLabel;

  /// No description provided for @authPasswordRule.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters'**
  String authPasswordRule(int min);

  /// No description provided for @authSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// No description provided for @authCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAction;

  /// No description provided for @authToCreate.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authToCreate;

  /// No description provided for @authToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Have an account? Sign in'**
  String get authToSignIn;

  /// No description provided for @authForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgot;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authConfirmTitle;

  /// No description provided for @authConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Tap it, then come back and sign in.'**
  String authConfirmBody(String email);

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// No description provided for @authResetIntro.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to set a new password. Open it on this phone.'**
  String get authResetIntro;

  /// No description provided for @authResetSend.
  ///
  /// In en, this message translates to:
  /// **'Email me a link'**
  String get authResetSend;

  /// No description provided for @authResetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authResetNewPassword;

  /// No description provided for @authResetSentTo.
  ///
  /// In en, this message translates to:
  /// **'Link sent to {email}. Open it on this phone to set a new password.'**
  String authResetSentTo(String email);

  /// No description provided for @authResetSave.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get authResetSave;

  /// No description provided for @authResetResend.
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get authResetResend;

  /// No description provided for @authErrEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authErrEmailEmpty;

  /// No description provided for @authErrEmailMalformed.
  ///
  /// In en, this message translates to:
  /// **'That email doesn\'t look right'**
  String get authErrEmailMalformed;

  /// No description provided for @authErrPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get authErrPasswordEmpty;

  /// No description provided for @authErrPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters'**
  String authErrPasswordShort(int min);

  /// No description provided for @authErrCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That link has expired. Ask for a new one.'**
  String get authErrCodeInvalid;

  /// No description provided for @authErrInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is wrong'**
  String get authErrInvalidCredentials;

  /// No description provided for @authErrEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Sign in instead.'**
  String get authErrEmailTaken;

  /// No description provided for @authErrEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first. The link is in your inbox.'**
  String get authErrEmailNotConfirmed;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a different, longer password'**
  String get authErrWeakPassword;

  /// No description provided for @authErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a minute, then try again.'**
  String get authErrRateLimited;

  /// No description provided for @authErrOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get authErrOffline;

  /// No description provided for @authErrNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This way of signing in isn\'t ready in this version.'**
  String get authErrNotConfigured;

  /// No description provided for @authErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Try again.'**
  String get authErrUnknown;

  /// No description provided for @authSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'About your trip'**
  String get authSetupTitle;

  /// No description provided for @authSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'So every amount shows in money you know.'**
  String get authSetupIntro;

  /// No description provided for @authSetupTypeHeader.
  ///
  /// In en, this message translates to:
  /// **'You are'**
  String get authSetupTypeHeader;

  /// No description provided for @authTypeVisitor.
  ///
  /// In en, this message translates to:
  /// **'Visiting Thailand'**
  String get authTypeVisitor;

  /// No description provided for @authTypeVisitorSub.
  ///
  /// In en, this message translates to:
  /// **'Paying in baht'**
  String get authTypeVisitorSub;

  /// No description provided for @authTypeThai.
  ///
  /// In en, this message translates to:
  /// **'Thai, travelling abroad'**
  String get authTypeThai;

  /// No description provided for @authTypeThaiSub.
  ///
  /// In en, this message translates to:
  /// **'Paying in other currencies'**
  String get authTypeThaiSub;

  /// No description provided for @authSetupMoneyHeader.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get authSetupMoneyHeader;

  /// No description provided for @authHomeCurrency.
  ///
  /// In en, this message translates to:
  /// **'You think in'**
  String get authHomeCurrency;

  /// No description provided for @authCardCurrency.
  ///
  /// In en, this message translates to:
  /// **'Your card bills in'**
  String get authCardCurrency;

  /// No description provided for @authSetupLanguageHeader.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get authSetupLanguageHeader;

  /// No description provided for @authLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get authLanguageEn;

  /// No description provided for @authLanguageTh.
  ///
  /// In en, this message translates to:
  /// **'ไทย'**
  String get authLanguageTh;

  /// No description provided for @authSetupFooter.
  ///
  /// In en, this message translates to:
  /// **'You can change these later in Settings.'**
  String get authSetupFooter;

  /// No description provided for @authSetupStart.
  ///
  /// In en, this message translates to:
  /// **'Start my trip'**
  String get authSetupStart;

  /// No description provided for @authSetupOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get authSetupOtherAccount;

  /// No description provided for @authAccountHeader.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get authAccountHeader;

  /// No description provided for @authGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get authGuestTitle;

  /// No description provided for @authGuestSub.
  ///
  /// In en, this message translates to:
  /// **'Records stay on this phone only'**
  String get authGuestSub;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get authDelete;

  /// No description provided for @authDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get authDeleteTitle;

  /// No description provided for @authDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile and saved records will be removed for good.'**
  String get authDeleteBody;

  /// No description provided for @authDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get authDeleteConfirm;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authCancel;

  /// No description provided for @politeEndingFemaleStatement.
  ///
  /// In en, this message translates to:
  /// **'ค่ะ'**
  String get politeEndingFemaleStatement;

  /// No description provided for @haggleNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Ask for this next'**
  String get haggleNextLabel;

  /// No description provided for @haggleDealLabel.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get haggleDealLabel;

  /// No description provided for @haggleDealAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} THB'**
  String haggleDealAmount(String amount);

  /// No description provided for @haggleAcceptSentence.
  ///
  /// In en, this message translates to:
  /// **'ตกลง {amount} บาท{ending}'**
  String haggleAcceptSentence(String amount, String ending);

  /// No description provided for @haggleStopLabel.
  ///
  /// In en, this message translates to:
  /// **'They won\'t go lower'**
  String get haggleStopLabel;

  /// No description provided for @haggleStopAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} THB or walk away'**
  String haggleStopAmount(String amount);

  /// No description provided for @haggleLeaveSentence.
  ///
  /// In en, this message translates to:
  /// **'ไม่เป็นไร ขอบคุณ{ending}'**
  String haggleLeaveSentence(String ending);

  /// No description provided for @haggleTheyAnswered.
  ///
  /// In en, this message translates to:
  /// **'What did they say?'**
  String get haggleTheyAnswered;

  /// No description provided for @haggleTheyAgreed.
  ///
  /// In en, this message translates to:
  /// **'They agreed'**
  String get haggleTheyAgreed;

  /// No description provided for @haggleTheySaidNo.
  ///
  /// In en, this message translates to:
  /// **'They said no'**
  String get haggleTheySaidNo;

  /// No description provided for @haggleTheyOffered.
  ///
  /// In en, this message translates to:
  /// **'New price'**
  String get haggleTheyOffered;

  /// No description provided for @haggleTheyOfferedPrice.
  ///
  /// In en, this message translates to:
  /// **'They offered {amount}'**
  String haggleTheyOfferedPrice(String amount);

  /// No description provided for @haggleUnclear.
  ///
  /// In en, this message translates to:
  /// **'Not clear, ask again'**
  String get haggleUnclear;

  /// No description provided for @haggleSoFar.
  ///
  /// In en, this message translates to:
  /// **'This haggle so far'**
  String get haggleSoFar;

  /// No description provided for @haggleFirstAsk.
  ///
  /// In en, this message translates to:
  /// **'They asked'**
  String get haggleFirstAsk;

  /// No description provided for @haggleYouOffered.
  ///
  /// In en, this message translates to:
  /// **'You offered'**
  String get haggleYouOffered;

  /// No description provided for @haggleYouAsk.
  ///
  /// In en, this message translates to:
  /// **'You ask {amount}'**
  String haggleYouAsk(String amount);

  /// No description provided for @haggleTheirLast.
  ///
  /// In en, this message translates to:
  /// **'Their last {amount}'**
  String haggleTheirLast(String amount);

  /// No description provided for @haggleTheyOfferedTitle.
  ///
  /// In en, this message translates to:
  /// **'What price did they say?'**
  String get haggleTheyOfferedTitle;

  /// No description provided for @haggleUsePrice.
  ///
  /// In en, this message translates to:
  /// **'Use this price'**
  String get haggleUsePrice;

  /// No description provided for @haggleNewPrice.
  ///
  /// In en, this message translates to:
  /// **'New price'**
  String get haggleNewPrice;

  /// No description provided for @haggleHearAnswer.
  ///
  /// In en, this message translates to:
  /// **'Hear their answer'**
  String get haggleHearAnswer;

  /// No description provided for @haggleListeningAnswer.
  ///
  /// In en, this message translates to:
  /// **'Listening for their answer'**
  String get haggleListeningAnswer;

  /// No description provided for @authNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get authNewPasswordTitle;

  /// No description provided for @saveTerminalTitle.
  ///
  /// In en, this message translates to:
  /// **'Paid in local currency at a card terminal'**
  String get saveTerminalTitle;

  /// No description provided for @dccKeepLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay in {currency} and keep'**
  String dccKeepLabel(String currency);

  /// No description provided for @dccMarkupChip.
  ///
  /// In en, this message translates to:
  /// **'{percent} markup avoided'**
  String dccMarkupChip(String percent);

  /// No description provided for @dccPressKey.
  ///
  /// In en, this message translates to:
  /// **'F{key} · pay in {currency}'**
  String dccPressKey(int key, String currency);

  /// No description provided for @dccReason.
  ///
  /// In en, this message translates to:
  /// **'The {home} price on this terminal is about {percent} above the bank rate.'**
  String dccReason(String home, String percent);

  /// No description provided for @dccBothOptions.
  ///
  /// In en, this message translates to:
  /// **'Both options on the terminal'**
  String get dccBothOptions;

  /// No description provided for @dccOptionKey.
  ///
  /// In en, this message translates to:
  /// **'F{key}'**
  String dccOptionKey(int key);

  /// No description provided for @dccOptionHome.
  ///
  /// In en, this message translates to:
  /// **'Your home currency'**
  String get dccOptionHome;

  /// No description provided for @dccOptionHomeMore.
  ///
  /// In en, this message translates to:
  /// **'Home currency · about {amount} more'**
  String dccOptionHomeMore(String amount);

  /// No description provided for @dccOptionLocal.
  ///
  /// In en, this message translates to:
  /// **'Local currency'**
  String get dccOptionLocal;

  /// No description provided for @dccFairHome.
  ///
  /// In en, this message translates to:
  /// **'Fair price in {currency}'**
  String dccFairHome(String currency);

  /// No description provided for @dccEvenTitle.
  ///
  /// In en, this message translates to:
  /// **'Either key is fine here'**
  String get dccEvenTitle;

  /// No description provided for @dccEvenBody.
  ///
  /// In en, this message translates to:
  /// **'Paying in your home currency costs no more than paying locally at today\'s rate.'**
  String get dccEvenBody;

  /// No description provided for @rateDemoSource.
  ///
  /// In en, this message translates to:
  /// **'{pair} · fixed demo rate, {date}'**
  String rateDemoSource(String pair, String date);

  /// No description provided for @boardRates.
  ///
  /// In en, this message translates to:
  /// **'{code} on this board'**
  String boardRates(String code);

  /// No description provided for @boardHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling {code} here, below the middle rate'**
  String boardHeroLabel(String code);

  /// No description provided for @boardLossChip.
  ///
  /// In en, this message translates to:
  /// **'About {loss} less per {amount}'**
  String boardLossChip(String loss, String amount);

  /// No description provided for @boardBuying.
  ///
  /// In en, this message translates to:
  /// **'They buy at'**
  String get boardBuying;

  /// No description provided for @boardBuyingHint.
  ///
  /// In en, this message translates to:
  /// **'What you get for each {code}'**
  String boardBuyingHint(String code);

  /// No description provided for @boardSelling.
  ///
  /// In en, this message translates to:
  /// **'They sell at'**
  String get boardSelling;

  /// No description provided for @boardMid.
  ///
  /// In en, this message translates to:
  /// **'Middle rate'**
  String get boardMid;

  /// No description provided for @boardSource.
  ///
  /// In en, this message translates to:
  /// **'From the numbers on this board'**
  String get boardSource;

  /// No description provided for @boardVsReference.
  ///
  /// In en, this message translates to:
  /// **'Buying rate about {percent} below {source}'**
  String boardVsReference(String percent, String source);

  /// No description provided for @boardAboveReference.
  ///
  /// In en, this message translates to:
  /// **'Buying rate about {percent} above {source}'**
  String boardAboveReference(String percent, String source);

  /// No description provided for @stepFindTerminalDone.
  ///
  /// In en, this message translates to:
  /// **'Two-currency card terminal found'**
  String get stepFindTerminalDone;

  /// No description provided for @stepFindBoardDone.
  ///
  /// In en, this message translates to:
  /// **'Exchange rate board found'**
  String get stepFindBoardDone;

  /// No description provided for @stepCompareDcc.
  ///
  /// In en, this message translates to:
  /// **'Paying locally keeps about {amount}'**
  String stepCompareDcc(String amount);

  /// No description provided for @stepCompareBoard.
  ///
  /// In en, this message translates to:
  /// **'About {percent} below the middle rate'**
  String stepCompareBoard(String percent);

  /// No description provided for @settingsDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get settingsDemo;

  /// No description provided for @settingsDemoFooter.
  ///
  /// In en, this message translates to:
  /// **'For presenting. Language, currency and records change together, with fixed rates. Your own records are kept and come back when you turn it off.'**
  String get settingsDemoFooter;

  /// No description provided for @billCheckedTrace.
  ///
  /// In en, this message translates to:
  /// **'Figures checked on this phone · {elapsed}'**
  String billCheckedTrace(String elapsed);

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get authSigningIn;

  /// No description provided for @authErrTryAgain.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Try again.'**
  String get authErrTryAgain;

  /// No description provided for @authErrEmailRejected.
  ///
  /// In en, this message translates to:
  /// **'This email can\'t be used. Try another one.'**
  String get authErrEmailRejected;

  /// No description provided for @authErrEmailUndeliverable.
  ///
  /// In en, this message translates to:
  /// **'We can\'t send email to this address yet.'**
  String get authErrEmailUndeliverable;

  /// No description provided for @billTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'That took too long'**
  String get billTimeoutTitle;

  /// No description provided for @billTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'The connection may be slow. Try again in a moment.'**
  String get billTimeoutBody;

  /// No description provided for @scanKindLine.
  ///
  /// In en, this message translates to:
  /// **'{engine} sees {kind} ({confidence}) · {elapsed}'**
  String scanKindLine(
    String engine,
    String kind,
    String confidence,
    String elapsed,
  );

  /// No description provided for @scanCheckAsBill.
  ///
  /// In en, this message translates to:
  /// **'Check it as a bill'**
  String get scanCheckAsBill;

  /// No description provided for @kindAtm.
  ///
  /// In en, this message translates to:
  /// **'an ATM screen'**
  String get kindAtm;

  /// No description provided for @kindTerminal.
  ///
  /// In en, this message translates to:
  /// **'a card terminal'**
  String get kindTerminal;

  /// No description provided for @kindBill.
  ///
  /// In en, this message translates to:
  /// **'a bill or menu'**
  String get kindBill;

  /// No description provided for @kindPriceTag.
  ///
  /// In en, this message translates to:
  /// **'a price tag'**
  String get kindPriceTag;

  /// No description provided for @kindOther.
  ///
  /// In en, this message translates to:
  /// **'something else'**
  String get kindOther;

  /// No description provided for @demoLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demoLabel;

  /// No description provided for @demoVisitorBangkok.
  ///
  /// In en, this message translates to:
  /// **'US visitor in Bangkok'**
  String get demoVisitorBangkok;

  /// No description provided for @demoThaiTokyo.
  ///
  /// In en, this message translates to:
  /// **'Thai traveler in Tokyo'**
  String get demoThaiTokyo;

  /// No description provided for @demoPersonaDetail.
  ///
  /// In en, this message translates to:
  /// **'{language} · {currency}'**
  String demoPersonaDetail(String language, String currency);

  /// No description provided for @demoPill.
  ///
  /// In en, this message translates to:
  /// **'Demo · {name}'**
  String demoPill(String name);

  /// No description provided for @demoSwitchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch to {name}'**
  String demoSwitchTo(String name);

  /// No description provided for @settingsDemoOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsDemoOff;

  /// No description provided for @settingsDemoOffHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s rates and your own records'**
  String get settingsDemoOffHint;

  /// No description provided for @settingsDemoPersonaHint.
  ///
  /// In en, this message translates to:
  /// **'{detail} · fixed rates, sample records'**
  String settingsDemoPersonaHint(String detail);

  /// No description provided for @saveSampleWhen.
  ///
  /// In en, this message translates to:
  /// **'Sample · {when}'**
  String saveSampleWhen(String when);

  /// No description provided for @homeRateDemo.
  ///
  /// In en, this message translates to:
  /// **'{pair} · fixed demo rate, {date}'**
  String homeRateDemo(String pair, String date);

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeCashToday.
  ///
  /// In en, this message translates to:
  /// **'About {amount} in cash today'**
  String homeCashToday(String amount);

  /// No description provided for @homeCashBasis.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Estimate from 1 of your records over the last {days} days} other{Estimate from {count} of your records over the last {days} days}}'**
  String homeCashBasis(int days, int count);

  /// No description provided for @homeCashBasisSamples.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Estimate from 1 sample record over {days} days} other{Estimate from {count} sample records over {days} days}}'**
  String homeCashBasisSamples(int days, int count);

  /// No description provided for @homeCashBasisMixed.
  ///
  /// In en, this message translates to:
  /// **'Estimate from {count} records over the last {days} days, {samples} of them samples'**
  String homeCashBasisMixed(int days, int count, int samples);

  /// No description provided for @memoryDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{today} =1{yesterday} other{{days} days ago}}'**
  String memoryDaysAgo(int days);

  /// No description provided for @memoryPaidHere.
  ///
  /// In en, this message translates to:
  /// **'You paid {amount} here {when}'**
  String memoryPaidHere(String amount, String when);

  /// No description provided for @memoryPaidAt.
  ///
  /// In en, this message translates to:
  /// **'You paid {amount} at {place} {when}'**
  String memoryPaidAt(String amount, String place, String when);

  /// No description provided for @memoryPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid {amount} {when}'**
  String memoryPaid(String amount, String when);

  /// No description provided for @memoryFromRecords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{from your 1 past record} other{from your {count} past records}}'**
  String memoryFromRecords(int count);

  /// No description provided for @memoryFromSamples.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{from 1 sample record} other{from {count} sample records}}'**
  String memoryFromSamples(int count);

  /// No description provided for @memoryFromMixed.
  ///
  /// In en, this message translates to:
  /// **'from {count} past records, {samples} of them samples'**
  String memoryFromMixed(int count, int samples);

  /// No description provided for @memoryLine.
  ///
  /// In en, this message translates to:
  /// **'{fact} · {basis}'**
  String memoryLine(String fact, String basis);

  /// No description provided for @memoryCounterRow.
  ///
  /// In en, this message translates to:
  /// **'Your past haggles'**
  String get memoryCounterRow;

  /// No description provided for @memoryAbout.
  ///
  /// In en, this message translates to:
  /// **'About {amount}'**
  String memoryAbout(String amount);

  /// No description provided for @authWelcomeExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get authWelcomeExample;

  /// No description provided for @authWelcomeExampleLabel.
  ///
  /// In en, this message translates to:
  /// **'The ATM\'s conversion would have added'**
  String get authWelcomeExampleLabel;

  /// No description provided for @authWelcomeExampleChip.
  ///
  /// In en, this message translates to:
  /// **'Kept by choosing no conversion'**
  String get authWelcomeExampleChip;

  /// No description provided for @authWelcomeExampleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Example. The ATM\'s conversion would have cost {amount} more. Choosing no conversion kept it.'**
  String authWelcomeExampleSemantics(String amount);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsCredits.
  ///
  /// In en, this message translates to:
  /// **'Photo credits'**
  String get settingsCredits;

  /// No description provided for @creditsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The credits list could not be read'**
  String get creditsUnavailable;

  /// No description provided for @settingsCreditsHint.
  ///
  /// In en, this message translates to:
  /// **'{count} photos that taught the app to tell photos apart'**
  String settingsCreditsHint(int count);

  /// No description provided for @creditsRow.
  ///
  /// In en, this message translates to:
  /// **'{author} · {license}'**
  String creditsRow(String author, String license);

  /// No description provided for @creditsFooter.
  ///
  /// In en, this message translates to:
  /// **'These photos from Wikimedia Commons trained the on-device model that tells an ATM screen, a card terminal, a rate board and a receipt apart. Each is used under the licence shown, with its author.'**
  String get creditsFooter;

  /// No description provided for @aiWordedBy.
  ///
  /// In en, this message translates to:
  /// **'Worded by {engine} from the figures above · {elapsed}'**
  String aiWordedBy(String engine, String elapsed);

  /// No description provided for @memoryDiscount.
  ///
  /// In en, this message translates to:
  /// **'About {percent} % off the first price'**
  String memoryDiscount(String percent);

  /// No description provided for @homeKeptSamples.
  ///
  /// In en, this message translates to:
  /// **'Includes sample records'**
  String get homeKeptSamples;

  /// No description provided for @priceSentenceHigh.
  ///
  /// In en, this message translates to:
  /// **'{asked} is {over} above the usual top price, about {percent}'**
  String priceSentenceHigh(String asked, String over, String percent);

  /// No description provided for @priceSentenceFair.
  ///
  /// In en, this message translates to:
  /// **'{asked} is inside the usual price'**
  String priceSentenceFair(String asked);

  /// No description provided for @priceSentenceLow.
  ///
  /// In en, this message translates to:
  /// **'{asked} is below the usual price, a good buy'**
  String priceSentenceLow(String asked);

  /// No description provided for @priceAsked.
  ///
  /// In en, this message translates to:
  /// **'Asked {amount}'**
  String priceAsked(String amount);

  /// No description provided for @priceYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid {amount}'**
  String priceYouPaid(String amount);

  /// No description provided for @priceZoneCheap.
  ///
  /// In en, this message translates to:
  /// **'Cheap'**
  String get priceZoneCheap;

  /// No description provided for @priceZoneUsual.
  ///
  /// In en, this message translates to:
  /// **'Usual {unit}'**
  String priceZoneUsual(String unit);

  /// No description provided for @priceZoneHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priceZoneHigh;

  /// No description provided for @priceZoneFarAbove.
  ///
  /// In en, this message translates to:
  /// **'Far above'**
  String get priceZoneFarAbove;

  /// No description provided for @priceZoneFarBelow.
  ///
  /// In en, this message translates to:
  /// **'Far below'**
  String get priceZoneFarBelow;

  /// No description provided for @priceSemanticsRange.
  ///
  /// In en, this message translates to:
  /// **'Usual price {low} to {high} baht {unit}'**
  String priceSemanticsRange(String low, String high, String unit);

  /// No description provided for @priceSemanticsCounter.
  ///
  /// In en, this message translates to:
  /// **'Suggested offer {amount}'**
  String priceSemanticsCounter(String amount);

  /// No description provided for @haggleShowSeller.
  ///
  /// In en, this message translates to:
  /// **'Show the seller'**
  String get haggleShowSeller;

  /// No description provided for @showSellerTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn to the seller'**
  String get showSellerTurn;

  /// No description provided for @showSellerTurnBack.
  ///
  /// In en, this message translates to:
  /// **'Turn back to me'**
  String get showSellerTurnBack;

  /// No description provided for @showSellerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get showSellerClose;

  /// No description provided for @showSellerAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} บาท'**
  String showSellerAmount(String amount);

  /// No description provided for @haggleOfferMeaning.
  ///
  /// In en, this message translates to:
  /// **'Could you do {amount} baht?'**
  String haggleOfferMeaning(String amount);

  /// No description provided for @haggleAcceptMeaning.
  ///
  /// In en, this message translates to:
  /// **'OK, {amount} baht. It\'s a deal.'**
  String haggleAcceptMeaning(String amount);

  /// No description provided for @haggleLeaveMeaning.
  ///
  /// In en, this message translates to:
  /// **'No thanks, maybe another time.'**
  String get haggleLeaveMeaning;

  /// No description provided for @billShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get billShop;

  /// No description provided for @billShopUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not read'**
  String get billShopUnknown;

  /// No description provided for @billYourRecord.
  ///
  /// In en, this message translates to:
  /// **'Your record'**
  String get billYourRecord;

  /// No description provided for @billSave.
  ///
  /// In en, this message translates to:
  /// **'Save to my records'**
  String get billSave;

  /// No description provided for @billSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get billSaved;

  /// No description provided for @billEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get billEdit;

  /// No description provided for @billEnterIt.
  ///
  /// In en, this message translates to:
  /// **'Enter it yourself'**
  String get billEnterIt;

  /// No description provided for @billEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Your version of this bill'**
  String get billEditTitle;

  /// No description provided for @billServiceNone.
  ///
  /// In en, this message translates to:
  /// **'No service charge'**
  String get billServiceNone;

  /// No description provided for @billServiceIncludedChoice.
  ///
  /// In en, this message translates to:
  /// **'Service included'**
  String get billServiceIncludedChoice;

  /// No description provided for @billServicePercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get billServicePercentLabel;

  /// No description provided for @billUseCorrection.
  ///
  /// In en, this message translates to:
  /// **'Use these figures'**
  String get billUseCorrection;

  /// No description provided for @billCorrectedNote.
  ///
  /// In en, this message translates to:
  /// **'Your correction. It is saved as yours, not as checked by the app.'**
  String get billCorrectedNote;

  /// No description provided for @billMemoryVisits.
  ///
  /// In en, this message translates to:
  /// **'{visits, plural, =1{You saved 1 bill here before. Last time {total}} other{You saved {visits} bills here before. Last time {total}}}'**
  String billMemoryVisits(int visits, String total);

  /// No description provided for @billMemoryNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last time here you noted {note}} other{In {count} earlier bills here you noted {note}}}'**
  String billMemoryNote(String note, int count);

  /// No description provided for @billNoteServiceIncluded.
  ///
  /// In en, this message translates to:
  /// **'service was included'**
  String get billNoteServiceIncluded;

  /// No description provided for @billNoteServiceAdded.
  ///
  /// In en, this message translates to:
  /// **'service {percent} % was added'**
  String billNoteServiceAdded(String percent);

  /// No description provided for @billNoteNoService.
  ///
  /// In en, this message translates to:
  /// **'no service charge'**
  String get billNoteNoService;

  /// No description provided for @tabAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get tabAssistant;

  /// No description provided for @homeRouteNext.
  ///
  /// In en, this message translates to:
  /// **'Next stop'**
  String get homeRouteNext;

  /// No description provided for @homeRouteAtm.
  ///
  /// In en, this message translates to:
  /// **'ATM'**
  String get homeRouteAtm;

  /// No description provided for @homeRouteMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get homeRouteMarket;

  /// No description provided for @homeRouteTerminal.
  ///
  /// In en, this message translates to:
  /// **'Card terminal'**
  String get homeRouteTerminal;

  /// No description provided for @homeBriefingLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning briefing'**
  String get homeBriefingLabel;

  /// No description provided for @homeBriefingOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the assistant'**
  String get homeBriefingOpen;

  /// No description provided for @homeBriefingNoNumber.
  ///
  /// In en, this message translates to:
  /// **'Today\'s cash estimate goes here'**
  String get homeBriefingNoNumber;

  /// No description provided for @homeBriefingStops.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop on your calendar today} other{{count} stops on your calendar today}}'**
  String homeBriefingStops(int count);

  /// No description provided for @homeBriefingMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more stop} other{{count} more stops}}'**
  String homeBriefingMore(int count);

  /// No description provided for @nearbyLabel.
  ///
  /// In en, this message translates to:
  /// **'Watch out nearby'**
  String get nearbyLabel;

  /// No description provided for @nearbyOpen.
  ///
  /// In en, this message translates to:
  /// **'See every warning nearby'**
  String get nearbyOpen;

  /// No description provided for @nearbyMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more warning nearby} other{{count} more warnings nearby}}'**
  String nearbyMore(int count);

  /// No description provided for @nearbyNeedLocation.
  ///
  /// In en, this message translates to:
  /// **'See money traps near you'**
  String get nearbyNeedLocation;

  /// No description provided for @nearbyLocationPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Uses your location only while the app is open'**
  String get nearbyLocationPrivacy;

  /// No description provided for @nearbyLooking.
  ///
  /// In en, this message translates to:
  /// **'Checking ATMs and markets nearby'**
  String get nearbyLooking;

  /// No description provided for @nearbyClear.
  ///
  /// In en, this message translates to:
  /// **'Nothing to watch out for nearby'**
  String get nearbyClear;

  /// No description provided for @nearbyClearBasis.
  ///
  /// In en, this message translates to:
  /// **'From ATMs and markets Google Maps lists near you'**
  String get nearbyClearBasis;

  /// No description provided for @trapAtmFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Foreign cards pay a fee at ATMs here'**
  String get trapAtmFeeTitle;

  /// No description provided for @trapAtmFeeBody.
  ///
  /// In en, this message translates to:
  /// **'For example {fee} at {where}. Other banks differ, so take out more at once.'**
  String trapAtmFeeBody(String fee, String where);

  /// No description provided for @trapAtmConversionTitle.
  ///
  /// In en, this message translates to:
  /// **'ATMs here may offer to convert'**
  String get trapAtmConversionTitle;

  /// No description provided for @trapAtmConversionBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the local currency, not your own'**
  String get trapAtmConversionBody;

  /// No description provided for @trapCashOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash only'**
  String get trapCashOnlyTitle;

  /// No description provided for @trapCashOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Bring cash before you go'**
  String get trapCashOnlyBody;

  /// No description provided for @briefingCashOnly.
  ///
  /// In en, this message translates to:
  /// **'Cash only'**
  String get briefingCashOnly;

  /// No description provided for @briefingCardsOk.
  ///
  /// In en, this message translates to:
  /// **'Takes cards'**
  String get briefingCardsOk;

  /// No description provided for @briefingPayUnknown.
  ///
  /// In en, this message translates to:
  /// **'Payment not listed on Google Maps'**
  String get briefingPayUnknown;

  /// No description provided for @briefingLastSpent.
  ///
  /// In en, this message translates to:
  /// **'You spent {amount} here last time'**
  String briefingLastSpent(String amount);

  /// No description provided for @briefingLastSpentSample.
  ///
  /// In en, this message translates to:
  /// **'Sample record · {amount} here last time'**
  String briefingLastSpentSample(String amount);

  /// No description provided for @briefingPlaceDistance.
  ///
  /// In en, this message translates to:
  /// **'{place} · {meters} m'**
  String briefingPlaceDistance(String place, String meters);

  /// No description provided for @briefingSourceLive.
  ///
  /// In en, this message translates to:
  /// **'{source} · live'**
  String briefingSourceLive(String source);

  /// No description provided for @briefingSourceChecked.
  ///
  /// In en, this message translates to:
  /// **'{source} · checked {date}'**
  String briefingSourceChecked(String source, String date);

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantCashLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash for today'**
  String get assistantCashLabel;

  /// No description provided for @assistantCashAbout.
  ///
  /// In en, this message translates to:
  /// **'About {amount}'**
  String assistantCashAbout(String amount);

  /// No description provided for @assistantCashUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not enough to go on yet'**
  String get assistantCashUnknown;

  /// No description provided for @assistantStops.
  ///
  /// In en, this message translates to:
  /// **'Today\'s stops'**
  String get assistantStops;

  /// No description provided for @assistantPay.
  ///
  /// In en, this message translates to:
  /// **'Card, cash or QR'**
  String get assistantPay;

  /// No description provided for @assistantPayFor.
  ///
  /// In en, this message translates to:
  /// **'Compared for {place}'**
  String assistantPayFor(String place);

  /// No description provided for @assistantCard.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get assistantCard;

  /// No description provided for @assistantCardFooter.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. Your bank\'s fee page has these numbers.'**
  String get assistantCardFooter;

  /// No description provided for @assistantCardFromAccount.
  ///
  /// In en, this message translates to:
  /// **'Card fee from your account profile'**
  String get assistantCardFromAccount;

  /// No description provided for @assistantNearby.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get assistantNearby;

  /// No description provided for @assistantArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival alert'**
  String get assistantArrival;

  /// No description provided for @cashBasisNone.
  ///
  /// In en, this message translates to:
  /// **'Needs a day or two of saved spending'**
  String get cashBasisNone;

  /// No description provided for @cashBasisPattern.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{From your spending on 1 earlier day} other{From your spending on {days} earlier days}}'**
  String cashBasisPattern(int days);

  /// No description provided for @cashBasisPatternSamples.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{From sample records on 1 day} other{From sample records on {days} days}}'**
  String cashBasisPatternSamples(int days);

  /// No description provided for @cashBasisCashOnly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stop takes cash only (Google Maps)} other{{count} stops take cash only (Google Maps)}}'**
  String cashBasisCashOnly(int count);

  /// No description provided for @cashBasisLastVisit.
  ///
  /// In en, this message translates to:
  /// **'includes what you spent there last time'**
  String get cashBasisLastVisit;

  /// No description provided for @calendarConnect.
  ///
  /// In en, this message translates to:
  /// **'Read today\'s calendar'**
  String get calendarConnect;

  /// No description provided for @calendarDenied.
  ///
  /// In en, this message translates to:
  /// **'Calendar access is off in Settings'**
  String get calendarDenied;

  /// No description provided for @calendarPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Title, place and time only. Nothing is changed.'**
  String get calendarPrivacy;

  /// No description provided for @calendarReading.
  ///
  /// In en, this message translates to:
  /// **'Reading today\'s calendar'**
  String get calendarReading;

  /// No description provided for @calendarNoStops.
  ///
  /// In en, this message translates to:
  /// **'No stops with a place on your calendar today'**
  String get calendarNoStops;

  /// No description provided for @payCompareLabel.
  ///
  /// In en, this message translates to:
  /// **'Cheapest way to pay'**
  String get payCompareLabel;

  /// No description provided for @payCompareAsk.
  ///
  /// In en, this message translates to:
  /// **'Type an amount to compare'**
  String get payCompareAsk;

  /// No description provided for @payCompareAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get payCompareAmountHint;

  /// No description provided for @payCompareBestCard.
  ///
  /// In en, this message translates to:
  /// **'Pay by card'**
  String get payCompareBestCard;

  /// No description provided for @payCompareBestCash.
  ///
  /// In en, this message translates to:
  /// **'Pay in cash'**
  String get payCompareBestCash;

  /// No description provided for @payCompareBestQr.
  ///
  /// In en, this message translates to:
  /// **'Pay by QR'**
  String get payCompareBestQr;

  /// No description provided for @payCompareSame.
  ///
  /// In en, this message translates to:
  /// **'Card and cash cost about the same'**
  String get payCompareSame;

  /// No description provided for @payCompareCashOnly.
  ///
  /// In en, this message translates to:
  /// **'Cash only here'**
  String get payCompareCashOnly;

  /// No description provided for @payCompareNeedCard.
  ///
  /// In en, this message translates to:
  /// **'Add your card\'s foreign fee to compare'**
  String get payCompareNeedCard;

  /// No description provided for @payCompareNeedWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Cash depends on how much you take out at once'**
  String get payCompareNeedWithdrawal;

  /// No description provided for @payCompareNoRate.
  ///
  /// In en, this message translates to:
  /// **'Waiting for today\'s {currency} rate'**
  String payCompareNoRate(String currency);

  /// No description provided for @payCompareBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Cash costs less than the card only when you take out {amount} or more at once'**
  String payCompareBreakEven(String amount);

  /// No description provided for @payCompareAtmFeeSource.
  ///
  /// In en, this message translates to:
  /// **'Cash priced with a {fee} ATM fee ({source}). Other banks differ.'**
  String payCompareAtmFeeSource(String fee, String source);

  /// No description provided for @payCompareNoAtmFee.
  ///
  /// In en, this message translates to:
  /// **'No published ATM fee for foreign cards here, so cash is not priced'**
  String get payCompareNoAtmFee;

  /// No description provided for @payCompareDemoRate.
  ///
  /// In en, this message translates to:
  /// **'fixed demo rate'**
  String get payCompareDemoRate;

  /// No description provided for @payCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payCard;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash from an ATM'**
  String get payCash;

  /// No description provided for @payQr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get payQr;

  /// No description provided for @payExtra.
  ///
  /// In en, this message translates to:
  /// **'+{amount}'**
  String payExtra(String amount);

  /// No description provided for @payNotTaken.
  ///
  /// In en, this message translates to:
  /// **'Not taken here'**
  String get payNotTaken;

  /// No description provided for @payNeedCardFee.
  ///
  /// In en, this message translates to:
  /// **'Add your card fee'**
  String get payNeedCardFee;

  /// No description provided for @payNeedWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Depends on the withdrawal'**
  String get payNeedWithdrawal;

  /// No description provided for @payNoQrFee.
  ///
  /// In en, this message translates to:
  /// **'No published fee'**
  String get payNoQrFee;

  /// No description provided for @cardFeeRow.
  ///
  /// In en, this message translates to:
  /// **'Foreign transaction fee'**
  String get cardFeeRow;

  /// No description provided for @cardFeeMissing.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get cardFeeMissing;

  /// No description provided for @cardAtmRow.
  ///
  /// In en, this message translates to:
  /// **'Your bank at foreign ATMs'**
  String get cardAtmRow;

  /// No description provided for @cardAtmUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get cardAtmUnknown;

  /// No description provided for @cardAtmNoFee.
  ///
  /// In en, this message translates to:
  /// **'No fee'**
  String get cardAtmNoFee;

  /// No description provided for @cardAtmRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds ATM fees'**
  String get cardAtmRefunds;

  /// No description provided for @cardAtmFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed fee in {currency}'**
  String cardAtmFixed(String currency);

  /// No description provided for @cardAtmPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent of the withdrawal'**
  String get cardAtmPercent;

  /// No description provided for @cardAtmFixedValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} each time'**
  String cardAtmFixedValue(String amount);

  /// No description provided for @cardAtmPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{percent} of each withdrawal'**
  String cardAtmPercentValue(String percent);

  /// No description provided for @cardSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your card'**
  String get cardSheetTitle;

  /// No description provided for @cardFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Foreign transaction fee'**
  String get cardFeeLabel;

  /// No description provided for @cardFeeHintThai.
  ///
  /// In en, this message translates to:
  /// **'Thai banks publish up to 2.5% (Kasikorn, ttb fee lists 2025-2026)'**
  String get cardFeeHintThai;

  /// No description provided for @cardFeeHintOther.
  ///
  /// In en, this message translates to:
  /// **'Your card\'s terms list the exact fee.'**
  String get cardFeeHintOther;

  /// No description provided for @cardAtmLabel.
  ///
  /// In en, this message translates to:
  /// **'What your bank charges at a foreign ATM'**
  String get cardAtmLabel;

  /// No description provided for @cardFeeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a number from 0 to 20'**
  String get cardFeeInvalid;

  /// No description provided for @cardAtmValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Add the fee amount'**
  String get cardAtmValueInvalid;

  /// No description provided for @cardSheetPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only these numbers are kept. Never your card number.'**
  String get cardSheetPrivacy;

  /// No description provided for @cardSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save card facts'**
  String get cardSheetSave;

  /// No description provided for @arrivalOn.
  ///
  /// In en, this message translates to:
  /// **'On for your next arrival'**
  String get arrivalOn;

  /// No description provided for @arrivalOnBody.
  ///
  /// In en, this message translates to:
  /// **'When your phone lands in a country with another currency, you get one alert on which currency to pick'**
  String get arrivalOnBody;

  /// No description provided for @arrivalAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get arrivalAllow;

  /// No description provided for @arrivalBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off in Settings'**
  String get arrivalBlocked;

  /// No description provided for @arrivalDemoTrigger.
  ///
  /// In en, this message translates to:
  /// **'Demo · Land in Japan'**
  String get arrivalDemoTrigger;

  /// No description provided for @arrivalDemoFooter.
  ///
  /// In en, this message translates to:
  /// **'Demo state only. Shows the same alert your phone\'s location would.'**
  String get arrivalDemoFooter;

  /// No description provided for @arrivalShownDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo · {body}'**
  String arrivalShownDemo(String body);

  /// No description provided for @arrivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Landed in {country}'**
  String arrivalTitle(String country);

  /// No description provided for @arrivalBody.
  ///
  /// In en, this message translates to:
  /// **'If a card machine asks {home} or {local}, pick {local}'**
  String arrivalBody(String local, String home);

  /// No description provided for @arrivalBodyAtm.
  ///
  /// In en, this message translates to:
  /// **'If a card machine or ATM asks {home} or {local}, pick {local}'**
  String arrivalBodyAtm(String local, String home);

  /// No description provided for @arrivalChannel.
  ///
  /// In en, this message translates to:
  /// **'Arrival alerts'**
  String get arrivalChannel;

  /// No description provided for @countryJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get countryJapan;

  /// No description provided for @countryThailand.
  ///
  /// In en, this message translates to:
  /// **'Thailand'**
  String get countryThailand;

  /// No description provided for @billMemoryNoteBranch.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{At another branch you noted {note}} other{At other branches you noted {note} in {count} bills}}'**
  String billMemoryNoteBranch(String note, int count);

  /// No description provided for @billBrandMemory.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Another branch of this shop had {habit} (1 receipt)} other{Other branches of this shop had {habit} ({count} receipts)}}'**
  String billBrandMemory(String habit, int count);

  /// No description provided for @billBrandServiceAdded.
  ///
  /// In en, this message translates to:
  /// **'service charge added'**
  String get billBrandServiceAdded;

  /// No description provided for @tripMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip map'**
  String get tripMapTitle;

  /// No description provided for @tripMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Receipts and haggles you save with a place show up here.'**
  String get tripMapEmpty;

  /// No description provided for @tripMapKeptDay.
  ///
  /// In en, this message translates to:
  /// **'Kept {amount}'**
  String tripMapKeptDay(String amount);

  /// No description provided for @tripMapKept.
  ///
  /// In en, this message translates to:
  /// **'Kept {amount}'**
  String tripMapKept(String amount);

  /// No description provided for @tripMapSample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get tripMapSample;

  /// No description provided for @tripMapCorrected.
  ///
  /// In en, this message translates to:
  /// **'Your correction'**
  String get tripMapCorrected;

  /// No description provided for @tripMapKindReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get tripMapKindReceipt;

  /// No description provided for @tripMapKindHaggle.
  ///
  /// In en, this message translates to:
  /// **'Haggle'**
  String get tripMapKindHaggle;

  /// No description provided for @tripMapKindAtm.
  ///
  /// In en, this message translates to:
  /// **'ATM'**
  String get tripMapKindAtm;

  /// No description provided for @tripMapKindTerminal.
  ///
  /// In en, this message translates to:
  /// **'Card terminal'**
  String get tripMapKindTerminal;

  /// No description provided for @tripMapKeptAt.
  ///
  /// In en, this message translates to:
  /// **'Kept at {count, plural, =1{1 place} other{{count} places}}'**
  String tripMapKeptAt(int count);

  /// No description provided for @tripMapOnMap.
  ///
  /// In en, this message translates to:
  /// **'On the map'**
  String get tripMapOnMap;

  /// No description provided for @tripMapPlaces.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String tripMapPlaces(int count);

  /// No description provided for @tripMapToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tripMapToday;

  /// No description provided for @tripMapYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get tripMapYesterday;

  /// No description provided for @tripMapPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String tripMapPaid(String amount);

  /// No description provided for @tripMapClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get tripMapClose;

  /// No description provided for @tripMapOffline.
  ///
  /// In en, this message translates to:
  /// **'The map needs a connection. Every place is still listed below.'**
  String get tripMapOffline;

  /// No description provided for @tripMapEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt'**
  String get tripMapEmptyAction;

  /// No description provided for @tripMapMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map with {count, plural, =1{1 place} other{{count} places}}. Each one is also in the list below.'**
  String tripMapMapLabel(int count);

  /// No description provided for @tripMapShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Shows it on the map'**
  String get tripMapShowOnMap;

  /// No description provided for @tripMapNear.
  ///
  /// In en, this message translates to:
  /// **'Near {place}'**
  String tripMapNear(String place);

  /// No description provided for @billTotalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a total above 0 and up to {max}'**
  String billTotalInvalid(String max);

  /// No description provided for @trapAtmFeeBodyPlain.
  ///
  /// In en, this message translates to:
  /// **'For example {fee} per withdrawal. Take out more at once.'**
  String trapAtmFeeBodyPlain(String fee);

  /// No description provided for @arrivalOff.
  ///
  /// In en, this message translates to:
  /// **'Off until notifications are allowed'**
  String get arrivalOff;

  /// No description provided for @nearbyDemoOff.
  ///
  /// In en, this message translates to:
  /// **'Off in the demo state'**
  String get nearbyDemoOff;

  /// No description provided for @nearbyDemoOffBody.
  ///
  /// In en, this message translates to:
  /// **'Warnings nearby come from where your phone really is'**
  String get nearbyDemoOffBody;

  /// No description provided for @payCompareNeedBank.
  ///
  /// In en, this message translates to:
  /// **'Add what your bank charges at foreign ATMs to compare with cash'**
  String get payCompareNeedBank;

  /// No description provided for @payCompareWithdrawalAssumed.
  ///
  /// In en, this message translates to:
  /// **'Cash assumes you take out just this amount'**
  String get payCompareWithdrawalAssumed;

  /// No description provided for @payCompareWithdrawalPlan.
  ///
  /// In en, this message translates to:
  /// **'Cash assumes one withdrawal of about {amount}, today\'s estimate'**
  String payCompareWithdrawalPlan(String amount);

  /// No description provided for @aiHeardBy.
  ///
  /// In en, this message translates to:
  /// **'Heard by {engine} · {elapsed}'**
  String aiHeardBy(String engine, String elapsed);

  /// No description provided for @speakWordsAfter.
  ///
  /// In en, this message translates to:
  /// **'Their words appear when they finish'**
  String get speakWordsAfter;

  /// No description provided for @speakReading.
  ///
  /// In en, this message translates to:
  /// **'Reading what they said'**
  String get speakReading;

  /// No description provided for @assistantFacts.
  ///
  /// In en, this message translates to:
  /// **'Facts checked online'**
  String get assistantFacts;

  /// No description provided for @factsSummary.
  ///
  /// In en, this message translates to:
  /// **'{checked} checked today · {updated} updated · {unchanged} unchanged · {kept} kept'**
  String factsSummary(int checked, int updated, int unchanged, int kept);

  /// No description provided for @factsNotToday.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet today'**
  String get factsNotToday;

  /// No description provided for @factsOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline, showing the copy from {date}'**
  String factsOffline(String date);

  /// No description provided for @factsFooter.
  ///
  /// In en, this message translates to:
  /// **'Gemini reads each page once a day. A figure is used only when its sentence appears word for word on that page.'**
  String get factsFooter;

  /// No description provided for @factThAtmVisa.
  ///
  /// In en, this message translates to:
  /// **'ATM fee, Kasikorn K-ATM, Visa'**
  String get factThAtmVisa;

  /// No description provided for @factThAtmMastercard.
  ///
  /// In en, this message translates to:
  /// **'ATM fee, Kasikorn K-ATM, Mastercard'**
  String get factThAtmMastercard;

  /// No description provided for @factMangoLowest.
  ///
  /// In en, this message translates to:
  /// **'Mango, lowest wholesale price today'**
  String get factMangoLowest;

  /// No description provided for @factUpdated.
  ///
  /// In en, this message translates to:
  /// **'Read from the page today'**
  String get factUpdated;

  /// No description provided for @factUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Same as before, checked today'**
  String get factUnchanged;

  /// No description provided for @factKeptBlocked.
  ///
  /// In en, this message translates to:
  /// **'Kept the last value, the site blocks automated reads'**
  String get factKeptBlocked;

  /// No description provided for @factKeptNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Kept the last value, the figure was not found word for word'**
  String get factKeptNoMatch;

  /// No description provided for @factKeptOther.
  ///
  /// In en, this message translates to:
  /// **'Kept the last value, the page could not be read'**
  String get factKeptOther;

  /// No description provided for @factNew.
  ///
  /// In en, this message translates to:
  /// **'Researched by hand, not checked online yet'**
  String get factNew;

  /// No description provided for @factSourceLine.
  ///
  /// In en, this message translates to:
  /// **'{host} · checked {time}'**
  String factSourceLine(String host, String time);
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
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
