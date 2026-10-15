// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appName => 'Money Navigation';

  @override
  String get scanHint => 'วางหน้าจอตู้ ATM ให้อยู่ในกรอบ';

  @override
  String get scanShutter => 'ถ่ายรูป';

  @override
  String get scanChoosePhoto => 'เลือกรูป';

  @override
  String get scanClose => 'ปิด';

  @override
  String get scanFlashOn => 'เปิดไฟ';

  @override
  String get scanFlashOff => 'ปิดไฟ';

  @override
  String get scanCameraUnavailable => 'ใช้กล้องไม่ได้ในตอนนี้';

  @override
  String get scanCameraDenied =>
      'Money Navigation ยังไม่ได้รับสิทธิ์ใช้กล้อง เปิดได้ในการตั้งค่า หรือเลือกรูปแทน';

  @override
  String get stepReadText => 'กำลังอ่านรูป';

  @override
  String stepReadTextDone(int ms) {
    return 'อ่านบนมือถือเสร็จใน $ms มิลลิวินาที';
  }

  @override
  String get stepFindAtm => 'กำลังหาข้อเสนอแปลงสกุลเงินของตู้ ATM';

  @override
  String get stepFindAtmDone => 'พบข้อเสนอแปลงสกุลเงินของตู้ ATM';

  @override
  String stepValues(String withdrawal, String fee, String rate) {
    return 'ถอน $withdrawal · ค่าธรรมเนียม $fee · 1 USD = $rate THB';
  }

  @override
  String stepValuesMarkup(String values, String markup) {
    return '$values · บวกเพิ่ม $markup';
  }

  @override
  String get stepCompare => 'กำลังเทียบยอดทั้งสองแบบ';

  @override
  String stepCompareDone(String amount) {
    return 'ถ้าแปลงสกุลเงินจะจ่ายเพิ่มประมาณ $amount';
  }

  @override
  String get stepCompareEven => 'ยอดทั้งสองแบบใกล้เคียงกัน';

  @override
  String get scanTryAgain => 'ลองอีกครั้ง';

  @override
  String get atmKeepLabel => 'ประหยัดได้ประมาณ';

  @override
  String get atmPress => 'กด';

  @override
  String get atmDeclineButton =>
      'ตัวเลือกที่ไม่แปลงสกุลเงิน เพื่อจ่ายเป็นเงินบาท';

  @override
  String atmReasonMarkup(String markup) {
    return 'อัตราของตู้ ATM บวกเพิ่ม $markup';
  }

  @override
  String get atmReasonNoMarkup => 'อัตราของตู้ ATM แพงกว่าอัตราที่แสดงบนหน้าจอ';

  @override
  String atmSource(String time) {
    return 'จากตัวเลขบนหน้าจอตู้ ATM นี้ · $time';
  }

  @override
  String get atmEvenTitle => 'เลือกแบบไหนก็จ่ายใกล้เคียงกัน';

  @override
  String get atmEvenBody =>
      'ยอดที่แปลงแล้วตรงกับอัตราบนหน้าจอ จึงไม่มีส่วนที่ประหยัดได้';

  @override
  String get stepFindAtmFailed =>
      'ไม่พบตัวเลือกสกุลเงินหรือป้ายอัตราแลกเปลี่ยน';

  @override
  String get stepReadTextFailed => 'ไม่พบตัวอักษร';

  @override
  String get stepValuesFailed => 'อ่านตัวเลขบางส่วนไม่ได้';

  @override
  String get scanTipNoText => 'ขยับเข้าไปใกล้ขึ้นให้หน้าจอเต็มรูป';

  @override
  String get scanTipNotAtm =>
      'เล็งตรงไปที่หน้าจอที่ให้เลือกสองสกุลเงิน หรือป้ายอัตราแลกเปลี่ยน';

  @override
  String get scanTipLooksLikeBill => 'รูปนี้ดูเหมือนบิล กดตรวจบิลนี้ได้เลย';

  @override
  String get scanTipMissingValues =>
      'ถือมือถือให้ตรงและเลี่ยงแสงสะท้อนบนหน้าจอ';

  @override
  String get atmBothTotals => 'ยอดทั้งสองแบบ';

  @override
  String get atmIfConvertDetail => 'ใช้อัตราของตู้ ATM';

  @override
  String get atmIfNotConvertDetail => 'ธนาคารของบัตรเป็นผู้แปลง';

  @override
  String get atmOnScreen => 'บนหน้าจอนี้';

  @override
  String get atmRowWithdrawal => 'ยอดถอน';

  @override
  String get atmRowFee => 'ค่าธรรมเนียมตู้ ATM';

  @override
  String get atmRowRate => 'อัตราที่แสดง';

  @override
  String get atmRowMarkup => 'ส่วนบวกเพิ่มที่แสดง';

  @override
  String atmRateValue(String rate) {
    return '1 USD = $rate THB';
  }

  @override
  String get atmIfConvert => 'ถ้าแปลงสกุลเงิน';

  @override
  String get atmIfNotConvert => 'ถ้าไม่แปลง';

  @override
  String get atmScanAnother => 'สแกนอีกครั้ง';

  @override
  String get speakOpen => 'ฟังราคา';

  @override
  String get speakListening => 'กำลังฟัง';

  @override
  String get speakListenHint => 'ยื่นมือถือไปทางผู้ขาย';

  @override
  String get speakStop => 'ฟังเสร็จแล้ว';

  @override
  String get speakListenAgain => 'ฟังอีกครั้ง';

  @override
  String get speakTypeSubmit => 'ตรวจราคานี้';

  @override
  String get speakHeard => 'ผู้ขายพูดว่า';

  @override
  String speakMeaning(String item, String amount, String unit) {
    return '$item $amount $unit';
  }

  @override
  String get unitPerKg => 'ต่อกิโล';

  @override
  String get unitEach => 'ต่อชิ้น';

  @override
  String get unitPerPlate => 'ต่อจาน';

  @override
  String get unitPerHour => 'ต่อชั่วโมง';

  @override
  String get unitPerRide => 'ต่อเที่ยว';

  @override
  String get verdictHigh => 'แพง';

  @override
  String get verdictFair => 'ราคาปกติ';

  @override
  String get verdictLow => 'ถูก';

  @override
  String speakOverBy(String amount) {
    return 'แพงกว่าราคาปกติ $amount';
  }

  @override
  String get speakFairBody => 'อยู่ในช่วงราคาปกติ';

  @override
  String get speakLowBody => 'ถูกกว่าราคาปกติ';

  @override
  String get speakUsualPrice => 'ราคาปกติ';

  @override
  String speakUsualRange(String low, String high, String unit) {
    return '$low–$high บาท $unit';
  }

  @override
  String get speakAsked => 'ราคาที่ขอ';

  @override
  String speakSources(int count, String month) {
    return '$count แหล่ง · $month';
  }

  @override
  String get speakCounterLabel => 'ขอเป็น';

  @override
  String speakCounterAmount(String amount) {
    return '$amount บาท';
  }

  @override
  String get speakSayIt => 'พูดเป็นภาษาไทย';

  @override
  String get speakSpeaking => 'กำลังพูด';

  @override
  String get speakNoVoice => 'มือถือนี้ไม่มีเสียงภาษาไทย ให้ผู้ขายดูประโยคแทน';

  @override
  String counterOfferSentence(String amount, String ending) {
    return 'ลดเหลือ $amount บาทได้ไหม$ending';
  }

  @override
  String get speakNothingHeard => 'ไม่ได้ยินอะไร';

  @override
  String get speakNothingHeardTip =>
      'เข้าไปใกล้ผู้ขายแล้วลองอีกครั้ง หรือพิมพ์สิ่งที่ได้ยิน';

  @override
  String get speakNoPrice => 'ไม่ได้ยินราคา';

  @override
  String get speakNoPriceTip => 'ถามราคาผู้ขายอีกครั้งแล้วกดฟัง';

  @override
  String get speakUnknownItem => 'ยังไม่มีราคาปกติของสินค้านี้';

  @override
  String speakUnknownItemTip(String amount) {
    return 'ราคาคือ $amount เราเทียบเฉพาะสินค้าที่มีแหล่งข้อมูล';
  }

  @override
  String get speakUnitMismatch => 'ราคานี้เป็นหน่วยอื่น';

  @override
  String speakUnitMismatchTip(String unit) {
    return 'ราคาปกติคิด$unit ลองถามราคา$unit';
  }

  @override
  String get speakEnterPrice => 'ใส่ราคา';

  @override
  String get speakEnterTitle => 'ผู้ขายขอเท่าไร';

  @override
  String get speakPickItem => 'สินค้า';

  @override
  String get speakPriceLabel => 'ราคา (บาท)';

  @override
  String get speakEntered => 'คุณใส่ว่า';

  @override
  String get speakPreparing => 'กำลังเตรียม';

  @override
  String get speakUsualRangeRow => 'ช่วงราคาปกติ';

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
  String get speakWhichItem => 'ผู้ขายขายอะไร';

  @override
  String speakHeardPrice(String price) {
    return 'ได้ยินว่า $price';
  }

  @override
  String get tabHome => 'หน้าหลัก';

  @override
  String get tabScan => 'สแกน';

  @override
  String get tabSpeak => 'ฟังราคา';

  @override
  String get tabRecords => 'บันทึก';

  @override
  String get back => 'กลับ';

  @override
  String get homeKeptLabel => 'เงินที่ประหยัดได้ในทริปนี้';

  @override
  String homeKeptApprox(String amount) {
    return 'ประมาณ $amount';
  }

  @override
  String ratePair(String from, String rate, String to) {
    return '1 $from = $rate $to';
  }

  @override
  String homeRateSource(String pair, String date) {
    return '$pair วันที่ $date · ธนาคารกลางยุโรป ผ่าน Frankfurter';
  }

  @override
  String homeRateCached(String pair, String date) {
    return '$pair วันที่ $date · ธนาคารกลางยุโรป ผ่าน Frankfurter · ค่าล่าสุด ออฟไลน์อยู่';
  }

  @override
  String get homeRateLoading => 'กำลังดึงอัตราแลกเปลี่ยนวันนี้';

  @override
  String homeRateUnavailable(String currency) {
    return 'ต้องต่ออินเทอร์เน็ตเพื่อดูอัตรา $currency วันนี้';
  }

  @override
  String get homeRecent => 'บันทึกล่าสุด';

  @override
  String get homeSeeAll => 'ดูทั้งหมด';

  @override
  String get homeEmptyLabel => 'ก่อนกดถอนเงิน';

  @override
  String get homeEmptyTitle => 'สแกนหน้าจอ ATM ก่อนกดปุ่มใดๆ';

  @override
  String get homeEmptyAction => 'เปิดกล้องสแกน';

  @override
  String saveKeptValue(String amount) {
    return '+$amount';
  }

  @override
  String get saveAtmTitle => 'ไม่โดนค่าแปลงสกุลเงินที่ ATM';

  @override
  String saveHaggleTitle(String item) {
    return 'ต่อราคา$itemได้';
  }

  @override
  String saveHaggleSubtitle(String paid, String when) {
    return 'จ่าย $paid · $when';
  }

  @override
  String get saveHaggleUnknownItem => 'ราคาตลาด';

  @override
  String get saveToTrip => 'บันทึกในทริป';

  @override
  String get savedToTrip => 'บันทึกแล้ว';

  @override
  String get recordsTitle => 'บันทึก';

  @override
  String get recordsEmpty =>
      'ยังไม่มีบันทึก ผลที่บันทึกหลังสแกนหรือต่อราคาจะแสดงที่นี่';

  @override
  String get recordsRemove => 'ลบ';

  @override
  String get recordsFooter =>
      'ปัดแถวไปทางซ้ายเพื่อลบ บันทึกไว้ในเครื่องนี้เท่านั้น';

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get settingsCurrency => 'สกุลเงินของคุณ';

  @override
  String get settingsChange => 'เปลี่ยน';

  @override
  String get settingsCurrencyFooter =>
      'ยอดรวมจะแสดงเป็นสกุลเงินนี้ด้วย ตามอัตรารายวันจาก Frankfurter (ธนาคารกลางยุโรป)';

  @override
  String get settingsSpeaking => 'การพูดภาษาไทยแทนคุณ';

  @override
  String get settingsEndingMale => 'ลงท้ายด้วย ครับ';

  @override
  String get settingsEndingFemale => 'ลงท้ายด้วย คะ';

  @override
  String get settingsEndingNone => 'ไม่ลงท้าย';

  @override
  String get settingsSpeakingFooter =>
      'คนไทยลงท้ายคำขอสุภาพด้วย ครับ (ผู้ชาย) หรือ คะ (ผู้หญิง)';

  @override
  String get politeEndingMale => 'ครับ';

  @override
  String get politeEndingFemale => 'คะ';

  @override
  String get currencyOffline => 'ต่ออินเทอร์เน็ตเพื่อโหลดรายการสกุลเงิน';

  @override
  String get currencySource =>
      'สกุลเงินที่มีอัตราอ้างอิงรายวันจากธนาคารกลางยุโรป';

  @override
  String get haggleSaveTitle => 'คุณจ่ายไปเท่าไร';

  @override
  String get haggleSaveOffer => 'ราคาที่คุณต่อ';

  @override
  String get haggleSaveAsked => 'ราคาที่เขาบอก';

  @override
  String get haggleSaveOther => 'จำนวนอื่น';

  @override
  String haggleSaveKeeps(String amount) {
    return 'ประหยัด $amount';
  }

  @override
  String settingsEndingExample(String ending) {
    return '…ได้ไหม$ending';
  }

  @override
  String haggleSaveTooHigh(String amount) {
    return 'ใส่น้อยกว่า $amount ซึ่งเป็นราคาที่เขาบอก';
  }

  @override
  String get speakDeniedTitle => 'ไมโครโฟนปิดอยู่';

  @override
  String get speakDeniedBody =>
      'เปิดไมโครโฟนให้ Money Navigation ในการตั้งค่า หรือใส่ราคาเอง';

  @override
  String get speakUnavailableTitle => 'ฟังภาษาไทยไม่ได้';

  @override
  String get speakUnavailableBody =>
      'มือถือนี้ฟังเสียงภาษาไทยไม่ได้ ใส่ราคาเองแทน';

  @override
  String get speakOpenSettings => 'เปิดการตั้งค่า';

  @override
  String speakAmountUnit(String amount, String unit) {
    return '$amount $unit';
  }

  @override
  String haggleSaveChoice(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get speakPriceInvalid => 'ใส่เป็นตัวเลข เช่น 150';

  @override
  String speakPriceTooHigh(String amount) {
    return 'ใส่ได้ไม่เกิน $amount';
  }

  @override
  String get haggleSaveNothingKept =>
      'จ่ายตามราคาที่เขาบอก ไม่มีเงินที่ประหยัดได้';

  @override
  String get recordsRemoved => 'ลบออกจากทริปแล้ว';

  @override
  String get recordsUndo => 'เลิกทำ';

  @override
  String aiTrace(String engine, String elapsed) {
    return 'ตรวจโดย $engine · $elapsed';
  }

  @override
  String aiVoiceCached(String engine) {
    return 'เสียงจาก $engine เก็บไว้ในเครื่องนี้';
  }

  @override
  String aiItemMatched(
    String engine,
    String item,
    String confidence,
    String elapsed,
  ) {
    return '$engine จับคู่สิ่งที่ได้ยินเป็น $item มั่นใจ $confidence · $elapsed';
  }

  @override
  String aiPlacesLine(
    String engine,
    String place,
    String rating,
    String reviews,
    String elapsed,
  ) {
    return '$engine · $place $rating ($reviews รีวิว) · $elapsed';
  }

  @override
  String get billOpen => 'ตรวจบิล';

  @override
  String get billStartTitle => 'ตรวจบิลร้านอาหาร';

  @override
  String get billStartBody =>
      'ถ่ายรูปบิลทั้งใบ Google Cloud Vision อ่านภาษาไทย แล้วมือถือตรวจว่าตัวเลขทุกตัวรวมกันถูกต้อง และบอกว่ามีอะไรบวกเพิ่ม';

  @override
  String get billTake => 'ถ่ายรูป';

  @override
  String get billTakeAnother => 'บิลใบอื่น';

  @override
  String get billChoose => 'เลือกรูป';

  @override
  String get billReading => 'กำลังอ่านบิล';

  @override
  String billReadingBody(String engine) {
    return '$engine กำลังอ่านข้อความภาษาไทย จากนั้นมือถือจะตรวจตัวเลข';
  }

  @override
  String get billTotalLabel => 'ยอดรวมของบิลนี้';

  @override
  String get billServiceChip => 'มีค่าบริการบวกเพิ่ม';

  @override
  String get billVatOnTopChip => 'บวก VAT เพิ่ม';

  @override
  String get billVatInsideChip => 'รวม VAT แล้ว';

  @override
  String get billNothingAddedChip => 'ไม่มีการบวกเพิ่ม';

  @override
  String get billHowBuilt => 'ยอดรวมมาจากอะไร';

  @override
  String get billInsideTotal => 'รวมอยู่ในยอดแล้ว';

  @override
  String get billSubtotal => 'ยอดก่อนส่วนลด';

  @override
  String billItems(int count) {
    return '$count รายการ';
  }

  @override
  String get billDiscount => 'ส่วนลด';

  @override
  String get billService => 'ค่าบริการ';

  @override
  String billServicePercent(String percent) {
    return 'ค่าบริการ $percent%';
  }

  @override
  String get billVat => 'VAT';

  @override
  String billVatPercent(String percent) {
    return 'VAT $percent%';
  }

  @override
  String get billAddedOnTop => 'บวกเพิ่ม';

  @override
  String get billAlreadyIncluded => 'รวมอยู่แล้ว ไม่ได้จ่ายเพิ่ม';

  @override
  String get billTotal => 'ยอดรวม';

  @override
  String get billBeforeVat => 'ก่อน VAT';

  @override
  String get billProof => 'ตรวจแล้วว่าตัวเลขทุกตัวในบิลนี้รวมกันลงตัว';

  @override
  String billVisionTrace(String engine, int lines, String elapsed) {
    return 'อ่านโดย $engine · $lines บรรทัด · $elapsed';
  }

  @override
  String get billOfflineTitle => 'ไม่มีอินเทอร์เน็ต';

  @override
  String get billOfflineBody =>
      'การอ่านภาษาไทยต้องใช้อินเทอร์เน็ต เชื่อมต่อแล้วถ่ายใหม่';

  @override
  String get billTooLargeTitle => 'รูปใหญ่เกินไป';

  @override
  String get billTooLargeBody => 'ถ่ายใหม่จากหน้านี้ ระบบจะส่งรูปที่เล็กลงให้';

  @override
  String get billNoTextTitle => 'ไม่พบข้อความ';

  @override
  String get billNoTextBody => 'ถ่ายให้บิลเต็มกรอบ แสงพอ แล้วลองอีกครั้ง';

  @override
  String get billNoMatchTitle => 'ตรวจบิลนี้ไม่ได้';

  @override
  String get billNoMatchBody =>
      'อ่านข้อความได้ แต่ตัวเลขรวมกันไม่ลงตัวพอจะยืนยัน จึงไม่แสดงตัวเลขที่เดา ลองถ่ายบิลทั้งใบให้ชัดขึ้น';

  @override
  String get billServiceTitle => 'อ่านบิลไม่สำเร็จ';

  @override
  String get billServiceBody => 'ลองใหม่อีกครั้งในอีกสักครู่';

  @override
  String get authWelcomeTitle => 'รู้ก่อนจ่ายว่าควรจ่ายทางไหน';

  @override
  String get authWelcomeBody =>
      'เข้าสู่ระบบเพื่อเก็บบันทึกการเดินทางไว้ใช้ได้ทุกเครื่อง';

  @override
  String get authContinueApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get authContinueGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get authContinueEmail => 'ดำเนินการต่อด้วยอีเมล';

  @override
  String get authLookAround => 'ดูแอปก่อนโดยไม่ต้องมีบัญชี';

  @override
  String get authSignInTitle => 'เข้าสู่ระบบ';

  @override
  String get authCreateTitle => 'สร้างบัญชี';

  @override
  String get authEmailLabel => 'อีเมล';

  @override
  String get authPasswordLabel => 'รหัสผ่าน';

  @override
  String get authNameLabel => 'ชื่อ (ไม่บังคับ)';

  @override
  String authPasswordRule(int min) {
    return 'อย่างน้อย $min ตัวอักษร';
  }

  @override
  String get authSignInAction => 'เข้าสู่ระบบ';

  @override
  String get authCreateAction => 'สร้างบัญชี';

  @override
  String get authToCreate => 'ยังไม่มีบัญชี สร้างบัญชีใหม่';

  @override
  String get authToSignIn => 'มีบัญชีแล้ว เข้าสู่ระบบ';

  @override
  String get authForgot => 'ลืมรหัสผ่าน';

  @override
  String get authShowPassword => 'แสดงรหัสผ่าน';

  @override
  String get authHidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String get authConfirmTitle => 'ตรวจสอบอีเมลของคุณ';

  @override
  String authConfirmBody(String email) {
    return 'เราส่งลิงก์ไปที่ $email แล้ว กดลิงก์ แล้วกลับมาเข้าสู่ระบบ';
  }

  @override
  String get authBackToSignIn => 'กลับไปเข้าสู่ระบบ';

  @override
  String get authResetTitle => 'ตั้งรหัสผ่านใหม่';

  @override
  String get authResetIntro =>
      'เราจะส่งลิงก์ทางอีเมลเพื่อตั้งรหัสผ่านใหม่ เปิดลิงก์ในเครื่องนี้';

  @override
  String get authResetSend => 'ส่งลิงก์ทางอีเมล';

  @override
  String get authResetNewPassword => 'รหัสผ่านใหม่';

  @override
  String authResetSentTo(String email) {
    return 'ส่งลิงก์ไปที่ $email แล้ว เปิดลิงก์ในเครื่องนี้เพื่อตั้งรหัสผ่านใหม่';
  }

  @override
  String get authResetSave => 'ตั้งรหัสผ่านใหม่';

  @override
  String get authResetResend => 'ส่งอีกครั้ง';

  @override
  String get authErrEmailEmpty => 'กรอกอีเมล';

  @override
  String get authErrEmailMalformed => 'รูปแบบอีเมลไม่ถูกต้อง';

  @override
  String get authErrPasswordEmpty => 'กรอกรหัสผ่าน';

  @override
  String authErrPasswordShort(int min) {
    return 'ใช้อย่างน้อย $min ตัวอักษร';
  }

  @override
  String get authErrCodeInvalid => 'ลิงก์หมดอายุแล้ว ขอลิงก์ใหม่';

  @override
  String get authErrInvalidCredentials => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get authErrEmailTaken => 'อีเมลนี้มีบัญชีอยู่แล้ว เข้าสู่ระบบแทน';

  @override
  String get authErrEmailNotConfirmed =>
      'ยืนยันอีเมลก่อน ลิงก์อยู่ในกล่องจดหมาย';

  @override
  String get authErrWeakPassword => 'เลือกรหัสผ่านอื่นที่ยาวกว่านี้';

  @override
  String get authErrRateLimited => 'ลองหลายครั้งเกินไป รอสักครู่แล้วลองใหม่';

  @override
  String get authErrOffline =>
      'ไม่มีอินเทอร์เน็ต ตรวจสอบการเชื่อมต่อแล้วลองใหม่';

  @override
  String get authErrNotConfigured =>
      'วิธีเข้าสู่ระบบนี้ยังไม่พร้อมในเวอร์ชันนี้';

  @override
  String get authErrUnknown => 'เข้าสู่ระบบไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get authSetupTitle => 'เกี่ยวกับการเดินทางของคุณ';

  @override
  String get authSetupIntro => 'เพื่อให้ทุกจำนวนเงินแสดงเป็นสกุลที่คุณคุ้นเคย';

  @override
  String get authSetupTypeHeader => 'คุณคือ';

  @override
  String get authTypeVisitor => 'มาเที่ยวประเทศไทย';

  @override
  String get authTypeVisitorSub => 'จ่ายเป็นเงินบาท';

  @override
  String get authTypeThai => 'คนไทยเที่ยวต่างประเทศ';

  @override
  String get authTypeThaiSub => 'จ่ายเป็นสกุลเงินอื่น';

  @override
  String get authSetupMoneyHeader => 'เงิน';

  @override
  String get authHomeCurrency => 'สกุลเงินที่คุณคุ้นเคย';

  @override
  String get authCardCurrency => 'บัตรของคุณเรียกเก็บเป็น';

  @override
  String get authSetupLanguageHeader => 'ภาษา';

  @override
  String get authLanguageEn => 'English';

  @override
  String get authLanguageTh => 'ไทย';

  @override
  String get authSetupFooter => 'เปลี่ยนได้ภายหลังในการตั้งค่า';

  @override
  String get authSetupStart => 'เริ่มการเดินทาง';

  @override
  String get authSetupOtherAccount => 'ใช้บัญชีอื่น';

  @override
  String get authAccountHeader => 'บัญชี';

  @override
  String get authGuestTitle => 'ยังไม่ได้เข้าสู่ระบบ';

  @override
  String get authGuestSub => 'บันทึกอยู่ในเครื่องนี้เท่านั้น';

  @override
  String get authSignOut => 'ออกจากระบบ';

  @override
  String get authDelete => 'ลบบัญชี';

  @override
  String get authDeleteTitle => 'ลบบัญชีของคุณใช่ไหม';

  @override
  String get authDeleteBody => 'โปรไฟล์และบันทึกที่เก็บไว้จะถูกลบถาวร';

  @override
  String get authDeleteConfirm => 'ลบบัญชี';

  @override
  String get authCancel => 'ยกเลิก';

  @override
  String get politeEndingFemaleStatement => 'ค่ะ';

  @override
  String get haggleNextLabel => 'ขอราคานี้ต่อ';

  @override
  String get haggleDealLabel => 'ตกลงกันได้';

  @override
  String haggleDealAmount(String amount) {
    return '$amount บาท';
  }

  @override
  String haggleAcceptSentence(String amount, String ending) {
    return 'ตกลง $amount บาท$ending';
  }

  @override
  String get haggleStopLabel => 'เขาไม่ลดแล้ว';

  @override
  String haggleStopAmount(String amount) {
    return 'จ่าย $amount บาท หรือเดินไปร้านอื่น';
  }

  @override
  String haggleLeaveSentence(String ending) {
    return 'ไม่เป็นไร ขอบคุณ$ending';
  }

  @override
  String get haggleTheyAnswered => 'เขาตอบว่าอะไร';

  @override
  String get haggleTheyAgreed => 'เขาตกลง';

  @override
  String get haggleTheySaidNo => 'เขาไม่ลด';

  @override
  String get haggleTheyOffered => 'ราคาใหม่';

  @override
  String haggleTheyOfferedPrice(String amount) {
    return 'เขาให้ $amount';
  }

  @override
  String get haggleUnclear => 'ไม่ชัด ถามอีกครั้ง';

  @override
  String get haggleSoFar => 'การต่อราคาครั้งนี้';

  @override
  String get haggleFirstAsk => 'เขาบอก';

  @override
  String get haggleYouOffered => 'คุณต่อ';

  @override
  String haggleYouAsk(String amount) {
    return 'คุณขอ $amount';
  }

  @override
  String haggleTheirLast(String amount) {
    return 'ราคาสุดท้ายของเขา $amount';
  }

  @override
  String get haggleTheyOfferedTitle => 'เขาบอกราคาเท่าไร';

  @override
  String get haggleUsePrice => 'ใช้ราคานี้';

  @override
  String get haggleNewPrice => 'ราคาใหม่';

  @override
  String get haggleHearAnswer => 'ฟังคำตอบ';

  @override
  String get haggleListeningAnswer => 'กำลังฟังคำตอบของเขา';

  @override
  String get authNewPasswordTitle => 'ตั้งรหัสผ่านใหม่';

  @override
  String get saveTerminalTitle => 'จ่ายด้วยสกุลเงินท้องถิ่นที่เครื่องรูดบัตร';

  @override
  String dccKeepLabel(String currency) {
    return 'จ่ายเป็น $currency ประหยัดได้';
  }

  @override
  String dccMarkupChip(String percent) {
    return 'ไม่โดนบวกเพิ่ม $percent';
  }

  @override
  String dccPressKey(int key, String currency) {
    return 'F$key · จ่ายเป็น $currency';
  }

  @override
  String dccReason(String home, String percent) {
    return 'ยอด $home บนเครื่องนี้แพงกว่าอัตราธนาคารประมาณ $percent';
  }

  @override
  String get dccBothOptions => 'ตัวเลือกทั้งสองบนเครื่อง';

  @override
  String dccOptionKey(int key) {
    return 'F$key';
  }

  @override
  String get dccOptionHome => 'สกุลเงินของคุณ';

  @override
  String dccOptionHomeMore(String amount) {
    return 'สกุลเงินของคุณ · แพงกว่าประมาณ $amount';
  }

  @override
  String get dccOptionLocal => 'สกุลเงินท้องถิ่น';

  @override
  String dccFairHome(String currency) {
    return 'ราคาที่ควรจ่ายเป็น $currency';
  }

  @override
  String get dccEvenTitle => 'กดปุ่มไหนก็ได้';

  @override
  String get dccEvenBody =>
      'จ่ายเป็นสกุลเงินของคุณก็ไม่แพงกว่าจ่ายเงินท้องถิ่นตามอัตรา⁠วัน⁠นี้';

  @override
  String rateDemoSource(String pair, String date) {
    return '$pair · อัตราคงที่สำหรับสาธิต $date';
  }

  @override
  String boardRates(String code) {
    return '$code บนป้ายนี้';
  }

  @override
  String boardHeroLabel(String code) {
    return 'ขาย $code ที่นี่ ได้ต่ำกว่าอัตรากลาง';
  }

  @override
  String boardLossChip(String loss, String amount) {
    return 'ได้น้อยลงประมาณ $loss ต่อ $amount';
  }

  @override
  String get boardBuying => 'รับซื้อ';

  @override
  String boardBuyingHint(String code) {
    return 'เงินที่คุณได้ต่อ 1 $code';
  }

  @override
  String get boardSelling => 'ขายออก';

  @override
  String get boardMid => 'อัตรากลาง';

  @override
  String get boardSource => 'จากตัวเลขบนป้ายนี้';

  @override
  String boardVsReference(String percent, String source) {
    return 'อัตรารับซื้อต่ำกว่าประมาณ $percent เทียบกับ $source';
  }

  @override
  String boardAboveReference(String percent, String source) {
    return 'อัตรารับซื้อสูงกว่าประมาณ $percent เทียบกับ $source';
  }

  @override
  String get stepFindTerminalDone => 'พบเครื่องรูดบัตรที่มีสองสกุลเงิน';

  @override
  String get stepFindBoardDone => 'พบป้ายอัตราแลกเปลี่ยน';

  @override
  String stepCompareDcc(String amount) {
    return 'จ่ายเป็นเงินท้องถิ่นประหยัดได้ประมาณ $amount';
  }

  @override
  String stepCompareBoard(String percent) {
    return 'ต่ำกว่าอัตรากลางประมาณ $percent';
  }

  @override
  String get settingsDemo => 'สาธิต';

  @override
  String get settingsDemoFooter =>
      'ใช้ตอนนำเสนอ เปลี่ยนภาษา สกุลเงิน และบันทึกพร้อมกันด้วยอัตราคงที่ บันทึกของคุณจะกลับมาเมื่อปิดโหมดสาธิต';

  @override
  String billCheckedTrace(String elapsed) {
    return 'ตรวจตัวเลขในเครื่องนี้ · $elapsed';
  }

  @override
  String get authSigningIn => 'กำลังเข้าสู่ระบบ';

  @override
  String get authErrTryAgain => 'ทำไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get authErrEmailRejected => 'ใช้อีเมลนี้ไม่ได้ ลองอีเมลอื่น';

  @override
  String get authErrEmailUndeliverable => 'ตอนนี้ยังส่งอีเมลไปที่อยู่นี้ไม่ได้';

  @override
  String get billTimeoutTitle => 'ใช้เวลานานเกินไป';

  @override
  String get billTimeoutBody => 'สัญญาณอาจช้า ลองใหม่อีกสักครู่';

  @override
  String scanKindLine(
    String engine,
    String kind,
    String confidence,
    String elapsed,
  ) {
    return '$engine เห็นว่าเป็น$kind ($confidence) · $elapsed';
  }

  @override
  String get scanCheckAsBill => 'ตรวจบิลนี้';

  @override
  String get kindAtm => 'หน้าจอ ATM';

  @override
  String get kindTerminal => 'เครื่องรูดบัตร';

  @override
  String get kindBill => 'บิลหรือเมนู';

  @override
  String get kindPriceTag => 'ป้ายราคา';

  @override
  String get kindOther => 'อย่างอื่น';

  @override
  String get demoLabel => 'สาธิต';

  @override
  String get demoVisitorBangkok => 'นักท่องเที่ยวอเมริกันในกรุงเทพฯ';

  @override
  String get demoThaiTokyo => 'นักท่องเที่ยวไทยในโตเกียว';

  @override
  String demoPersonaDetail(String language, String currency) {
    return '$language · $currency';
  }

  @override
  String demoPill(String name) {
    return 'สาธิต · $name';
  }

  @override
  String demoSwitchTo(String name) {
    return 'สลับเป็น$name';
  }

  @override
  String get settingsDemoOff => 'ปิด';

  @override
  String get settingsDemoOffHint => 'อัตราวันนี้และบันทึกของคุณเอง';

  @override
  String settingsDemoPersonaHint(String detail) {
    return '$detail · อัตราคงที่ บันทึกตัวอย่าง';
  }

  @override
  String saveSampleWhen(String when) {
    return 'ตัวอย่าง · $when';
  }

  @override
  String homeRateDemo(String pair, String date) {
    return '$pair · อัตราคงที่สำหรับสาธิต วันที่ $date';
  }

  @override
  String get homeToday => 'วันนี้';

  @override
  String homeCashToday(String amount) {
    return 'วันนี้น่าจะใช้เงินสดราว $amount';
  }

  @override
  String homeCashBasis(int days, int count) {
    return 'ประมาณจากบันทึกของคุณ $count รายการใน $days วันล่าสุด';
  }

  @override
  String homeCashBasisSamples(int days, int count) {
    return 'ประมาณจากบันทึกตัวอย่าง $count รายการใน $days วัน';
  }

  @override
  String homeCashBasisMixed(int days, int count, int samples) {
    return 'ประมาณจากบันทึก $count รายการใน $days วันล่าสุด เป็นตัวอย่าง $samples รายการ';
  }

  @override
  String memoryDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'เมื่อ $days วันก่อน',
      one: 'เมื่อวาน',
      zero: 'วันนี้',
    );
    return '$_temp0';
  }

  @override
  String memoryPaidHere(String amount, String when) {
    return '$whenคุณจ่ายที่นี่ $amount';
  }

  @override
  String memoryPaidAt(String amount, String place, String when) {
    return '$whenคุณจ่ายที่ $place $amount';
  }

  @override
  String memoryPaid(String amount, String when) {
    return '$whenคุณจ่าย $amount';
  }

  @override
  String memoryFromRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จากบันทึกของคุณ $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String memoryFromSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จากบันทึกตัวอย่าง $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String memoryFromMixed(int count, int samples) {
    return 'จากบันทึก $count รายการ เป็นตัวอย่าง $samples รายการ';
  }

  @override
  String memoryLine(String fact, String basis) {
    return '$fact · $basis';
  }

  @override
  String get memoryCounterRow => 'การต่อราคาครั้งก่อนของคุณ';

  @override
  String memoryAbout(String amount) {
    return 'ราว $amount';
  }

  @override
  String get authWelcomeExample => 'ตัวอย่าง';

  @override
  String get authWelcomeExampleLabel =>
      'การแปลงสกุลเงินของตู้ ATM จะทำให้เสียเพิ่ม';

  @override
  String get authWelcomeExampleChip => 'ประหยัดได้เพราะเลือกไม่แปลงสกุลเงิน';

  @override
  String authWelcomeExampleSemantics(String amount) {
    return 'ตัวอย่าง การแปลงสกุลเงินของตู้ ATM จะทำให้เสียเพิ่ม $amount การเลือกไม่แปลงช่วยประหยัดเงินส่วนนี้';
  }

  @override
  String get settingsAbout => 'เกี่ยวกับแอป';

  @override
  String get settingsCredits => 'เครดิตภาพ';

  @override
  String get creditsUnavailable => 'อ่านรายการเครดิตไม่ได้';

  @override
  String settingsCreditsHint(int count) {
    return 'ภาพ $count ภาพที่ใช้สอนแอปให้แยกประเภทภาพ';
  }

  @override
  String creditsRow(String author, String license) {
    return '$author · $license';
  }

  @override
  String get creditsFooter =>
      'ภาพเหล่านี้จาก Wikimedia Commons ใช้ฝึกโมเดลบนเครื่องที่แยกหน้าจอ ATM เครื่องรูดบัตร ป้ายอัตราแลกเปลี่ยน และใบเสร็จ แต่ละภาพใช้ตามสัญญาอนุญาตที่แสดง พร้อมชื่อผู้สร้าง';

  @override
  String aiWordedBy(String engine, String elapsed) {
    return 'เรียบเรียงโดย $engine จากตัวเลขด้านบน · $elapsed';
  }

  @override
  String memoryDiscount(String percent) {
    return 'ลดจากราคาแรกได้ราว $percent %';
  }

  @override
  String get homeKeptSamples => 'รวมบันทึกตัวอย่าง';

  @override
  String priceSentenceHigh(String asked, String over, String percent) {
    return '$asked แพงกว่าราคาปกติสูงสุด $over ราว $percent';
  }

  @override
  String priceSentenceFair(String asked) {
    return '$asked อยู่ในช่วงราคาปกติ';
  }

  @override
  String priceSentenceLow(String asked) {
    return '$asked ต่ำกว่าราคาปกติ ซื้อได้คุ้ม';
  }

  @override
  String priceAsked(String amount) {
    return 'เขาบอก $amount';
  }

  @override
  String priceYouPaid(String amount) {
    return 'คุณเคยจ่าย $amount';
  }

  @override
  String get priceZoneCheap => 'ถูก';

  @override
  String priceZoneUsual(String unit) {
    return 'ปกติ $unit';
  }

  @override
  String get priceZoneHigh => 'แพง';

  @override
  String get priceZoneFarAbove => 'แพงมาก';

  @override
  String get priceZoneFarBelow => 'ถูกมาก';

  @override
  String priceSemanticsRange(String low, String high, String unit) {
    return 'ราคาปกติ $low ถึง $high บาท $unit';
  }

  @override
  String priceSemanticsCounter(String amount) {
    return 'ราคาที่แนะนำให้ต่อ $amount';
  }

  @override
  String get haggleShowSeller => 'ให้ผู้ขายดู';

  @override
  String get showSellerTurn => 'หันให้ผู้ขาย';

  @override
  String get showSellerTurnBack => 'หันกลับมาทางฉัน';

  @override
  String get showSellerClose => 'ปิด';

  @override
  String showSellerAmount(String amount) {
    return '$amount บาท';
  }

  @override
  String haggleOfferMeaning(String amount) {
    return 'ขอลดเหลือ $amount บาท';
  }

  @override
  String haggleAcceptMeaning(String amount) {
    return 'ตกลงที่ $amount บาท';
  }

  @override
  String get haggleLeaveMeaning => 'ไม่เป็นไร ขอบคุณ';

  @override
  String get billShop => 'ร้าน';

  @override
  String get billShopUnknown => 'อ่านไม่ได้';

  @override
  String get billYourRecord => 'บันทึกของคุณ';

  @override
  String get billSave => 'บันทึกไว้';

  @override
  String get billSaved => 'บันทึกแล้ว';

  @override
  String get billEdit => 'แก้ไข';

  @override
  String get billEnterIt => 'ใส่เอง';

  @override
  String get billEditTitle => 'บิลนี้ตามที่คุณเห็น';

  @override
  String get billServiceNone => 'ไม่มีค่าบริการ';

  @override
  String get billServiceIncludedChoice => 'รวมค่าบริการแล้ว';

  @override
  String get billServicePercentLabel => 'ค่าบริการ';

  @override
  String get billUseCorrection => 'ใช้ตัวเลขนี้';

  @override
  String get billCorrectedNote =>
      'นี่คือตัวเลขที่คุณแก้ บันทึกเป็นของคุณ ไม่ใช่ผลที่แอปตรวจ';

  @override
  String billMemoryVisits(int visits, String total) {
    return 'คุณเคยบันทึกบิลที่ร้านนี้ $visits ใบ ครั้งล่าสุด $total';
  }

  @override
  String billMemoryNote(String note, int count) {
    return 'ครั้งก่อนที่ร้านนี้คุณจดว่า $note ($count ใบ)';
  }

  @override
  String get billNoteServiceIncluded => 'รวมค่าบริการแล้ว';

  @override
  String billNoteServiceAdded(String percent) {
    return 'บวกค่าบริการ $percent %';
  }

  @override
  String get billNoteNoService => 'ไม่มีค่าบริการ';

  @override
  String get tabAssistant => 'ผู้ช่วย';

  @override
  String get homeRouteNext => 'จุดต่อไป';

  @override
  String get homeRouteAtm => 'ตู้ ATM';

  @override
  String get homeRouteMarket => 'ตลาด';

  @override
  String get homeRouteTerminal => 'เครื่องรูดบัตร';

  @override
  String get homeBriefingLabel => 'สรุปเช้านี้';

  @override
  String get homeBriefingOpen => 'เปิดผู้ช่วย';

  @override
  String get homeBriefingNoNumber => 'ยอดประมาณเงินสดของวันนี้จะแสดงที่นี่';

  @override
  String homeBriefingStops(int count) {
    return 'วันนี้มี $count จุดในปฏิทิน';
  }

  @override
  String homeBriefingMore(int count) {
    return 'อีก $count จุด';
  }

  @override
  String get nearbyLabel => 'ระวังแถวนี้';

  @override
  String get nearbyOpen => 'ดูคำเตือนทั้งหมดแถวนี้';

  @override
  String nearbyMore(int count) {
    return 'มีคำเตือนอีก $count รายการแถวนี้';
  }

  @override
  String get nearbyNeedLocation => 'ดูกับดักเรื่องเงินใกล้ตัว';

  @override
  String get nearbyLocationPrivacy => 'ใช้ตำแหน่งเฉพาะตอนเปิดแอป';

  @override
  String get nearbyLooking => 'กำลังดูตู้ ATM และตลาดแถวนี้';

  @override
  String get nearbyClear => 'แถวนี้ไม่มีอะไรต้องระวัง';

  @override
  String get nearbyClearBasis => 'จากตู้ ATM และตลาดใกล้คุณใน Google Maps';

  @override
  String get trapAtmFeeTitle =>
      'บัตรต่างประเทศเสียค่าธรรมเนียมที่ตู้ ATM ที่นี่';

  @override
  String trapAtmFeeBody(String fee, String where) {
    return 'เช่น $fee ที่ $where ธนาคารอื่นอาจต่างกัน จึงควรถอนครั้งละมากขึ้น';
  }

  @override
  String get trapAtmConversionTitle => 'ตู้ ATM ที่นี่อาจเสนอแปลงสกุลเงิน';

  @override
  String get trapAtmConversionBody =>
      'เลือกสกุลเงินท้องถิ่น ไม่ใช่สกุลเงินของคุณ';

  @override
  String get trapCashOnlyTitle => 'รับเฉพาะเงินสด';

  @override
  String get trapCashOnlyBody => 'เตรียมเงินสดไปก่อน';

  @override
  String get briefingCashOnly => 'เงินสดเท่านั้น';

  @override
  String get briefingCardsOk => 'รับบัตร';

  @override
  String get briefingPayUnknown => 'Google Maps ไม่ได้ระบุวิธีจ่าย';

  @override
  String briefingLastSpent(String amount) {
    return 'ครั้งก่อนคุณใช้ที่นี่ $amount';
  }

  @override
  String briefingLastSpentSample(String amount) {
    return 'บันทึกตัวอย่าง · ครั้งก่อนใช้ที่นี่ $amount';
  }

  @override
  String briefingPlaceDistance(String place, String meters) {
    return '$place · $meters ม.';
  }

  @override
  String briefingSourceLive(String source) {
    return '$source · ข้อมูลล่าสุด';
  }

  @override
  String briefingSourceChecked(String source, String date) {
    return '$source · ตรวจเมื่อ $date';
  }

  @override
  String get assistantTitle => 'ผู้ช่วย';

  @override
  String get assistantCashLabel => 'เงินสดสำหรับวันนี้';

  @override
  String assistantCashAbout(String amount) {
    return 'ราว $amount';
  }

  @override
  String get assistantCashUnknown => 'ยังมีข้อมูลไม่พอ';

  @override
  String get assistantStops => 'จุดแวะวันนี้';

  @override
  String get assistantPay => 'บัตร เงินสด หรือ QR';

  @override
  String assistantPayFor(String place) {
    return 'เทียบสำหรับ $place';
  }

  @override
  String get assistantCard => 'บัตรของคุณ';

  @override
  String get assistantCardFooter =>
      'บันทึกไว้ในเครื่องนี้ ดูตัวเลขได้จากหน้าค่าธรรมเนียมของธนาคาร';

  @override
  String get assistantCardFromAccount =>
      'ค่าธรรมเนียมบัตรจากโปรไฟล์บัญชีของคุณ';

  @override
  String get assistantNearby => 'ใกล้คุณ';

  @override
  String get assistantArrival => 'แจ้งเตือนเมื่อถึงปลายทาง';

  @override
  String get cashBasisNone => 'ต้องมีบันทึกการใช้จ่ายสักหนึ่งถึงสองวัน';

  @override
  String cashBasisPattern(int days) {
    return 'จากการใช้จ่ายของคุณใน $days วันก่อนหน้า';
  }

  @override
  String cashBasisPatternSamples(int days) {
    return 'จากบันทึกตัวอย่างใน $days วัน';
  }

  @override
  String cashBasisCashOnly(int count) {
    return '$count จุดรับเฉพาะเงินสด (Google Maps)';
  }

  @override
  String get cashBasisLastVisit => 'รวมยอดที่เคยใช้ที่นั่นครั้งก่อน';

  @override
  String get calendarConnect => 'อ่านปฏิทินวันนี้';

  @override
  String get calendarDenied => 'ปิดการเข้าถึงปฏิทินไว้ในการตั้งค่า';

  @override
  String get calendarPrivacy => 'อ่านเฉพาะชื่อ สถานที่ และเวลา ไม่แก้ไขอะไร';

  @override
  String get calendarReading => 'กำลังอ่านปฏิทินวันนี้';

  @override
  String get calendarNoStops => 'วันนี้ไม่มีนัดที่ระบุสถานที่ในปฏิทิน';

  @override
  String get payCompareLabel => 'วิธีจ่ายที่ถูกที่สุด';

  @override
  String get payCompareAsk => 'ใส่จำนวนเงินเพื่อเทียบ';

  @override
  String get payCompareAmountHint => 'จำนวนเงิน';

  @override
  String get payCompareBestCard => 'จ่ายด้วยบัตร';

  @override
  String get payCompareBestCash => 'จ่ายด้วยเงินสด';

  @override
  String get payCompareBestQr => 'จ่ายด้วย QR';

  @override
  String get payCompareSame => 'บัตรกับเงินสดเสียพอ ๆ กัน';

  @override
  String get payCompareCashOnly => 'ที่นี่รับเฉพาะเงินสด';

  @override
  String get payCompareNeedCard => 'ใส่ค่าธรรมเนียมต่างประเทศของบัตรเพื่อเทียบ';

  @override
  String get payCompareNeedWithdrawal => 'เงินสดขึ้นกับว่าถอนครั้งละเท่าไร';

  @override
  String payCompareNoRate(String currency) {
    return 'รออัตรา $currency วันนี้';
  }

  @override
  String payCompareBreakEven(String amount) {
    return 'เงินสดถูกกว่าบัตรก็ต่อเมื่อถอนครั้งละ $amount ขึ้นไป';
  }

  @override
  String payCompareAtmFeeSource(String fee, String source) {
    return 'คิดเงินสดด้วยค่าธรรมเนียม ATM $fee ($source) ธนาคารอื่นอาจต่างกัน';
  }

  @override
  String get payCompareNoAtmFee =>
      'ไม่พบค่าธรรมเนียม ATM สำหรับบัตรต่างประเทศที่เผยแพร่ จึงไม่คิดราคาเงินสด';

  @override
  String get payCompareDemoRate => 'อัตราสาธิตคงที่';

  @override
  String get payCard => 'บัตร';

  @override
  String get payCash => 'เงินสดจาก ATM';

  @override
  String get payQr => 'QR';

  @override
  String payExtra(String amount) {
    return '+$amount';
  }

  @override
  String get payNotTaken => 'ที่นี่ไม่รับ';

  @override
  String get payNeedCardFee => 'ใส่ค่าธรรมเนียมบัตร';

  @override
  String get payNeedWithdrawal => 'ขึ้นกับยอดที่ถอน';

  @override
  String get payNoQrFee => 'ไม่มีค่าธรรมเนียมที่เผยแพร่';

  @override
  String get cardFeeRow => 'ค่าธรรมเนียมใช้จ่ายต่างประเทศ';

  @override
  String get cardFeeMissing => 'ยังไม่ได้ใส่';

  @override
  String get cardAtmRow => 'ธนาคารของคุณเมื่อถอนที่ ATM ต่างประเทศ';

  @override
  String get cardAtmUnknown => 'ไม่แน่ใจ';

  @override
  String get cardAtmNoFee => 'ไม่มีค่าธรรมเนียม';

  @override
  String get cardAtmRefunds => 'คืนค่าธรรมเนียม ATM';

  @override
  String cardAtmFixed(String currency) {
    return 'ค่าธรรมเนียมคงที่เป็น $currency';
  }

  @override
  String get cardAtmPercent => 'เปอร์เซ็นต์ของยอดถอน';

  @override
  String cardAtmFixedValue(String amount) {
    return 'ครั้งละ $amount';
  }

  @override
  String cardAtmPercentValue(String percent) {
    return '$percent ของแต่ละครั้งที่ถอน';
  }

  @override
  String get cardSheetTitle => 'บัตรของคุณ';

  @override
  String get cardFeeLabel => 'ค่าธรรมเนียมใช้จ่ายต่างประเทศ';

  @override
  String get cardFeeHintThai =>
      'ธนาคารไทยระบุไม่เกิน 2.5% (ตารางค่าธรรมเนียมกสิกรไทย ทีทีบี ปี 2025-2026)';

  @override
  String get cardFeeHintOther => 'ดูค่าธรรมเนียมจริงได้ในเงื่อนไขบัตร';

  @override
  String get cardAtmLabel => 'ธนาคารของคุณคิดเท่าไรเมื่อถอนที่ ATM ต่างประเทศ';

  @override
  String get cardFeeInvalid => 'ใส่ตัวเลข 0 ถึง 20';

  @override
  String get cardAtmValueInvalid => 'ใส่จำนวนค่าธรรมเนียม';

  @override
  String get cardSheetPrivacy => 'เก็บเฉพาะตัวเลขเหล่านี้ ไม่เก็บเลขบัตร';

  @override
  String get cardSheetSave => 'บันทึกข้อมูลบัตร';

  @override
  String get arrivalOn => 'เปิดไว้สำหรับการเดินทางครั้งต่อไป';

  @override
  String get arrivalOnBody =>
      'เมื่อโทรศัพท์ถึงประเทศที่ใช้สกุลเงินอื่น จะแจ้งเตือนครั้งเดียวว่าควรเลือกสกุลเงินไหน';

  @override
  String get arrivalAllow => 'อนุญาตการแจ้งเตือน';

  @override
  String get arrivalBlocked => 'ปิดการแจ้งเตือนไว้ในการตั้งค่า';

  @override
  String get arrivalDemoTrigger => 'สาธิต · ถึงญี่ปุ่น';

  @override
  String get arrivalDemoFooter =>
      'เฉพาะโหมดสาธิต แสดงการแจ้งเตือนเดียวกับที่ตำแหน่งจริงจะส่ง';

  @override
  String arrivalShownDemo(String body) {
    return 'สาธิต · $body';
  }

  @override
  String arrivalTitle(String country) {
    return 'ถึง$countryแล้ว';
  }

  @override
  String arrivalBody(String local, String home) {
    return 'ถ้าเครื่องรูดบัตรถามว่าจ่ายเป็น $home หรือ $local ให้เลือก $local';
  }

  @override
  String arrivalBodyAtm(String local, String home) {
    return 'ถ้าเครื่องรูดบัตรหรือตู้ ATM ถามว่าจ่ายเป็น $home หรือ $local ให้เลือก $local';
  }

  @override
  String get arrivalChannel => 'แจ้งเตือนเมื่อถึงปลายทาง';

  @override
  String get countryJapan => 'ญี่ปุ่น';

  @override
  String get countryThailand => 'ไทย';

  @override
  String billMemoryNoteBranch(String note, int count) {
    return 'ที่สาขาอื่นคุณจดว่า $note ($count ใบ)';
  }

  @override
  String billBrandMemory(String habit, int count) {
    return 'สาขาอื่นของร้านนี้ $habit ($count ใบเสร็จ)';
  }

  @override
  String get billBrandServiceAdded => 'บวกค่าบริการ';

  @override
  String get tripMapTitle => 'แผนที่ทริป';

  @override
  String get tripMapEmpty =>
      'ใบเสร็จและการต่อราคาที่บันทึกพร้อมสถานที่จะแสดงที่นี่';

  @override
  String tripMapKeptDay(String amount) {
    return 'ประหยัด $amount';
  }

  @override
  String tripMapKept(String amount) {
    return 'ประหยัด $amount';
  }

  @override
  String get tripMapSample => 'ตัวอย่าง';

  @override
  String get tripMapCorrected => 'ตัวเลขที่คุณแก้';

  @override
  String get tripMapKindReceipt => 'ใบเสร็จ';

  @override
  String get tripMapKindHaggle => 'ต่อราคา';

  @override
  String get tripMapKindAtm => 'ATM';

  @override
  String get tripMapKindTerminal => 'เครื่องรูดบัตร';

  @override
  String tripMapKeptAt(int count) {
    return 'ประหยัดได้จาก $count แห่ง';
  }

  @override
  String get tripMapOnMap => 'บนแผนที่';

  @override
  String tripMapPlaces(int count) {
    return '$count แห่ง';
  }

  @override
  String get tripMapToday => 'วันนี้';

  @override
  String get tripMapYesterday => 'เมื่อวาน';

  @override
  String tripMapPaid(String amount) {
    return 'จ่าย $amount';
  }

  @override
  String get tripMapClose => 'ปิด';

  @override
  String get tripMapOffline =>
      'แผนที่ต้องใช้อินเทอร์เน็ต แต่ทุกแห่งยังอยู่ในรายการด้านล่าง';

  @override
  String get tripMapEmptyAction => 'สแกนใบเสร็จ';

  @override
  String tripMapMapLabel(int count) {
    return 'แผนที่ $count แห่ง ทุกแห่งอยู่ในรายการด้านล่างด้วย';
  }

  @override
  String get tripMapShowOnMap => 'แสดงบนแผนที่';

  @override
  String tripMapNear(String place) {
    return 'ใกล้ $place';
  }

  @override
  String billTotalInvalid(String max) {
    return 'ใส่ยอดรวมมากกว่า 0 และไม่เกิน $max';
  }

  @override
  String trapAtmFeeBodyPlain(String fee) {
    return 'เช่น ครั้งละ $fee ควรถอนครั้งละมากขึ้น';
  }

  @override
  String get arrivalOff => 'ปิดอยู่จนกว่าจะอนุญาตการแจ้งเตือน';

  @override
  String get nearbyDemoOff => 'ปิดในโหมดสาธิต';

  @override
  String get nearbyDemoOffBody => 'คำเตือนใกล้ตัวมาจากตำแหน่งจริงของโทรศัพท์';

  @override
  String get payCompareNeedBank =>
      'ใส่ค่าธรรมเนียมที่ธนาคารของคุณคิดเมื่อถอนที่ ATM ต่างประเทศ เพื่อเทียบกับเงินสด';

  @override
  String get payCompareWithdrawalAssumed =>
      'คิดเงินสดโดยถือว่าถอนเท่ากับยอดนี้พอดี';

  @override
  String payCompareWithdrawalPlan(String amount) {
    return 'คิดเงินสดโดยถือว่าถอนครั้งเดียวราว $amount ตามยอดประมาณวันนี้';
  }

  @override
  String aiHeardBy(String engine, String elapsed) {
    return 'ฟังโดย $engine · $elapsed';
  }

  @override
  String get speakWordsAfter => 'คำพูดจะขึ้นเมื่อผู้ขายพูดจบ';

  @override
  String get speakReading => 'กำลังอ่านสิ่งที่ผู้ขายพูด';

  @override
  String get assistantFacts => 'ข้อมูลที่ตรวจทางออนไลน์';

  @override
  String factsSummary(int checked, int updated, int unchanged, int kept) {
    return 'วันนี้ตรวจ $checked รายการ · อัปเดต $updated · เท่าเดิม $unchanged · คงค่าเดิม $kept';
  }

  @override
  String get factsNotToday => 'วันนี้ยังไม่ได้ตรวจ';

  @override
  String factsOffline(String date) {
    return 'ออฟไลน์ แสดงข้อมูลชุดของ $date';
  }

  @override
  String get factsFooter =>
      'Gemini อ่านแต่ละหน้าวันละครั้ง ใช้ตัวเลขเฉพาะเมื่อประโยคนั้นปรากฏในหน้าเว็บตรงทุกตัวอักษร';

  @override
  String get factThAtmVisa => 'ค่าธรรมเนียม ATM กสิกรไทย บัตร Visa';

  @override
  String get factThAtmMastercard => 'ค่าธรรมเนียม ATM กสิกรไทย บัตร Mastercard';

  @override
  String get factMangoLowest => 'มะม่วง ราคาส่งต่ำสุดวันนี้';

  @override
  String get factUpdated => 'อ่านจากหน้าเว็บวันนี้';

  @override
  String get factUnchanged => 'เท่าเดิม ตรวจแล้ววันนี้';

  @override
  String get factKeptBlocked => 'คงค่าเดิม เว็บไซต์ไม่อนุญาตให้อ่านอัตโนมัติ';

  @override
  String get factKeptNoMatch =>
      'คงค่าเดิม ไม่พบตัวเลขในหน้าเว็บแบบตรงทุกตัวอักษร';

  @override
  String get factKeptOther => 'คงค่าเดิม อ่านหน้าเว็บไม่ได้';

  @override
  String get factNew => 'ค้นคว้าด้วยตนเอง ยังไม่ได้ตรวจออนไลน์';

  @override
  String factSourceLine(String host, String time) {
    return '$host · ตรวจเมื่อ $time';
  }

  @override
  String get recordsSwipeHint => 'ปัดแถวไปทางซ้ายเพื่อลบ';

  @override
  String get recordsSavedPhone => 'บันทึกไว้ในเครื่องนี้เท่านั้น';

  @override
  String get recordsSavedAccount => 'บันทึกไว้ในบัญชีของคุณด้วย';

  @override
  String get recordsSavedDemo =>
      'บันทึกสาธิตอยู่ในโหมดสาธิตเท่านั้น ไม่ถูกส่งไปยังบัญชีของคุณ';

  @override
  String get haggleNoRange =>
      'ยังไม่มีช่วงราคาที่มีแหล่งอ้างอิงสำหรับสินค้านี้';

  @override
  String haggleNewItemHeard(String item, String amount, String unit) {
    return '$item $amount $unit';
  }

  @override
  String get haggleUsualDiscountRow => 'ส่วนลดที่คุณมักได้';

  @override
  String haggleDidTheyMean(String item) {
    return 'หมายถึง$itemใช่ไหม';
  }

  @override
  String get haggleYes => 'ใช่';

  @override
  String get haggleNo => 'ไม่ใช่';

  @override
  String aiNewItemLine(String engine, String elapsed) {
    return '$engine ระบุสินค้าจากสิ่งที่ได้ยิน · $elapsed';
  }

  @override
  String get haggleSomethingElse => 'อย่างอื่น';

  @override
  String get haggleTypeItem => 'เขาขายอะไร';

  @override
  String get haggleTypeItemHint => 'เช่น ลาเต้วานิลลา';
}
