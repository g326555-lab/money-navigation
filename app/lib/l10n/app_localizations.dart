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
  /// **'Point at the ATM screen'**
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
  /// **'The camera isn\'t available. You can still choose a photo.'**
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
  /// **'Withdrawal {withdrawal} · fee {fee} · 1 USD = {rate} THB'**
  String stepValues(String withdrawal, String fee, String rate);

  /// No description provided for @stepValuesMarkup.
  ///
  /// In en, this message translates to:
  /// **'{values} · mark-up {markup}'**
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
  /// **'1 USD = {rate} THB'**
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
