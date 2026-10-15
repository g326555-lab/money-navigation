# 준비 단계 확인 메모 (2026-10-07 ~ 10-08)

대회 전에 연습 앱(`practice/`, 대회 전 삭제)으로 확인한 사실과 해결책. 앱 코드나 결과물이 아니라 조사 메모다.
확인 환경: macOS 27.0.1, Xcode 27.0, Flutter 3.47.6 (Dart 3.13.5), iOS 27 시뮬레이터 iPhone 18 Pro, Android 16(API 36) 에뮬레이터. 실제 휴대폰에서는 아직 확인하지 않았다.

## 1. 버전 (2026-10-08 기준 최신, 모두 Android/iOS 지원)

| 패키지 | 버전 |
| --- | --- |
| google_mlkit_text_recognition | 0.17.1 |
| google_mlkit_image_labeling | 0.16.1 |
| google_mlkit_translation | 0.15.1 |
| google_mlkit_commons | 0.13.0 |
| speech_to_text | 7.5.0 |
| flutter_tts | 4.2.5 |
| camera | 0.12.1 |
| geolocator | 14.1.1 |
| supabase_flutter | 2.18.0 |

- ML Kit iOS 최소 버전 15.5. Podfile 첫 줄을 `platform :ios, '15.5'`로.
- flutter_tts, google_mlkit_* 는 Swift Package Manager 미지원 경고가 나오지만 CocoaPods로 정상 빌드된다.
- Supabase CLI 2.120.0 (2026-10-10 업그레이드, `brew trust supabase/tap` 완료).

## 2. 꼭 넣어야 하는 해결책

### 2-1. iOS: ML Kit을 Apple Silicon 시뮬레이터에서 쓰기
ML Kit 바이너리에 arm64 시뮬레이터용이 없어 그대로는 x86_64로만 빌드되고 iOS 26+ 시뮬레이터에서 실행 불가.
google_mlkit_commons README의 공식 우회책을 `ios/Podfile`에 추가:

```ruby
flutter_ios_podfile_setup

require File.expand_path(
  '.symlinks/plugins/google_mlkit_commons/ios/scripts/apple_silicon_simulator',
  __dir__,
)
...
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
  mlkit_apple_silicon_simulator_patch(installer)
end
```

- 추가한 뒤 **빌드를 두 번** 해야 한다. 첫 빌드 때 Flutter가 패치 전 상태를 보고 `Generated.xcconfig`에 `EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386 arm64`를 써 버린다. 두 번째 빌드에서 `i386`만 남으면 정상.
- 증상: `Framework 'Pods_Runner' not found`, 또는 `flutter run`에서 `No Xcode build settings have been found`.
- 확인: iOS 출시용 빌드(`flutter build ios --release --no-codesign`)의 arm64가 `platform 2`(실제 아이폰)로 되돌아가 있음. TestFlight 빌드에 문제 없음.
- 직접 `pod install`을 돌릴 때는 `LANG=en_US.UTF-8`을 붙인다(안 붙이면 Ruby 인코딩 오류).

### 2-2. Android: 출시용 빌드에서 ML Kit 살리기
- R8이 쓰지 않는 언어 인식기 때문에 빌드 실패(`Missing class ...ChineseTextRecognizerOptions`). 해결: `-dontwarn` 규칙. 출처: flutter-ml/google_ml_kit_flutter#528
- 빌드가 되어도 실행 시 ML Kit이 죽음(`NoSuchMethodException ...Registrar.<init>`, `MissingPluginException`). R8이 리플렉션으로 만드는 클래스를 지운 것. `-keep` 규칙으로 해결했고, 디버그와 같은 결과를 확인했다. 이 정확한 오류의 공식 해결책은 찾지 못했다(Google ML Kit known issues의 같은 방식 적용).

`android/app/build.gradle.kts`의 release:
```kotlin
isMinifyEnabled = true
proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
```

`android/app/proguard-rules.pro`:
```
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google_mlkit_** { *; }
```
- 출시용 APK 크기 약 158MB(전체 ABI 포함). 줄이려면 `--split-per-abi` 검토.

### 2-3. iOS: 번역 모델 받기 완료 신호가 오지 않음
- iOS에서 `downloadModel()`의 Future가 끝나지 않는다(10분 대기 후 타임아웃). 실제로는 모델이 2초 만에 받아져 있다. 플러그인이 완료 알림을 받지 못하는 것으로 보인다.
- 우회: 받기를 시작만 하고, 1초마다 `isModelDownloaded()`로 확인. Android는 정상(새로 받기 10초).
- 앱 시작 때 en, th, ja 모델을 미리 받아 두기.

### 2-4. 권한 문구
- iOS Info.plist: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `NSLocationWhenInUseUsageDescription`.
- Android Manifest: INTERNET, CAMERA, RECORD_AUDIO, ACCESS_FINE/COARSE_LOCATION. `<queries>`에 `android.speech.RecognitionService`, `android.intent.action.TTS_SERVICE`.

