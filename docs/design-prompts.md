# Design prompts (Stitch for screens, Nano Banana for images)

Stitch exports are references only. The lead rebuilds them in Flutter using docs/DESIGN.md tokens; fonts and colors always follow DESIGN.md, not the export. Images from Nano Banana go to app/assets/ (icons) or the pitch deck (photos).

## Stitch — rules
- New project in App (mobile) mode. One screen per prompt. Generate the Home screen first; every later prompt starts with "Same visual style as the Home screen".
- If a result uses Inter / Plus Jakarta Sans, all-caps labels, or card soup, reply with the FIX prompt below.

### FIX prompt
Change all typography to Google Sans Flex (Noto Sans Thai for Thai). Remove all-caps labels, remove boxes around content that does not need them, increase spacing, make the key number much larger. Keep the layout idea.

### BASE (paste at the top of every Stitch prompt)
Mobile app, portrait phone 466 x 737 pt, one screen only, not a presentation board. App: "Money Navigation", an AI travel money assistant ("Maps tells you where to go. Money Navigation tells you how to pay."). Quality bar: a flagship app from a large product team (Toss, Apple Wallet, Wise level). Background #F2F4F6, text #111418, secondary #4E5968, tertiary #8B95A1, one accent green #19D873 (green text #00A85A), warning red #FF3B5C. Font Google Sans Flex (Noto Sans Thai for Thai). One dominant number per screen, generous spacing, hierarchy from type size and whitespace. Brand motif: a thin green route line like a map navigation route. No all-caps labels, no emoji, no gradients, no purple, no glow, no colored card stripes, no stacks of small grey boxes, no sparkle AI icons.

### 1 Home (English)
Top row: "Money Navigation" left, pill toggle "Bangkok · USD" right. Hero directly on background: small label "Kept on this trip", "316" very large (~88pt, extra bold, tight tracking) with "THB" small beside it, "≈ $10.24" grey below. Under it the green route line with stops "ATM · +246", "Market · +70" and a hollow dot "Next stop". Briefing row with a small icon: "About 2,000 THB in cash today", grey line "Chatuchak market is mostly cash only". Recent saves as two plain rows with thin dividers: "ATM conversion avoided · +246 THB", "Mango price checked · +70 THB". Bottom: large full-width dark button "Scan to check" with camera icon, smaller text button "Hear a price" with microphone icon.

### 2 Scan in progress (English)
Same visual style as the Home screen. Full-screen camera view of an ATM screen (dark), a precise green detection box snapped around the amounts. Bottom sheet (white, rounded top, drag handle) listing real steps that appear one by one with check marks: "ATM screen recognized", "Read 4,000 THB · fee 220 THB · 1 USD = 30.86 THB · mark-up 5.50%", "Checked today's rate", and a fourth step in progress "Working out the cheaper button". Close button top left, flashlight top right.

### 3 ATM verdict (English)
Same visual style as the Home screen. Huge "246 THB" with label above "You keep about". Instruction block (the only dark card): "Press: Accept without currency conversion". One plain reason line: "The ATM's own rate adds 5.50% on top." Two-row comparison: "If you convert · 144.71 USD" vs "If you don't · 4,220 THB charged in baht". Small source line "Rate checked today 10:24". Bottom button "Save to trip".

### 4 Haggling (English, Thai shown)
Same visual style as the Home screen. Top: fine live waveform and "Listening". Heard text large in Thai "มะม่วงกิโลละ 150", English under it "Mango, 150 THB per kilo". Verdict: "150" in red with label "High", then "Usual 60–80 THB". Sources line growing: "3 online reviews · 2 traveler records · Oct". Bottom: big green-outlined button "Say in Thai: 80 baht?" with the Thai sentence "80 บาทได้ไหมคะ" and a speaker icon.

### 5 Arrival alert (Thai, lock screen)
iPhone lock screen, time 14:05, location "Narita Airport". One notification from Money Navigation: title "ถึงญี่ปุ่นแล้ว", body "ถ้าเครื่องรูดบัตรถามว่าจ่ายเป็นบาทหรือเยน ให้เลือกเยน", small grey line "ประหยัดได้หลายร้อยบาท". Blurred city wallpaper.

### 6 Japan terminal verdict (Thai)
Same visual style as the Home screen, Thai UI. Small photo strip of a card terminal screen showing "F1: THB 12,851.82" and "F2: JPY 58,000" with F2 highlighted green. Huge "494 บาท" with label "ประหยัดประมาณ". Dark instruction card: "กด F2 จ่ายเป็นเยน". Line "1 บาท = 4.6935 เยน · อัตราวันนี้". Bottom button "บันทึกลงทริป".

### 7 Bill check (English)
Same visual style as the Home screen. Top: small thumbnail of a Thai restaurant receipt. Large total "233.00 THB". Plain rows: Subtotal 225.00, Discount −13.00, Service charge 10% +21.00 (tag "added on top"), VAT 7% 15.24 (tag "already included"). One explanation line: "Service charge was added on top. VAT is already inside the total." Bottom button "Looks right".

### 8 Trip summary (English)
Same visual style as the Home screen. "Kept on this trip" with huge "1,240 THB". The green route line drawn across the whole trip with stops by day. Breakdown rows: Card terminals 494, ATM 380, Markets 366. Small line "Your prices helped 12 other travelers". Share button.

## Nano Banana — rules
- No text inside images (generators garble text). Add text later in the app or slides.
- No real brand logos, no real bank names.

### App icon
App icon, 1024 x 1024, square, no transparency, no text. A minimal flat-but-dimensional symbol: a round coin whose face is cut by a bold navigation arrow pointing up and right, like a map direction arrow. Coin in vivid green #19D873 with a subtle inner bevel, arrow in white. Background near-black #111418. Centered, generous padding, crisp vector look, soft single light source, premium like a top App Store finance app. No gradients beyond the subtle bevel, no glow, no sparkles.

### App icon — alternate light
Same symbol on a white #FFFFFF background, coin green #19D873, arrow #111418.

### Brand states (in-app, transparent background, 512 x 512)
Same coin-and-arrow symbol on a transparent background, three variants side by side: (1) default green coin with white arrow, (2) guide: arrow glowing slightly brighter green with a short motion trail, (3) warning: coin red #FF3B5C with a white exclamation shape replacing the arrow. Flat vector, consistent stroke and size.

### Pitch photo — Tokyo terminal (16:9)
Photorealistic close-up, shallow depth of field: a Thai traveler's hand holding a credit card over a small handheld card terminal at a Tokyo shop counter, the terminal screen glowing with two choice buttons (no readable text), warm evening shop light, blurred Japanese shop interior behind. Cinematic, Apple keynote style, dark tones, no brand logos.

### Pitch photo — Bangkok market (16:9)
Photorealistic: a busy Bangkok street market at dusk, a mango stall with neat piles of yellow mangoes, a vendor gesturing, a foreign tourist holding up a smartphone toward the vendor. Warm lights, shallow depth of field, cinematic, no readable signs, no brand logos.

### Pitch photo — phone hero (16:9)
Product shot: a modern foldable phone (outer screen) floating at a slight angle on a pure black background, screen blank white for later screenshot insertion, soft studio rim light, Apple keynote style, minimal reflections.
