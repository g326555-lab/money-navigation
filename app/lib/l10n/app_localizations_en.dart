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
  String counterOfferSentence(String amount, String ending) {
    return 'ลดเหลือ $amount บาทได้ไหม$ending';
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
  String get speakEnterPrice => 'Enter price';

  @override
  String get speakEnterTitle => 'What is the seller asking?';

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
  String get speakWhichItem => 'What are they selling?';

  @override
  String speakHeardPrice(String price) {
    return 'We heard $price.';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabScan => 'Scan';

  @override
  String get tabSpeak => 'Speak';

  @override
  String get tabRecords => 'Records';

  @override
  String get back => 'Back';

  @override
  String get homeKeptLabel => 'Kept on this trip';

  @override
  String homeKeptApprox(String amount) {
    return 'About $amount';
  }

  @override
  String ratePair(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String homeRateSource(String pair, String date) {
    return '$pair on $date · European Central Bank via Frankfurter';
  }

  @override
  String homeRateCached(String pair, String date) {
    return '$pair on $date · European Central Bank via Frankfurter · last known, offline';
  }

  @override
  String get homeRateLoading => 'Getting today\'s rate';

  @override
  String homeRateUnavailable(String currency) {
    return 'Today\'s $currency rate needs a connection';
  }

  @override
  String get homeRecent => 'Recent saves';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeEmptyLabel => 'Before you withdraw';

  @override
  String get homeEmptyTitle => 'Scan the ATM screen before you press anything';

  @override
  String get homeEmptyAction => 'Open the scanner';

  @override
  String saveKeptValue(String amount) {
    return '+$amount';
  }

  @override
  String get saveAtmTitle => 'ATM conversion avoided';

  @override
  String saveHaggleTitle(String item) {
    return '$item haggled down';
  }

  @override
  String saveHaggleSubtitle(String paid, String when) {
    return 'Paid $paid · $when';
  }

  @override
  String get saveHaggleUnknownItem => 'Market price';

  @override
  String get saveToTrip => 'Save to trip';

  @override
  String get savedToTrip => 'Saved to trip';

  @override
  String get recordsTitle => 'Records';

  @override
  String get recordsEmpty =>
      'Nothing saved yet. Results you save after a scan or a haggle are listed here.';

  @override
  String get recordsRemove => 'Remove';

  @override
  String get recordsFooter =>
      'Swipe a row left to remove it. Saved only on this phone.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCurrency => 'Home currency';

  @override
  String get settingsChange => 'Change';

  @override
  String get settingsCurrencyFooter =>
      'Totals also show in this currency at the daily rate from Frankfurter (European Central Bank).';

  @override
  String get settingsSpeaking => 'Speaking Thai for you';

  @override
  String get settingsEndingMale => 'End with khrap';

  @override
  String get settingsEndingFemale => 'End with kha';

  @override
  String get settingsEndingNone => 'No ending';

  @override
  String get settingsSpeakingFooter =>
      'Thai speakers end a polite request with khrap (men) or kha (women).';

  @override
  String get politeEndingMale => 'ครับ';

  @override
  String get politeEndingFemale => 'คะ';

  @override
  String get currencyOffline =>
      'Connect to the internet to load the list of currencies.';

  @override
  String get currencySource =>
      'Currencies with a daily reference rate from the European Central Bank.';

  @override
  String get haggleSaveTitle => 'What did you pay?';

  @override
  String get haggleSaveOffer => 'Your offer';

  @override
  String get haggleSaveAsked => 'Their price';

  @override
  String get haggleSaveOther => 'Another amount';

  @override
  String haggleSaveKeeps(String amount) {
    return 'Keeps $amount';
  }

  @override
  String settingsEndingExample(String ending) {
    return '…ได้ไหม$ending';
  }

  @override
  String haggleSaveTooHigh(String amount) {
    return 'Enter less than $amount, the price they asked';
  }

  @override
  String get speakDeniedTitle => 'Microphone is off';

  @override
  String get speakDeniedBody =>
      'Turn on the microphone for Money Navigation in Settings, or enter the price yourself.';

  @override
  String get speakUnavailableTitle => 'Thai listening isn\'t available';

  @override
  String get speakUnavailableBody =>
      'This phone can\'t recognise Thai speech. Enter the price yourself instead.';

  @override
  String get speakOpenSettings => 'Open Settings';

  @override
  String speakAmountUnit(String amount, String unit) {
    return '$amount $unit';
  }

  @override
  String haggleSaveChoice(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get speakPriceInvalid => 'Enter a number, like 150';

  @override
  String speakPriceTooHigh(String amount) {
    return 'Prices up to $amount';
  }

  @override
  String get haggleSaveNothingKept =>
      'Paying their price keeps nothing to save';

  @override
  String get recordsRemoved => 'Removed from this trip';

  @override
  String get recordsUndo => 'Undo';

  @override
  String aiTrace(String engine, String elapsed) {
    return 'Checked by $engine · $elapsed';
  }

  @override
  String aiVoiceCached(String engine) {
    return 'Voice from $engine, saved on this phone';
  }

  @override
  String aiItemMatched(
    String engine,
    String item,
    String confidence,
    String elapsed,
  ) {
    return '$engine matched what was heard to $item, $confidence sure · $elapsed';
  }

  @override
  String aiPlacesLine(
    String engine,
    String place,
    String rating,
    String reviews,
    String elapsed,
  ) {
    return '$engine · $place $rating ($reviews reviews) · $elapsed';
  }

  @override
  String get billOpen => 'Check a bill';

  @override
  String get billStartTitle => 'Check a Thai bill';

  @override
  String get billStartBody =>
      'Take a photo of the whole bill. Google Cloud Vision reads the Thai, then your phone checks that every figure adds up and shows what was added on top.';

  @override
  String get billTake => 'Take photo';

  @override
  String get billTakeAnother => 'Another bill';

  @override
  String get billChoose => 'Choose photo';

  @override
  String get billReading => 'Reading the bill';

  @override
  String billReadingBody(String engine) {
    return '$engine is reading the Thai text. Your phone checks the figures next.';
  }

  @override
  String get billTotalLabel => 'Total on this bill';

  @override
  String get billServiceChip => 'Service charge added on top';

  @override
  String get billVatOnTopChip => 'VAT added on top';

  @override
  String get billVatInsideChip => 'VAT already included';

  @override
  String get billNothingAddedChip => 'Nothing added on top';

  @override
  String get billHowBuilt => 'How the total was built';

  @override
  String get billInsideTotal => 'Already inside the total';

  @override
  String get billSubtotal => 'Subtotal';

  @override
  String billItems(int count) {
    return '$count items';
  }

  @override
  String get billDiscount => 'Discount';

  @override
  String get billService => 'Service charge';

  @override
  String billServicePercent(String percent) {
    return 'Service charge $percent %';
  }

  @override
  String get billVat => 'VAT';

  @override
  String billVatPercent(String percent) {
    return 'VAT $percent %';
  }

  @override
  String get billAddedOnTop => 'Added on top';

  @override
  String get billAlreadyIncluded => 'Already included, not extra';

  @override
  String get billTotal => 'Total';

  @override
  String get billBeforeVat => 'Before VAT';

  @override
  String get billProof =>
      'Every figure was checked against the others on this bill.';

  @override
  String billVisionTrace(String engine, int lines, String elapsed) {
    return 'Read by $engine · $lines lines · $elapsed';
  }

  @override
  String get billOfflineTitle => 'No connection';

  @override
  String get billOfflineBody =>
      'Reading Thai needs the internet. Connect and take the photo again.';

  @override
  String get billTooLargeTitle => 'That photo is too large';

  @override
  String get billTooLargeBody =>
      'This photo is too big to send. Take it again from this screen, it sends a smaller copy.';

  @override
  String get billNoTextTitle => 'No text found';

  @override
  String get billNoTextBody =>
      'Fill the frame with the bill, in good light, and try again.';

  @override
  String get billNoMatchTitle => 'Couldn\'t verify this bill';

  @override
  String get billNoMatchBody =>
      'The text was read, but its figures don\'t add up in a way we can prove. Nothing is shown rather than a guess. Try a sharper photo of the whole bill.';

  @override
  String get billServiceTitle => 'The reader didn\'t answer';

  @override
  String get billServiceBody => 'Try again in a moment.';

  @override
  String get authWelcomeTitle => 'See which way to pay';

  @override
  String get authWelcomeBody =>
      'Sign in to keep your trip records on any phone.';

  @override
  String get authContinueApple => 'Continue with Apple';

  @override
  String get authContinueGoogle => 'Continue with Google';

  @override
  String get authContinueEmail => 'Continue with email';

  @override
  String get authLookAround => 'Look around without an account';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authCreateTitle => 'Create an account';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authNameLabel => 'Name, if you like';

  @override
  String authPasswordRule(int min) {
    return 'At least $min characters';
  }

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authCreateAction => 'Create account';

  @override
  String get authToCreate => 'New here? Create an account';

  @override
  String get authToSignIn => 'Have an account? Sign in';

  @override
  String get authForgot => 'Forgot password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authConfirmTitle => 'Check your email';

  @override
  String authConfirmBody(String email) {
    return 'We sent a link to $email. Tap it, then come back and sign in.';
  }

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetIntro =>
      'We\'ll email you a link to set a new password. Open it on this phone.';

  @override
  String get authResetSend => 'Email me a link';

  @override
  String get authResetNewPassword => 'New password';

  @override
  String authResetSentTo(String email) {
    return 'Link sent to $email. Open it on this phone to set a new password.';
  }

  @override
  String get authResetSave => 'Set new password';

  @override
  String get authResetResend => 'Send it again';

  @override
  String get authErrEmailEmpty => 'Enter your email';

  @override
  String get authErrEmailMalformed => 'That email doesn\'t look right';

  @override
  String get authErrPasswordEmpty => 'Enter a password';

  @override
  String authErrPasswordShort(int min) {
    return 'Use at least $min characters';
  }

  @override
  String get authErrCodeInvalid => 'That link has expired. Ask for a new one.';

  @override
  String get authErrInvalidCredentials => 'Email or password is wrong';

  @override
  String get authErrEmailTaken =>
      'This email already has an account. Sign in instead.';

  @override
  String get authErrEmailNotConfirmed =>
      'Confirm your email first. The link is in your inbox.';

  @override
  String get authErrWeakPassword => 'Choose a different, longer password';

  @override
  String get authErrRateLimited =>
      'Too many tries. Wait a minute, then try again.';

  @override
  String get authErrOffline =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get authErrNotConfigured =>
      'This way of signing in isn\'t ready in this version.';

  @override
  String get authErrUnknown => 'Couldn\'t sign in. Try again.';

  @override
  String get authSetupTitle => 'About your trip';

  @override
  String get authSetupIntro => 'So every amount shows in money you know';

  @override
  String get authSetupTypeHeader => 'You are';

  @override
  String get authTypeVisitor => 'Visiting Thailand';

  @override
  String get authTypeVisitorSub => 'Paying in baht';

  @override
  String get authTypeThai => 'Thai, travelling abroad';

  @override
  String get authTypeThaiSub => 'Paying in other currencies';

  @override
  String get authSetupMoneyHeader => 'Money';

  @override
  String get authHomeCurrency => 'You think in';

  @override
  String get authCardCurrency => 'Your card bills in';

  @override
  String get authSetupLanguageHeader => 'Language';

  @override
  String get authLanguageEn => 'English';

  @override
  String get authLanguageTh => 'ไทย';

  @override
  String get authSetupFooter => 'You can change these later in Settings.';

  @override
  String get authSetupStart => 'Start my trip';

  @override
  String get authSetupOtherAccount => 'Use a different account';

  @override
  String get authAccountHeader => 'Account';

  @override
  String get authGuestTitle => 'Not signed in';

  @override
  String get authGuestSub => 'Records stay on this phone only';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authDelete => 'Delete account';

  @override
  String get authDeleteTitle => 'Delete your account?';

  @override
  String get authDeleteBody =>
      'Your profile and saved records will be removed for good.';

  @override
  String get authDeleteConfirm => 'Delete account';

  @override
  String get authCancel => 'Cancel';

  @override
  String get politeEndingFemaleStatement => 'ค่ะ';

  @override
  String get haggleNextLabel => 'Ask for this next';

  @override
  String get haggleDealLabel => 'Deal';

  @override
  String haggleDealAmount(String amount) {
    return '$amount THB';
  }

  @override
  String haggleAcceptSentence(String amount, String ending) {
    return 'ตกลง $amount บาท$ending';
  }

  @override
  String get haggleStopLabel => 'They won\'t go lower';

  @override
  String haggleStopAmount(String amount) {
    return 'Pay $amount THB or walk away';
  }

  @override
  String haggleLeaveSentence(String ending) {
    return 'ไม่เป็นไร ขอบคุณ$ending';
  }

  @override
  String get haggleTheyAnswered => 'What did they say?';

  @override
  String get haggleTheyAgreed => 'They agreed';

  @override
  String get haggleTheySaidNo => 'They said no';

  @override
  String get haggleTheyOffered => 'New price';

  @override
  String haggleTheyOfferedPrice(String amount) {
    return 'They offered $amount';
  }

  @override
  String get haggleUnclear => 'Not clear, ask again';

  @override
  String get haggleSoFar => 'This haggle so far';

  @override
  String get haggleFirstAsk => 'They asked';

  @override
  String get haggleYouOffered => 'You offered';

  @override
  String haggleYouAsk(String amount) {
    return 'You ask $amount';
  }

  @override
  String haggleTheirLast(String amount) {
    return 'Their last $amount';
  }

  @override
  String get haggleTheyOfferedTitle => 'What price did they say?';

  @override
  String get haggleUsePrice => 'Use this price';

  @override
  String get haggleNewPrice => 'New price';

  @override
  String get haggleHearAnswer => 'Hear their answer';

  @override
  String get haggleListeningAnswer => 'Listening for their answer';

  @override
  String get authNewPasswordTitle => 'Set a new password';

  @override
  String get saveTerminalTitle => 'Paid in local currency at a card terminal';

  @override
  String dccKeepLabel(String currency) {
    return 'Pay in $currency and keep';
  }

  @override
  String dccMarkupChip(String percent) {
    return '$percent markup avoided';
  }

  @override
  String dccPressKey(int key, String currency) {
    return 'F$key · pay in $currency';
  }

  @override
  String dccReason(String home, String percent) {
    return 'The $home price on this terminal adds about $percent on top of the bank rate.';
  }

  @override
  String get dccBothOptions => 'Both options on the terminal';

  @override
  String dccOptionKey(int key) {
    return 'F$key';
  }

  @override
  String get dccOptionHome => 'Your home currency';

  @override
  String get dccOptionLocal => 'Local currency';

  @override
  String dccFairHome(String currency) {
    return 'Fair price in $currency';
  }

  @override
  String dccEvenTitle(int key) {
    return 'Either key is fine here, F$key included';
  }

  @override
  String get dccEvenBody =>
      'The home-currency price is not dearer than paying locally at today\'s rate.';

  @override
  String rateDemoSource(String pair, String date) {
    return '$pair · fixed demo rate, $date';
  }

  @override
  String boardLossTitle(String code, String percent) {
    return 'Selling $code here gets about $percent less than the middle rate';
  }

  @override
  String boardLossBody(String amount, String loss) {
    return 'On $amount that is about $loss less in your hand.';
  }

  @override
  String boardRates(String code) {
    return '$code on this board';
  }

  @override
  String get boardBuying => 'They buy at';

  @override
  String boardBuyingHint(String code) {
    return 'What you get for each $code';
  }

  @override
  String get boardSelling => 'They sell at';

  @override
  String get boardMid => 'Middle rate';

  @override
  String get boardSource => 'From the numbers on this board';

  @override
  String boardVsReference(String percent, String source) {
    return 'About $percent below $source';
  }

  @override
  String get stepFindTerminalDone => 'Card terminal with two currencies found';

  @override
  String get stepFindBoardDone => 'Exchange rate board found';

  @override
  String stepCompareDcc(String amount) {
    return 'Paying locally keeps about $amount';
  }

  @override
  String stepCompareBoard(String percent) {
    return 'About $percent below the middle rate';
  }

  @override
  String get settingsDemo => 'Demo';

  @override
  String get settingsDemoFooter =>
      'For presenting. Language, currency and records change together, with fixed rates. Your own records are kept and come back when you turn it off.';

  @override
  String billCheckedTrace(String elapsed) {
    return 'Figures checked on this phone · $elapsed';
  }

  @override
  String get authSigningIn => 'Signing in';

  @override
  String get authErrTryAgain => 'That didn\'t work. Try again.';

  @override
  String get authErrEmailRejected =>
      'This email can\'t be used. Try another one.';

  @override
  String get authErrEmailUndeliverable =>
      'We can\'t send email to this address yet.';

  @override
  String get billTimeoutTitle => 'That took too long';

  @override
  String get billTimeoutBody => 'That took too long. Try again in a moment.';

  @override
  String scanKindLine(
    String engine,
    String kind,
    String confidence,
    String elapsed,
  ) {
    return '$engine sees $kind ($confidence) · $elapsed';
  }

  @override
  String get scanCheckAsBill => 'Check it as a bill';

  @override
  String get kindAtm => 'an ATM screen';

  @override
  String get kindTerminal => 'a card terminal';

  @override
  String get kindBill => 'a bill or menu';

  @override
  String get kindPriceTag => 'a price tag';

  @override
  String get kindOther => 'something else';

  @override
  String get demoLabel => 'Demo';

  @override
  String get demoVisitorBangkok => 'US visitor in Bangkok';

  @override
  String get demoThaiTokyo => 'Thai traveler in Tokyo';

  @override
  String demoPersonaDetail(String language, String currency) {
    return '$language · $currency';
  }

  @override
  String demoPill(String name) {
    return 'Demo · $name';
  }

  @override
  String demoSwitchTo(String name) {
    return 'Switch to $name';
  }

  @override
  String get settingsDemoOff => 'Off';

  @override
  String get settingsDemoOffHint => 'Today\'s rates and your own records';

  @override
  String settingsDemoPersonaHint(String detail) {
    return '$detail · fixed rates, sample records';
  }

  @override
  String saveSampleWhen(String when) {
    return 'Sample · $when';
  }

  @override
  String homeRateDemo(String pair, String date) {
    return '$pair · fixed demo rate, $date';
  }

  @override
  String get homeToday => 'Today';

  @override
  String homeCashToday(String amount) {
    return 'About $amount in cash today';
  }

  @override
  String homeCashBasis(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Estimate from your last $days days',
    );
    return '$_temp0';
  }

  @override
  String homeCashBasisSamples(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Estimate from $days days of sample records',
    );
    return '$_temp0';
  }

  @override
  String homeCashBasisMixed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Estimate from your last $days days, sample records included',
    );
    return '$_temp0';
  }

  @override
  String memoryDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: 'yesterday',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String memoryPaidHere(String amount, String when) {
    return 'You paid $amount here $when';
  }

  @override
  String memoryPaidAt(String amount, String place, String when) {
    return 'You paid $amount at $place $when';
  }

  @override
  String memoryPaid(String amount, String when) {
    return 'You paid $amount $when';
  }

  @override
  String memoryFromRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'from your $count past records',
      one: 'from your 1 past record',
    );
    return '$_temp0';
  }

  @override
  String memoryFromSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'from $count sample records',
      one: 'from 1 sample record',
    );
    return '$_temp0';
  }

  @override
  String memoryFromMixed(int count, int samples) {
    return 'from $count past records, $samples of them samples';
  }

  @override
  String memoryLine(String fact, String basis) {
    return '$fact · $basis';
  }

  @override
  String get memoryCounterRow => 'Your past haggles suggest';

  @override
  String memoryAbout(String amount) {
    return 'About $amount';
  }

  @override
  String get authWelcomeExample => 'Example';

  @override
  String get authWelcomeExampleLabel => 'ATM offered to convert';

  @override
  String get authWelcomeExampleChip => 'Kept by declining the conversion';

  @override
  String authWelcomeExampleSemantics(String amount) {
    return 'Example. An ATM offered to convert. Declining kept $amount.';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsCredits => 'Photo credits';

  @override
  String get creditsUnavailable => 'The credits list couldn\'t be opened.';

  @override
  String settingsCreditsHint(int count) {
    return 'The on-device photo model learned from $count photos shared under Creative Commons licences. Their authors are credited below.';
  }

  @override
  String creditsRow(String author, String license) {
    return '$author · $license';
  }

  @override
  String get creditsFooter =>
      'Photos from Wikimedia Commons, used under the licence named on each row.';

  @override
  String aiWordedBy(String engine, String elapsed) {
    return 'Worded by $engine from the figures above · $elapsed';
  }
}
