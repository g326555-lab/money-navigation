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
  /// **'No ATM conversion offer in this photo'**
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
  /// **'Point at the ATM screen that shows the amount in your home currency.'**
  String get scanTipNotAtm;

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

  /// Spoken to a Thai seller; always Thai in every locale.
  ///
  /// In en, this message translates to:
  /// **'ลดเหลือ {amount} บาทได้ไหม'**
  String counterOfferSentence(String amount);

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

  /// No description provided for @speakUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Thai speech recognition isn\'t available on this phone. You can type what you heard.'**
  String get speakUnavailable;

  /// No description provided for @speakDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off for Money Navigation. Turn it on in Settings, or type what you heard.'**
  String get speakDenied;

  /// No description provided for @speakEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get speakEnterPrice;

  /// No description provided for @speakEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'What is the seller asking'**
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
  /// **'What are they selling'**
  String get speakWhichItem;

  /// No description provided for @speakHeardPrice.
  ///
  /// In en, this message translates to:
  /// **'We heard {price}.'**
  String speakHeardPrice(String price);
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
