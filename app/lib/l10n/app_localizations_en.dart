// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Money Navigation';

  @override
  String get scanHint => 'Point at the ATM screen';

  @override
  String get scanShutter => 'Take photo';

  @override
  String get scanChoosePhoto => 'Choose photo';

  @override
  String get scanClose => 'Close';

  @override
  String get scanFlashOn => 'Turn on light';

  @override
  String get scanFlashOff => 'Turn off light';

  @override
  String get scanCameraUnavailable => 'The camera isn\'t available right now.';

  @override
  String get scanCameraDenied =>
      'Camera access is off for Money Navigation. Turn it on in Settings, or choose a photo.';

  @override
  String get stepReadText => 'Reading the photo';

  @override
  String stepReadTextDone(int ms) {
    return 'Read on your phone in $ms ms';
  }

  @override
  String get stepFindAtm => 'Looking for an ATM conversion offer';

  @override
  String get stepFindAtmDone => 'ATM conversion offer found';

  @override
  String stepValues(String withdrawal, String fee, String rate) {
    return 'Withdrawal $withdrawal · fee $fee · 1 USD = $rate THB';
  }

  @override
  String stepValuesMarkup(String values, String markup) {
    return '$values · mark-up $markup';
  }

  @override
  String get stepCompare => 'Comparing both totals';

  @override
  String stepCompareDone(String amount) {
    return 'Converting costs about $amount more';
  }

  @override
  String get stepCompareEven => 'Both totals come out about the same';

  @override
  String get scanTryAgain => 'Try again';

  @override
  String get atmKeepLabel => 'You keep about';

  @override
  String get atmPress => 'Press';

  @override
  String get atmDeclineButton =>
      'The option without conversion, so you pay in baht';

  @override
  String atmReasonMarkup(String markup) {
    return 'The ATM\'s own rate adds $markup on top.';
  }

  @override
  String get atmReasonNoMarkup =>
      'The ATM\'s own rate charges more than the rate on its screen.';

  @override
  String atmSource(String time) {
    return 'From the numbers on this ATM screen · $time';
  }

  @override
  String get atmEvenTitle => 'Either choice costs about the same';

  @override
  String get atmEvenBody =>
      'The converted total matches the rate on the screen, so there is nothing to keep here.';

  @override
  String get stepFindAtmFailed => 'No ATM conversion offer in this photo';

  @override
  String get stepReadTextFailed => 'No text found';

  @override
  String get stepValuesFailed => 'Some numbers couldn\'t be read';

  @override
  String get scanTipNoText =>
      'Move closer so the screen fills most of the photo.';

  @override
  String get scanTipNotAtm =>
      'Point at the ATM screen that shows the amount in your home currency.';

  @override
  String get scanTipMissingValues =>
      'Hold the phone straight and avoid glare on the screen.';

  @override
  String get atmBothTotals => 'Both totals';

  @override
  String get atmIfConvertDetail => 'At the ATM\'s own rate';

  @override
  String get atmIfNotConvertDetail => 'Your card\'s bank converts it';

  @override
  String get atmOnScreen => 'On this screen';

  @override
  String get atmRowWithdrawal => 'Withdrawal';

  @override
  String get atmRowFee => 'ATM access fee';

  @override
  String get atmRowRate => 'Rate shown';

  @override
  String get atmRowMarkup => 'Mark-up shown';

  @override
  String atmRateValue(String rate) {
    return '1 USD = $rate THB';
  }

  @override
  String get atmIfConvert => 'If you convert';

  @override
  String get atmIfNotConvert => 'If you don\'t';

  @override
  String get atmScanAnother => 'Scan another';
}