## 3. 기능별 확인 결과

| 기능 | iOS 시뮬레이터 | Android 에뮬레이터 | 메모 |
| --- | --- | --- | --- |
| 글자 인식, ATM 사진 | 통과 | 통과 | 천 단위가 점: "4.000 THB", "4.220 THB" |
| 글자 인식, 일본 단말기 | 숫자 읽음 | 숫자 읽음 | 쉼표 뒤 공백 "12, 851.82", "58, 000". iOS는 "F2:PY"(J 누락). 통화 코드 말고 F1/F2 위치와 숫자로 판단 |
| 이미지 분류(기본 모델) | 통과 | 통과 | Android 점수가 낮음(최고 0.45). 임계값 0.5면 결과 없음 |
| 커스텀 모델 분류 | 4/4 | 4/4 | 아래 4번 |
| 번역 en↔th | 통과 | 통과 | "Can you make it 300 baht?" → "만들 수 있나요"로 오역. 흥정 문장은 미리 쓴 태국어 문장 또는 Gemini 사용 |
| 태국어 음성 출력 | 통과(Kanya 목소리) | 통과(5개 목소리) | 귀로 듣지는 않음 |
| 음성 인식 준비 | 통과(th-TH) | 통과(th_TH) | 실제 말소리 인식은 미확인 |
| 환율 Frankfurter | 통과 | 통과 | 새 주소 `https://api.frankfurter.dev/v1/latest?base=THB&symbols=JPY,USD`. 옛 `api.frankfurter.app`는 301 리다이렉트 |
| 카메라 | 0개(시뮬레이터 한계) | 2개 | 촬영은 실기기 필요 |
| 위치 | 통과 | 실패 | 에뮬레이터 GPS 미반영, Google 위치 정확도 동의 요구(거절함). 실기기 필요 |

- 환율 참고: 10/6 1 THB = 4.7085 JPY, 10/7 4.6958. 시연 고정값 4.6935와 다르므로 시연 모드에서만 고정값 사용.

## 4. 이미지 분류 모델 학습 (MediaPipe Model Maker)
- 이 맥에서 학습부터 ML Kit 실행까지 확인. 학습 23초(이미지 100장, MobileNetV2, 8 epoch). 출력 `model.tflite`, `labels.txt`, 라벨이 메타데이터에 들어가 ML Kit이 라벨 이름을 그대로 돌려준다.
- 버전 조합(이대로 고정해야 import가 된다):
```bash
uv venv -p 3.11 .venv-mp
VIRTUAL_ENV=.venv-mp uv pip install mediapipe-model-maker "tensorflow==2.15.1" "keras==2.15.0" "tf-keras==2.15.1" "jax==0.4.30" "jaxlib==0.4.30" "setuptools<70"
```
  - `runtime_version` protobuf ImportError 메시지는 나오지만 무시해도 학습·내보내기 정상.
  - 설치 용량 약 2.4GB.
- Flutter에서는 `LocalLabelerOptions(modelPath: 파일경로)`. 에셋을 앱 폴더에 복사한 뒤 경로를 넘긴다.
- 당일 할 일: 실제 사진을 클래스별로 충분히 모으기. 연습은 같은 사진을 변형해서 정확도 1.00은 의미 없음.

## 5. Gemini
- 무료 등급 키는 맥 키체인 `gemini-practice`에 있음(연습용). 앱에서는 Supabase secret에만 둔다.
- 현재 API: `POST https://generativelanguage.googleapis.com/v1beta/interactions`, 헤더 `x-goog-api-key`. 이미지는 `{"type":"image","data":base64,"mime_type":"image/jpeg"}`. 응답 텍스트는 `steps[].content[]`의 `type:"text"`.
- 권장 모델 `gemini-3.8-flash`. 무료 등급은 자주 `service_unavailable`(붐빔). **재시도 + 예비 모델(3.7 → 3.5 Flash) 필수**. 3.5 Flash도 계산서 숫자는 정확, 영어 메뉴명은 비움.
- 계산서 읽기: 정답 숫자를 주지 않아도 소계 225.00, 할인 13.00, 서비스료 21.00, 세전 217.76, 부가세 15.24, 합계 233.00, 받은 돈 300, 거스름 67.00 모두 일치. 할인 줄의 "15%"(13.00은 15%가 아님)는 지적하지 못함. 이런 검증은 `rules/`에서.
- 지도 연동(Grounding with Google Maps)과 구글 검색 연동은 **무료 등급 불가**. 유료 등급은 월 5,000건 무료 후 1,000건당 14달러. Google AI Pro 구독은 API 키에 적용되지 않는다.
- 무료 대안으로 확인한 방식: Gemini가 일정 JSON 생성 → OpenStreetMap Nominatim으로 장소 검증(이름 유사도 + 장소 종류 + 지역이 맞을 때만 "확인됨"). 5곳 중 4곳 확인, 1곳은 다른 지점이라 "확인 필요".
  - Nominatim 규칙: 1초 1건, 앱 이름 User-Agent, 결과 캐시, "© OpenStreetMap contributors" 표시, 자동완성 금지.
  - OSM 데이터 오류 있음(미용실이 "Sampheng market"으로 등록). 장소 종류 확인이 필요한 이유.
  - 비용·현금 전용 여부는 Gemini 추정이라 "AI 추정"으로 표시.
