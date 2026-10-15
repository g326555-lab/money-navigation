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
  String get stepFindAtmFailed => 'ไม่พบข้อเสนอแปลงสกุลเงินของตู้ ATM ในรูปนี้';

  @override
  String get stepReadTextFailed => 'ไม่พบตัวอักษร';

  @override
  String get stepValuesFailed => 'อ่านตัวเลขบางส่วนไม่ได้';

  @override
  String get scanTipNoText => 'ขยับเข้าไปใกล้ขึ้นให้หน้าจอเต็มรูป';

  @override
  String get scanTipNotAtm =>
      'เล็งไปที่หน้าจอตู้ ATM ที่แสดงยอดเป็นสกุลเงินของบัตร';

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
  String counterOfferSentence(String amount) {
    return 'ลดเหลือ $amount บาทได้ไหม';
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
  String get speakUnavailable =>
      'มือถือนี้ใช้การฟังภาษาไทยไม่ได้ พิมพ์สิ่งที่ได้ยินแทนได้';

  @override
  String get speakDenied =>
      'Money Navigation ยังไม่ได้รับสิทธิ์ใช้ไมโครโฟน เปิดได้ในการตั้งค่า หรือพิมพ์สิ่งที่ได้ยินแทน';

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
}
