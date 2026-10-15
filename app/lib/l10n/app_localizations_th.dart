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
  String get scanHint => 'เล็งไปที่หน้าจอตู้ ATM';

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
  String get scanCameraUnavailable =>
      'ใช้กล้องไม่ได้ในตอนนี้ แต่ยังเลือกรูปได้';

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
    return 'ถอน $withdrawal · ค่าธรรมเนียม $fee · 1 USD = $rate THB';
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
    return '1 USD = $rate THB';
  }

  @override
  String get atmIfConvert => 'ถ้าแปลงสกุลเงิน';

  @override
  String get atmIfNotConvert => 'ถ้าไม่แปลง';

  @override
  String get atmScanAnother => 'สแกนอีกครั้ง';
}
