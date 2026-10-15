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
  String get stepFindAtmFailed =>
      'No currency choice or rate board in this photo';

  @override
  String get stepReadTextFailed => 'No text found';

  @override
  String get stepValuesFailed => 'Some numbers couldn\'t be read';

  @override
  String get scanTipNoText =>
      'Move closer so the screen fills most of the photo.';

  @override
  String get scanTipNotAtm =>
      'Point straight at the screen that offers two currencies, or at a rate board.';

  @override
  String get scanTipLooksLikeBill =>
      'This looks like a bill. You can check it here.';

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
  String get homeKeptOpenRecords => 'Open trip records';

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
  String get homeRecentReceipts => 'Recent receipts';

  @override
  String get receiptChecked =>
      'Figures checked against the saved receipt data.';

  @override
  String get receiptNotChecked =>
      'Receipt data saved, but the figures were not verified.';

  @override
  String get receiptPhotoMissing =>
      'The receipt details saved here do not include a photo.';

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
  String get saveDetailsAsked => 'Seller asked';

  @override
  String get saveDetailsPaid => 'You paid';

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
    return 'Service charge $percent%';
  }

  @override
  String get billVat => 'VAT';

  @override
  String billVatPercent(String percent) {
    return 'VAT $percent%';
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
      'Take it again from this screen and a smaller copy is sent.';

  @override
  String get billNoTextTitle => 'No text found';

  @override
  String get billNoTextBody =>
      'Fill the frame with the bill, in good light, and try again.';

  @override
  String get billNoMatchTitle => 'Couldn\'t verify this bill';

  @override
  String get billNoMatchBody =>
      'The text was read, but its figures don\'t add up, so nothing is shown rather than a guess. Try a sharper photo of the whole bill.';

  @override
  String get billServiceTitle => 'The bill reader didn\'t answer';

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
  String get authSetupIntro => 'So every amount shows in money you know.';

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
    return 'The $home price on this terminal is about $percent above the bank rate.';
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
  String dccOptionHomeMore(String amount) {
    return 'Home currency · about $amount more';
  }

  @override
  String get dccOptionLocal => 'Local currency';

  @override
  String dccFairHome(String currency) {
    return 'Fair price in $currency';
  }

  @override
  String get dccEvenTitle => 'Either key is fine here';

  @override
  String get dccEvenBody =>
      'Paying in your home currency costs no more than paying locally at today\'s rate.';

  @override
  String rateDemoSource(String pair, String date) {
    return '$pair · fixed demo rate, $date';
  }

  @override
  String boardRates(String code) {
    return '$code on this board';
  }

  @override
  String boardHeroLabel(String code) {
    return 'Selling $code here, below the middle rate';
  }

  @override
  String boardLossChip(String loss, String amount) {
    return 'About $loss less per $amount';
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
    return 'Buying rate about $percent below $source';
  }

  @override
  String boardAboveReference(String percent, String source) {
    return 'Buying rate about $percent above $source';
  }

  @override
  String get stepFindTerminalDone => 'Two-currency card terminal found';

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
  String get billTimeoutBody =>
      'The connection may be slow. Try again in a moment.';

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
  String get cashWalletTitle => 'Cash on hand';

  @override
  String get cashWalletUpdate => 'Update';

  @override
  String get cashWalletNotSet => 'Add your cash balance to start tracking';

  @override
  String cashWalletCurrent(String amount) {
    return 'Current balance: $amount';
  }

  @override
  String get cashWalletSetBalance => 'Set balance';

  @override
  String get cashWalletAddCash => 'Add cash';

  @override
  String get cashWalletSpendCash => 'Record cash spent';

  @override
  String get cashWalletBalanceField => 'Cash you have now';

  @override
  String get cashWalletAddField => 'Cash added';

  @override
  String get cashWalletSpendField => 'Cash spent';

  @override
  String get cashWalletSave => 'Save balance';

  @override
  String get cashWalletAdded => 'Cash added';

  @override
  String get cashWalletSpent => 'Cash spent';

  @override
  String get cashWalletAtm => 'ATM withdrawal';

  @override
  String get cashWalletHaggle => 'Market purchase';

  @override
  String get cashWalletBill => 'Receipt payment';

  @override
  String get cashWalletBillCash => 'Paid in cash · wallet updated';

  @override
  String get cashWalletBillCard => 'Paid by card · cash balance unchanged';

  @override
  String get cashWalletExchange => 'Cash exchange';

  @override
  String get exchangeTitle => 'Find a better exchange rate';

  @override
  String get exchangeSubtitle =>
      'Nearby counters · rates from their published boards';

  @override
  String get exchangeAmount => 'Foreign cash to exchange';

  @override
  String get exchangeCurrency => 'Currency you have';

  @override
  String get exchangeDenomination => 'Banknote rate tier';

  @override
  String get exchangeChooseDenomination => 'Choose the notes you have';

  @override
  String get exchangeFind => 'Compare nearby rates';

  @override
  String get exchangeLoading => 'Checking current published rates';

  @override
  String get exchangeNoLocation =>
      'Turn on location to compare nearby counters';

  @override
  String get exchangeNoData => 'Live exchange rates are unavailable right now';

  @override
  String exchangeNoNearby(Object distance) {
    return 'No current rates found within $distance km';
  }

  @override
  String get exchangeNoRates =>
      'No current quote for this currency and note tier';

  @override
  String exchangeRateLine(Object rate, Object payoutCurrency, Object currency) {
    return '$rate $payoutCurrency per 1 $currency';
  }

  @override
  String exchangePayout(Object amount) {
    return 'About $amount';
  }

  @override
  String exchangeDistance(Object distance) {
    return '$distance km away';
  }

  @override
  String exchangeUpdated(Object time) {
    return 'Rate source updated $time';
  }

  @override
  String get exchangeFreshness => 'Only current published rates are ranked';

  @override
  String get exchangeAttribution =>
      'Rates collected from published shop boards by ThaiRate · CC BY 4.0';

  @override
  String get exchangeCounterNote =>
      'Rates can change at the counter. Confirm before exchanging.';

  @override
  String get exchangeMap => 'Open map';

  @override
  String get exchangeAddToCash => 'Add received cash to balance';

  @override
  String get exchangeConfirmTitle => 'Confirm the counter payout';

  @override
  String exchangeConfirmBody(Object amount) {
    return 'The estimate was about $amount. Enter the amount you actually received.';
  }

  @override
  String get exchangeUseActual => 'Add actual amount';

  @override
  String get exchangeCancel => 'Cancel';

  @override
  String get exchangeRecorded => 'Exchange added to Cash on hand';

  @override
  String get exchangeMixedDenomination =>
      'Compare one banknote tier at a time. Enter only cash in that tier.';

  @override
  String get cashPaymentMethod => 'How did you pay?';

  @override
  String get cashPaymentCash => 'Cash';

  @override
  String get cashPaymentCard => 'Card';

  @override
  String get cashPaymentExplainer =>
      'Choose the payment method so your cash balance stays accurate.';

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
  String get memoryCounterRow => 'Your past haggles';

  @override
  String memoryAbout(String amount) {
    return 'About $amount';
  }

  @override
  String get authWelcomeExample => 'Example';

  @override
  String get authWelcomeExampleLabel =>
      'The ATM\'s conversion would have added';

  @override
  String get authWelcomeExampleChip => 'Kept by choosing no conversion';

  @override
  String authWelcomeExampleSemantics(String amount) {
    return 'Example. The ATM\'s conversion would have cost $amount more. Choosing no conversion kept it.';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsCredits => 'Photo credits';

  @override
  String get creditsUnavailable => 'The credits list could not be read';

  @override
  String settingsCreditsHint(int count) {
    return '$count photos that taught the app to tell photos apart';
  }

  @override
  String creditsRow(String author, String license) {
    return '$author · $license';
  }

  @override
  String get creditsFooter =>
      'These photos from Wikimedia Commons trained the on-device model that tells an ATM screen, a card terminal, a rate board and a receipt apart. Each is used under the licence shown, with its author.';

  @override
  String aiWordedBy(String engine, String elapsed) {
    return 'Worded by $engine from the figures above · $elapsed';
  }

  @override
  String memoryDiscount(String percent) {
    return 'About $percent % off the first price';
  }

  @override
  String get homeKeptSamples => 'Includes sample records';

  @override
  String priceSentenceHigh(String asked, String over, String percent) {
    return '$asked is $over above the usual top price, about $percent';
  }

  @override
  String priceSentenceFair(String asked) {
    return '$asked is inside the usual price';
  }

  @override
  String priceSentenceLow(String asked) {
    return '$asked is below the usual price, a good buy';
  }

  @override
  String priceAsked(String amount) {
    return 'Asked $amount';
  }

  @override
  String priceYouPaid(String amount) {
    return 'You paid $amount';
  }

  @override
  String get priceZoneCheap => 'Cheap';

  @override
  String priceZoneUsual(String unit) {
    return 'Usual $unit';
  }

  @override
  String get priceZoneHigh => 'High';

  @override
  String get priceZoneFarAbove => 'Far above';

  @override
  String get priceZoneFarBelow => 'Far below';

  @override
  String priceSemanticsRange(String low, String high, String unit) {
    return 'Usual price $low to $high baht $unit';
  }

  @override
  String priceSemanticsCounter(String amount) {
    return 'Suggested offer $amount';
  }

  @override
  String get haggleShowSeller => 'Show the seller';

  @override
  String get showSellerTurn => 'Turn to the seller';

  @override
  String get showSellerTurnBack => 'Turn back to me';

  @override
  String get showSellerClose => 'Close';

  @override
  String showSellerAmount(String amount) {
    return '$amount บาท';
  }

  @override
  String haggleOfferMeaning(String amount) {
    return 'Could you do $amount baht?';
  }

  @override
  String haggleAcceptMeaning(String amount) {
    return 'OK, $amount baht. It\'s a deal.';
  }

  @override
  String get haggleLeaveMeaning => 'No thanks, maybe another time.';

  @override
  String get billShop => 'Shop';

  @override
  String get billCategory => 'Suggested category';

  @override
  String get billCategoryGoogle =>
      'Based on this place\'s category in Google Maps';

  @override
  String get billCategoryName =>
      'No place type matched; the shop-name guess may be wrong';

  @override
  String get billCategoryManual => 'Category chosen by you';

  @override
  String get billCategoryEdit => 'Choose a category';

  @override
  String get spendFood => 'Food and drink';

  @override
  String get spendTransport => 'Transport';

  @override
  String get spendShopping => 'Shopping';

  @override
  String get spendLodging => 'Lodging';

  @override
  String get spendOther => 'Other';

  @override
  String get billShopUnknown => 'Not read';

  @override
  String get billYourRecord => 'Your record';

  @override
  String get billSave => 'Save to my records';

  @override
  String get billSaved => 'Saved';

  @override
  String get billEdit => 'Edit';

  @override
  String get billEnterIt => 'Enter it yourself';

  @override
  String get billEditTitle => 'Your version of this bill';

  @override
  String get billServiceNone => 'No service charge';

  @override
  String get billServiceIncludedChoice => 'Service included';

  @override
  String get billServicePercentLabel => 'Service charge';

  @override
  String get billUseCorrection => 'Use these figures';

  @override
  String get billCorrectedNote =>
      'Your correction. It is saved as yours, not as checked by the app.';

  @override
  String billMemoryVisits(int visits, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      visits,
      locale: localeName,
      other: 'You saved $visits bills here before. Last time $total',
      one: 'You saved 1 bill here before. Last time $total',
    );
    return '$_temp0';
  }

  @override
  String billMemoryNote(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count earlier bills here you noted $note',
      one: 'Last time here you noted $note',
    );
    return '$_temp0';
  }

  @override
  String get billNoteServiceIncluded => 'service was included';

  @override
  String billNoteServiceAdded(String percent) {
    return 'service $percent % was added';
  }

  @override
  String get billNoteNoService => 'no service charge';

  @override
  String get tabAssistant => 'Assistant';

  @override
  String get homeRouteNext => 'Next stop';

  @override
  String get homeRouteAtm => 'ATM';

  @override
  String get homeRouteMarket => 'Market';

  @override
  String get homeRouteTerminal => 'Card terminal';

  @override
  String get homeBriefingLabel => 'Morning briefing';

  @override
  String get homeBriefingOpen => 'Open the assistant';

  @override
  String get homeBriefingEmpty => 'No stops planned today';

  @override
  String homeBriefingStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops on your calendar today',
      one: '1 stop on your calendar today',
    );
    return '$_temp0';
  }

  @override
  String homeBriefingMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more stops',
      one: '1 more stop',
    );
    return '$_temp0';
  }

  @override
  String get nearbyLabel => 'Watch out nearby';

  @override
  String get nearbyOpen => 'See every warning nearby';

  @override
  String get nearbyMapLabel => 'Open ATM map';

  @override
  String nearbyMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more warnings nearby',
      one: '1 more warning nearby',
    );
    return '$_temp0';
  }

  @override
  String get nearbyNeedLocation => 'See money traps near you';

  @override
  String get nearbyLocationPrivacy =>
      'Uses your location only while the app is open';

  @override
  String get nearbyLooking => 'Checking ATMs and markets nearby';

  @override
  String get nearbyClear => 'Nothing to watch out for nearby';

  @override
  String get nearbyClearBasis =>
      'From ATMs and markets Google Maps lists near you';

  @override
  String get trapAtmFeeTitle => 'Foreign cards pay a fee at ATMs here';

  @override
  String trapAtmFeeBody(String fee, String where) {
    return 'For example $fee at $where. Other banks differ, so take out more at once.';
  }

  @override
  String get trapAtmConversionTitle => 'ATMs here may offer to convert';

  @override
  String get trapAtmConversionBody => 'Choose the local currency, not your own';

  @override
  String get trapCashOnlyTitle => 'Cash only';

  @override
  String get trapCashOnlyBody => 'Bring cash before you go';

  @override
  String get briefingCashOnly => 'Cash only';

  @override
  String get briefingCardsOk => 'Takes cards';

  @override
  String get briefingPayUnknown => 'Payment not listed on Google Maps';

  @override
  String briefingLastSpent(String amount) {
    return 'You spent $amount here last time';
  }

  @override
  String briefingLastSpentSample(String amount) {
    return 'Sample record · $amount here last time';
  }

  @override
  String briefingPlaceDistance(String place, String meters) {
    return '$place · $meters m';
  }

  @override
  String briefingSourceLive(String source) {
    return '$source · live';
  }

  @override
  String briefingSourceChecked(String source, String date) {
    return '$source · checked $date';
  }

  @override
  String get assistantTitle => 'Assistant';

  @override
  String get assistantStops => 'Today\'s stops';

  @override
  String get assistantPay => 'Card, cash or QR';

  @override
  String assistantPayFor(String place) {
    return 'Compared for $place';
  }

  @override
  String get assistantCard => 'Your card';

  @override
  String get assistantCardFooter =>
      'Saved on this phone. Your bank\'s fee page has these numbers.';

  @override
  String get assistantCardFromAccount => 'Card fee from your account profile';

  @override
  String get assistantNearby => 'Near you';

  @override
  String get assistantArrival => 'Arrival alert';

  @override
  String get calendarConnect => 'Read today\'s calendar';

  @override
  String get calendarDenied => 'Calendar access is off in Settings';

  @override
  String get calendarPrivacy =>
      'Title, place and time only. Nothing is changed.';

  @override
  String get calendarReading => 'Reading today\'s calendar';

  @override
  String get calendarNoStops => 'No stops with a place on your calendar today';

  @override
  String get payCompareLabel => 'Cheapest way to pay';

  @override
  String get payCompareAsk => 'Type an amount to compare';

  @override
  String get payCompareAmountHint => 'Amount';

  @override
  String get payCompareBestCard => 'Pay by card';

  @override
  String get payCompareBestCash => 'Pay in cash';

  @override
  String get payCompareBestQr => 'Pay by QR';

  @override
  String get payCompareSame => 'Card and cash cost about the same';

  @override
  String get payCompareCashOnly => 'Cash only here';

  @override
  String get payCompareNeedCard => 'Add your card\'s foreign fee to compare';

  @override
  String get payCompareNeedWithdrawal =>
      'Cash depends on how much you take out at once';

  @override
  String payCompareNoRate(String currency) {
    return 'Waiting for today\'s $currency rate';
  }

  @override
  String payCompareBreakEven(String amount) {
    return 'Cash costs less than the card only when you take out $amount or more at once';
  }

  @override
  String payCompareAtmFeeSource(String fee, String source) {
    return 'Cash priced with a $fee ATM fee ($source). Other banks differ.';
  }

  @override
  String get payCompareNoAtmFee =>
      'No published ATM fee for foreign cards here, so cash is not priced';

  @override
  String get payCompareDemoRate => 'fixed demo rate';

  @override
  String get payCard => 'Card';

  @override
  String get payCash => 'Cash from an ATM';

  @override
  String get payQr => 'QR';

  @override
  String payExtra(String amount) {
    return '+$amount';
  }

  @override
  String get payNotTaken => 'Not taken here';

  @override
  String get payNeedCardFee => 'Add your card fee';

  @override
  String get payNeedWithdrawal => 'Depends on the withdrawal';

  @override
  String get payNoQrFee => 'No published fee';

  @override
  String get cardFeeRow => 'Foreign transaction fee';

  @override
  String get cardFeeMissing => 'Not added yet';

  @override
  String get cardAtmRow => 'Your bank at foreign ATMs';

  @override
  String get cardAtmUnknown => 'Not sure';

  @override
  String get cardAtmNoFee => 'No fee';

  @override
  String get cardAtmRefunds => 'Refunds ATM fees';

  @override
  String cardAtmFixed(String currency) {
    return 'Fixed fee in $currency';
  }

  @override
  String get cardAtmPercent => 'Percent of the withdrawal';

  @override
  String cardAtmFixedValue(String amount) {
    return '$amount each time';
  }

  @override
  String cardAtmPercentValue(String percent) {
    return '$percent of each withdrawal';
  }

  @override
  String get cardSheetTitle => 'Your card';

  @override
  String get cardCatalogTitle => 'Choose a card';

  @override
  String get cardCatalogOther => 'Other card / enter details yourself';

  @override
  String get cardCatalogUtopia => 'U-topia U-Card · Visa';

  @override
  String get cardCatalogUtopiaFacts =>
      'U-topia describes virtual and physical Visa cards, spending alerts, freeze/unfreeze, and custom spending limits.';

  @override
  String get cardCatalogUtopiaFeeNote =>
      'Its card terms dated May 20, 2026 list up to 1.5% foreign-exchange and up to 1.5% cross-border fees. These are separate fees, so they are not copied into the single fee field below.';

  @override
  String get cardCatalogUtopiaIssuerNote =>
      'U-topia\'s public documents name different card providers: the May 20 card terms say Third National, while the privacy policy updated October 6 names Rain. Check the current terms in your U-topia account before using fee comparisons.';

  @override
  String get cardCatalogSource => 'Open U-topia card terms';

  @override
  String get cardCatalogProductSource => 'Open U-topia product page';

  @override
  String get cardFeeLabel => 'Foreign transaction fee';

  @override
  String get cardFeeHintThai =>
      'Thai banks publish up to 2.5% (Kasikorn, ttb fee lists 2025-2026)';

  @override
  String get cardFeeHintOther => 'Your card\'s terms list the exact fee.';

  @override
  String get cardAtmLabel => 'What your bank charges at a foreign ATM';

  @override
  String get cardFeeInvalid => 'Use a number from 0 to 20';

  @override
  String get cardAtmValueInvalid => 'Add the fee amount';

  @override
  String get cardSheetPrivacy =>
      'Only these numbers are kept. Never your card number.';

  @override
  String get cardSheetSave => 'Save card facts';

  @override
  String get arrivalOn => 'On for your next arrival';

  @override
  String get arrivalOnBody =>
      'When your phone lands in a country with another currency, you get one alert on which currency to pick';

  @override
  String get arrivalAllow => 'Allow notifications';

  @override
  String get arrivalBlocked => 'Notifications are off in Settings';

  @override
  String get arrivalDemoTrigger => 'Demo · Land in Japan';

  @override
  String get arrivalDemoFooter =>
      'Demo state only. Shows the same alert your phone\'s location would.';

  @override
  String arrivalShownDemo(String body) {
    return 'Demo · $body';
  }

  @override
  String arrivalTitle(String country) {
    return 'Landed in $country';
  }

  @override
  String arrivalBody(String local, String home) {
    return 'If a card machine asks $home or $local, pick $local';
  }

  @override
  String arrivalBodyAtm(String local, String home) {
    return 'If a card machine or ATM asks $home or $local, pick $local';
  }

  @override
  String get arrivalChannel => 'Arrival alerts';

  @override
  String get countryJapan => 'Japan';

  @override
  String get countryThailand => 'Thailand';

  @override
  String billMemoryNoteBranch(String note, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'At other branches you noted $note in $count bills',
      one: 'At another branch you noted $note',
    );
    return '$_temp0';
  }

  @override
  String billBrandMemory(String habit, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Other branches of this shop had $habit ($count receipts)',
      one: 'Another branch of this shop had $habit (1 receipt)',
    );
    return '$_temp0';
  }

  @override
  String get billBrandServiceAdded => 'service charge added';

  @override
  String get tripMapTitle => 'Trip map';

  @override
  String get tripMapEmpty =>
      'Receipts and haggles you save with a place show up here.';

  @override
  String tripMapKeptDay(String amount) {
    return 'Kept $amount';
  }

  @override
  String tripMapKept(String amount) {
    return 'Kept $amount';
  }

  @override
  String get tripMapSample => 'Sample';

  @override
  String get tripMapCorrected => 'Your correction';

  @override
  String get tripMapKindReceipt => 'Receipt';

  @override
  String get tripMapKindHaggle => 'Haggle';

  @override
  String get tripMapKindAtm => 'ATM';

  @override
  String get tripMapKindTerminal => 'Card terminal';

  @override
  String tripMapKeptAt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return 'Kept at $_temp0';
  }

  @override
  String get tripMapOnMap => 'On the map';

  @override
  String tripMapPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get tripMapToday => 'Today';

  @override
  String get tripMapYesterday => 'Yesterday';

  @override
  String tripMapPaid(String amount) {
    return 'Paid $amount';
  }

  @override
  String get tripMapClose => 'Close';

  @override
  String get tripMapOffline =>
      'The map needs a connection. Every place is still listed below.';

  @override
  String get tripMapEmptyAction => 'Scan a receipt';

  @override
  String tripMapMapLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return 'Map with $_temp0. Each one is also in the list below.';
  }

  @override
  String get tripMapShowOnMap => 'Shows it on the map';

  @override
  String tripMapNear(String place) {
    return 'Near $place';
  }

  @override
  String billTotalInvalid(String max) {
    return 'Enter a total above 0 and up to $max';
  }

  @override
  String trapAtmFeeBodyPlain(String fee) {
    return 'For example $fee per withdrawal. Take out more at once.';
  }

  @override
  String get arrivalOff => 'Off until notifications are allowed';

  @override
  String get nearbyDemoOff => 'Off in the demo state';

  @override
  String get nearbyDemoOffBody =>
      'Warnings nearby come from where your phone really is';

  @override
  String get payCompareNeedBank =>
      'Add what your bank charges at foreign ATMs to compare with cash';

  @override
  String get payCompareWithdrawalAssumed =>
      'Cash assumes you take out just this amount';

  @override
  String payCompareWithdrawalPlan(String amount) {
    return 'Cash assumes one withdrawal of about $amount, today\'s estimate';
  }

  @override
  String aiHeardBy(String engine, String elapsed) {
    return 'Heard by $engine · $elapsed';
  }

  @override
  String get speakWordsAfter => 'Their words appear when they finish';

  @override
  String get speakReading => 'Reading what they said';

  @override
  String get assistantFacts => 'Facts checked online';

  @override
  String factsSummary(int checked, int updated, int unchanged, int kept) {
    return '$checked checked today · $updated updated · $unchanged unchanged · $kept kept';
  }

  @override
  String get factsNotToday => 'Not checked yet today';

  @override
  String factsOffline(String date) {
    return 'Offline, showing the copy from $date';
  }

  @override
  String get factsFooter =>
      'Gemini reads each page once a day. A figure is used only when its sentence appears word for word on that page.';

  @override
  String get factThAtmVisa => 'ATM fee, Kasikorn K-ATM, Visa';

  @override
  String get factThAtmMastercard => 'ATM fee, Kasikorn K-ATM, Mastercard';

  @override
  String get factMangoLowest => 'Mango, lowest wholesale price today';

  @override
  String get factUpdated => 'Read from the page today';

  @override
  String get factUnchanged => 'Same as before, checked today';

  @override
  String get factKeptBlocked =>
      'Kept the last value, the site blocks automated reads';

  @override
  String get factKeptNoMatch =>
      'Kept the last value, the figure was not found word for word';

  @override
  String get factKeptOther => 'Kept the last value, the page could not be read';

  @override
  String get factNew => 'Researched by hand, not checked online yet';

  @override
  String factSourceLine(String host, String time) {
    return '$host · checked $time';
  }

  @override
  String get recordsSwipeHint => 'Swipe a row left to remove it.';

  @override
  String get recordsSavedPhone => 'Saved only on this phone.';

  @override
  String get recordsSavedAccount => 'Saved to your account too.';

  @override
  String get recordsSavedDemo =>
      'Demo records stay in the demo and never reach your account.';

  @override
  String get haggleNoRange => 'No sourced price range for this item yet';

  @override
  String haggleNewItemHeard(String item, String amount, String unit) {
    return '$item, $amount $unit';
  }

  @override
  String get haggleUsualDiscountRow => 'Your usual discount';

  @override
  String haggleDidTheyMean(String item) {
    return 'Did they mean $item?';
  }

  @override
  String get haggleYes => 'Yes';

  @override
  String get haggleNo => 'No';

  @override
  String aiNewItemLine(String engine, String elapsed) {
    return '$engine named the item from what was heard · $elapsed';
  }

  @override
  String get haggleSomethingElse => 'Something else';

  @override
  String get haggleTypeItem => 'What are they selling?';

  @override
  String get haggleTypeItemHint => 'e.g. Vanilla latte';

  @override
  String get calendarSample => 'Sample calendar';

  @override
  String get haggleCheckingPrices => 'Checking prices online…';

  @override
  String haggleWebRange(String low, String high, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $low–$high THB on $count web pages',
      one: 'About $low–$high THB on 1 web page',
    );
    return '$_temp0';
  }

  @override
  String haggleWebQuote(String quote, String site, String date) {
    return '“$quote” · $site · $date';
  }

  @override
  String haggleReadOn(String date) {
    return 'read $date';
  }

  @override
  String get atmMapTitle => 'ATMs nearby';

  @override
  String get atmMapNearest => 'Nearest ATM';

  @override
  String atmMapMeters(String meters) {
    return '$meters m';
  }

  @override
  String atmMapAway(String meters) {
    return '$meters m away';
  }

  @override
  String atmMapMapLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ATMs',
      one: '1 ATM',
    );
    return 'Map with $_temp0. Each one is also in the list below.';
  }

  @override
  String get atmMapDirections => 'Directions';

  @override
  String atmMapDirectionsTo(String place) {
    return 'Walking directions to $place';
  }

  @override
  String get atmMapLooking => 'Looking for ATMs near you';

  @override
  String get atmMapNeedLocation => 'Allow location to see ATMs near you';

  @override
  String get atmMapLocationSettings =>
      'Location is off for this app. Turn it on in Settings.';

  @override
  String get atmMapEmpty =>
      'Google Maps returned no ATMs here. Check the connection, or search in Google Maps.';

  @override
  String get atmMapSearchMaps => 'Search in Google Maps';

  @override
  String get atmMapSource =>
      'Places from Google Maps · distances in a straight line';

  @override
  String get atmMapDemoOrigin =>
      'Around the first stop of the sample calendar, not where your phone is';

  @override
  String get atmMapList => 'Nearest first';

  @override
  String get atmMapRetry => 'Search again';

  @override
  String get cashWalletNegative =>
      'More cash was recorded as spent than you had. Update your balance.';

  @override
  String cashWalletLastMove(String what, String amount, String when) {
    return 'Last: $what $amount · $when';
  }

  @override
  String get recordKeptHero => 'Kept by this choice';

  @override
  String get recordReceiptHero => 'Receipt total';

  @override
  String get recordCashAdded => 'Added to cash on hand';

  @override
  String get recordCashSpent => 'Paid from cash on hand';

  @override
  String get recordCashNone => 'Cash on hand did not change';

  @override
  String get recordCashNoneBody =>
      'Paid by card, or saved without a payment method';

  @override
  String recordCashNow(String amount) {
    return 'Cash on hand now: $amount';
  }

  @override
  String get recordOpenInMaps => 'Open in Google Maps';

  @override
  String get recordNoFigures =>
      'This record was saved before the screen\'s figures were kept.';

  @override
  String get recordSellerPrices => 'Seller\'s prices';

  @override
  String get recordYourOffers => 'Your offers';

  @override
  String get recordItem => 'Item';

  @override
  String get recordSample => 'Sample record of the demo traveler';

  @override
  String get recordPhoto => 'Receipt photo';

  @override
  String get recordPhotoOpen => 'Open the receipt photo full screen';

  @override
  String get recordWhere => 'Where';

  @override
  String get recordChecks => 'What was read';

  @override
  String get exchangeRefresh => 'Refresh rates';

  @override
  String get exchangeEnterAmount =>
      'Enter an amount to compare nearby counters';

  @override
  String get exchangeRecordFailed =>
      'Couldn\'t add this to Cash on hand. Try again.';
}
