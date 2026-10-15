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
  String get scanHint => 'Fit the ATM screen inside the frame';

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

  @override
  String get speakOpen => 'Hear a price';

  @override
  String get speakListening => 'Listening';

  @override
  String get speakListenHint => 'Hold your phone toward the seller';

  @override
  String get speakStop => 'Done listening';

  @override
  String get speakListenAgain => 'Listen again';

  @override
  String get speakTypeSubmit => 'Check this price';

  @override
  String get speakHeard => 'They said';

  @override
  String speakMeaning(String item, String amount, String unit) {
    return '$item, $amount $unit';
  }

  @override
  String get unitPerKg => 'per kilo';

  @override
  String get unitEach => 'each';

  @override
  String get unitPerPlate => 'per plate';

  @override
  String get unitPerHour => 'per hour';

  @override
  String get unitPerRide => 'per ride';

  @override
  String get verdictHigh => 'High';

  @override
  String get verdictFair => 'Fair';

  @override
  String get verdictLow => 'Low';

  @override
  String speakOverBy(String amount) {
    return '$amount above the usual price';
  }

  @override
  String get speakFairBody => 'This is within the usual price.';

  @override
  String get speakLowBody => 'This is below the usual price.';

  @override
  String get speakUsualPrice => 'Usual price';

  @override
  String speakUsualRange(String low, String high, String unit) {
    return '$low–$high THB $unit';
  }

  @override
  String get speakAsked => 'Asked';

  @override
  String speakSources(int count, String month) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0 · $month';
  }

  @override
  String get speakCounterLabel => 'Ask for';

  @override
  String speakCounterAmount(String amount) {
    return '$amount THB';
  }

  @override
  String get speakSayIt => 'Say it in Thai';

  @override
  String get speakSpeaking => 'Speaking';

  @override
  String get speakNoVoice =>
      'No Thai voice on this phone. Show the sentence to the seller instead.';

  @override
  String counterOfferSentence(String amount) {
    return 'ลดเหลือ $amount บาทได้ไหม';
  }

  @override
  String get speakNothingHeard => 'Nothing was heard';

  @override
  String get speakNothingHeardTip =>
      'Move closer to the seller and try again, or type what you heard.';

  @override
  String get speakNoPrice => 'No price in what was heard';

  @override
  String get speakNoPriceTip => 'Ask the seller the price again, then listen.';

  @override
  String get speakUnknownItem => 'No usual price for this yet';

  @override
  String speakUnknownItemTip(String amount) {
    return 'The price was $amount. We only compare items we have sources for.';
  }

  @override
  String get speakUnitMismatch => 'The price is for a different amount';

  @override
  String speakUnitMismatchTip(String unit) {
    return 'The usual price is $unit. Ask the seller for the price $unit.';
  }

  @override
  String get speakUnavailable =>
      'Thai speech recognition isn\'t available on this phone. You can type what you heard.';

  @override
  String get speakDenied =>
      'Microphone access is off for Money Navigation. Turn it on in Settings, or type what you heard.';

  @override
  String get speakEnterPrice => 'Enter price';

  @override
  String get speakEnterTitle => 'What is the seller asking';

  @override
  String get speakPickItem => 'Item';

  @override
  String get speakPriceLabel => 'Price in THB';

  @override
  String get speakEntered => 'You entered';

  @override
  String get speakPreparing => 'Getting ready';

  @override
  String get speakUsualRangeRow => 'Usual range';

  @override
  String speakHeroLabel(String item, String unit) {
    return '$item · $unit';
  }

  @override
  String speakSourcesLine(String hosts, String sources) {
    return '$hosts · $sources';
  }

  @override
  String speakMonthRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get speakWhichItem => 'What are they selling';

  @override
  String speakHeardPrice(String price) {
    return 'We heard $price.';
  }
}