- Edge Function 형태 코드(Deno.serve, 키는 `Deno.env`)를 맥에서 Deno 2.7로 실행해 계산서 읽기 성공. Supabase 프로젝트는 아직 0개(로그인은 되어 있음).

## 6. 화면 크기
- Galaxy Z Fold8 커버: 1248×1972, 약 428ppi. Flutter 논리 크기 **466.5 × 737.2**(dpr 2.675). 디자인 기준 390보다 넓고 세로가 짧다. 하단 고정 버튼과 큰 숫자가 세로 737 안에 들어가야 한다.
- 에뮬레이터 `Fold8_cover` 만들어 둠(420dpi, 실행 후 `adb shell wm density 428`).

## 7. 글꼴
- Google Sans Flex(가변 글꼴, OFL), Noto Sans Thai(OFL) 모두 google/fonts 저장소에서 받을 수 있음.

## 8. 아직 확인하지 않은 것
- 실기기(Fold8, iPhone): 카메라 촬영, 실제 음성 인식, 음성 출력 소리, Android 위치.
- TestFlight 업로드(유료 계정 있음, 앱 ID 등록 필요).
- Supabase 실제 프로젝트에 Edge Function 배포와 secret 설정.

## 결정 (2026-10-10, 현준)
- 장소 확인은 **무료 대안**으로 간다: Gemini 일정 생성 + OpenStreetMap Nominatim 검증. 유료 Google Maps 연동은 쓰지 않는다.
- 발표 설명: "지금은 무료 지도 데이터로 확인하고, 서비스 단계에서 Google 지도 연동으로 바꿀 수 있다."

## 결정 (2026-10-11, 현준) — AI가 일하는 모습 보여주기
- 결과만 띄우지 않는다. 실제 중간 결과를 단계별로 보여준다: 인식(박스) → 읽은 숫자 → 환율 확인 → 계산 → 결론. 미리 짠 애니메이션 금지, 실제 값만.
- 시연에 심사위원의 실물 영수증/가격 말하기를 받아 즉석 처리한다. 실패 대비로 준비한 인쇄물을 백업으로 둔다.
- 시세는 출처가 쌓이는 모습(리뷰 n건, 여행자 기록 n건)을 보여준다.
- 행사장에서 학습한 사진 종류 구분 모델(ATM / 카드 단말기 / 메뉴·영수증 / 가격표)은 슬라이드와 말로 짚는다.

## 속도 목표 (2026-10-11) — 아직 측정 전
| 장면 | 목표 | 방법 |
| --- | --- | --- |
| ATM·카드 단말기 판단 | 찍고 1초 안에 결론 | 폰 안 OCR + 계산만. 인터넷·Gemini 불필요. 설명 문장은 뒤에서 받아 덧붙임 |
| 흥정 | 말 끝나고 2초 안에 "비싸요", 3초 안에 태국어 말하기 시작 | 시장 시세는 미리 받아 둠(캐시). 깎는 문장은 템플릿 + 숫자 |
| 영수증 AI 읽기 | 5초 안, 그동안 단계 표시 | Gemini 응답 스트리밍, 단계마다 즉시 표시 |
| 온라인 시세 검색 | 현장에서 기다리지 않음 | 도착·진입 시 미리 검색, 화면은 캐시 즉시 + 뒤에서 갱신 |
- 모든 네트워크 호출에 시간 제한을 두고, 넘으면 "최근 확인값(시간 표시)"을 보여준다. 가짜 값 금지.
- 다음 할 일: 위 4개 장면의 실제 소요 시간을 시뮬레이터와 폰(케이블 생기면)에서 각 10회 측정해 표로 남길 것. Gemini 모델별(flash 계열) 응답 시간, 검색 연동 켰을 때/껐을 때 비교 포함.

## 결정 (2026-10-13, 현준) — 발표 방식
- 발표는 스티브 잡스 아이폰 발표(2007) 방식: 정적 → 손 들기 → 체감 숫자(3,800฿ = 호텔 하룻밤) → 적(앱 세 개) → "눈, 입, 내비게이션… 세 개가 아니라 하나" → 라이브 데모 → "ChatGPT는 물어봐야 답한다, 우리는 먼저 말한다" → 돈의 웨이즈 → One more thing(심사위원 영수증 즉석 처리) → 마무리 한 줄.
- 슬라이드는 애플 스타일: 검은 배경, 한 장에 큰 단어나 숫자 하나, 장식 없음. 슬라이드 디자인은 행사 당일 제작.
- "세계 최초" 같은 사실 아닌 표현 금지. "셋을 하나로"는 사실이라 사용 가능.
