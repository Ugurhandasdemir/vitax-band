# Stitch prompt v2 (6 ekranlık 5 parti, ilk brief eksiksiz kapsanıyor)

Kullanım: Stitch her üretimde en fazla 6 ekran verir. Her partiyi ayrı üret.
Her seferinde "ORTAK BAŞLIK" + ilgili "PARTİ" metnini birlikte yapıştır.
Tutarlılık için üretilen ekranları Shift ile seçip tek seferde tema değişikliği uygulayabilirsin.
Stitch hareket üretmez: animasyonlu egzersiz alanı, tasarımda "döngü rozetli çerçeve" olarak çizilir,
gerçek animasyon uygulamada (egzersiz veri setindeki GIF'ler) çalışır.
İngilizce arayüz istersen "UI language: Turkish" satırını sil.

---

## ORTAK BAŞLIK (her partinin başına)

```
A clean, high-contrast, friendly personal health app for iPhone that tracks calories, workouts and smart-band health data, with an AI personal trainer.

**DESIGN SYSTEM (REQUIRED):**
- Platform: Mobile (iPhone SE 3, 375x667 portrait, home button, no notch, no bottom safe-area inset). Design for this small screen; content scrolls, never clips.
- Theme: Light, minimal, flat (no shadows), generous whitespace, soft rounded shapes
- Background: Cool Lavender White (#FBF8FF) for the canvas
- Surface: Pure White (#FFFFFF) for cards, with a 1px hairline border in Soft Lilac Gray (#E3E1EC)
- Primary Accent: Kinetic Orange (#A93100) for active states, key actions and focus; Bright Orange (#D34000) for filled buttons and the round add button
- Secondary: Health Blue (#0060AC) for progress, heart, hydration and protein
- Tertiary: Emerald Green (#006A34) for positive progress, carbs and good status
- Error: Alert Red (#BA1A1A) for warnings
- Text Primary: Deep Obsidian (#1A1B22); Text Secondary: Warm Umber (#5C4037)
- Typography: Inter only. Display 32/800, Headline 22/700 and 18/700, Body 16 and 14, Labels 14/600, caps labels 11/700 uppercase with wide tracking, micro tags 10/700. Minimum body size 14.
- Shapes: buttons and inputs 10px radius, cards 16-24px radius, chips, search bars and tags fully pill-shaped
- Navigation: bottom tab bar with 5 tabs (icon + label): Dashboard, Activity, Scan, AI Coach, Exercises. The active tab is a filled Kinetic Orange pill. Top bar: left avatar (opens the Profile hub), centered title "Vital Precision", right a small band status chip (green dot, battery %, last sync time).
- UI language: Turkish, friendly plain wording.

**DATA RULES (REQUIRED):**
- No Apple Health or HealthKit anywhere. Steps, distance, active calories, heart rate, resting HR, HRV/stress, sleep (deep / light / awake), SpO2, blood pressure, skin temperature, battery and wear status all come from the VitaxBand smart band over Bluetooth. Mark band metrics with a small "VitaxBand" tag and "2 dk önce güncellendi".
- Only food, water, body weight and workout sets/reps are entered manually.
- Optional sensors (SpO2, blood pressure, temperature, HRV, ECG) need a clear "Bandınız desteklemiyor" state.

**USER-FRIENDLY RULES (REQUIRED):**
- Logging food takes at most 3 taps; show Recent and Favorites first.
- 44px minimum touch targets. The primary action is always in the same place: a full-width Kinetic Orange button at the bottom, or the round orange + button.
- Every empty state explains what to do with one clear button. Undo toast after delete; confirm only destructive actions.
- Never rely on color alone: pair color with an icon or label. Text contrast AAA.
- Progressive disclosure: summary first, details behind a tap.
- Exercise demonstrations: the media is a square looping animated demo (about 180x180) inside a rounded card, not a full-bleed photo. Show a small "Döngü" badge, a pause/play button, a 0.5x / 1x speed toggle and a tiny "© Gym visual" credit line. In lists use a 72x72 animated thumbnail.
```

---

## PARTİ 1: Çekirdek (6 ekran)

```
**Page Structure (6 mobile screens):**
1. **Dashboard:** top bar; "Bugün" date header with a calendar button; daily coach briefing card (readiness score, today's plan: workout, calories, water; one insight; "Planı gör" button); Calories card with a ring (1,420 / 2,100 kcal), BURNED 450 (from the band) and REMAINING 680; three macro cards: Protein 112/150 g (blue), Carbs 150/250 g (green), Fat 32/70 g (orange) with percentage chips; compact band card (heart rate 72 bpm, steps 8,432, last night's sleep 7s 12dk, VitaxBand tag); "Bugünün öğünleri" list (Kahvaltı 420, Öğle 650, Akşam --) with a round orange + button; Hydration module with a 5-segment bar 1.2 L / 2.5 L and quick-add buttons 200 ml, 300 ml and Şişe.
2. **Calorie Tracking (dedicated food diary):** horizontal week date strip with today selected; daily summary bar (eaten, goal, remaining, and net calories = eaten minus band-burned); three slim macro bars; meal sections Kahvaltı, Öğle, Akşam, Atıştırmalık, each with item rows (name, portion, kcal, small macro line), a section kcal total and a "+ Yemek ekle" row; a swipe-to-delete hint; chips "Dünü kopyala" and "Hızlı kalori ekle"; a water summary row; sticky bottom button "Yemek ekle"; a friendly empty state for an empty meal.
3. **Scan:** live camera view with Kinetic Orange corner brackets and the hint "Barkodu çerçeveye alın"; segmented switch Barkod | Fotoğraf; flash and shutter controls; bottom sheet "Son kayıtlar" with recent item cards (photo, name, kcal, meal chip); a "Elle ara" link.
4. **Health & Activity, Today:** segmented control Bugün | Kalp | Uyku | Antrenman | Kilo; band sync card ("VitaxBand bağlı" with green dot, battery, "Şimdi senkronla", last sync time); Steps 8,432 / 10k and Active Energy 412 kcal progress tiles; distance tile; live heart rate 72 bpm with resting 58; readiness score; small 24-hour heart-rate sparkline.
5. **Weight:** "Kilo" card 76.4 kg with goal 72 kg and the remaining difference; interactive line chart with 7G / 30G / 90G chips and a tooltip on the selected point; "Kilo kaydet" button; recent entries list; goal progress bar.
6. **AI Coach chat:** coach message with a blue robot avatar, user message in an orange bubble, an inline recommendation card (Aktif toparlanma, Beslenme odağı), typing indicator; a "Kullanılan veriler" chip row (Uyku 7g, Dinlenik nabız, Adımlar, Öğünler, Antrenmanlar); suggested prompt chips; and a REAL text input bar with microphone and send button above the tab bar.
```

---

## PARTİ 2: Egzersiz ve antrenman (6 ekran)

```
**Page Structure (6 mobile screens):**
1. **Exercise Library:** title, pill search bar, muscle filter chips (Tümü, Göğüs, Sırt, Bacak, Kol, Omuz, Karın) and a two-option toggle "Egzersizler | Rutinler". Egzersizler view: rows with a 72x72 animated thumbnail, name, target muscle, equipment chip and an arrow. Rutinler view: routine cards (Push Day, Pull Day, Leg Day) with exercise count, estimated duration, last done date and a "Başlat" button.
2. **Exercise Details:** back bar; square looping animated demo card (Döngü badge, pause/play, 0.5x / 1x toggle, © Gym visual); name with intensity and equipment chips; Equipment and Mechanics tiles; Muscle Focus list (1 Primary, 2 Secondary, 3 Stabilizer); Execution steps as numbered timeline cards; Key Benefits list; a "Geçmişim" mini card (last weights and reps, best set); sticky "Antrenmana ekle" button.
3. **Workout Builder:** routine name field; exercise rows with animated thumbnails, sets x reps x weight steppers, a drag handle and delete; "Egzersiz ekle" button; summary of estimated duration and total sets; sticky "Başlat" button.
4. **Active Workout (recorded movement by movement from the band):** timer, live heart rate with a zone bar, kcal burned from the band. Current movement card with its looping animated demo, a big "Seti başlat / Seti bitir" button and a "Sonraki egzersiz" button. A mode switch at the top: Elle | Öneri. In Öneri mode, soft banners appear from heart-rate changes ("Nabız yükseliyor, set başlamış olabilir", "Nabız düşüyor, dinlenme başlamış olabilir") each with Onayla / Yoksay (suggestions, never silent). Set logger (weight x reps, check), rest timer that also shows heart-rate recovery (bpm drop in 60 s), and a live heart-rate sparkline with each set shaded as a segment.
5. **Workout Summary:** session timeline with the heart-rate curve and every movement/set as a labeled shaded segment; per-movement table (sets, reps x weight, average and peak HR, time under effort, HR recovery after the set, kcal); totals, personal records, notes; controls to edit, merge or split detected segments.
6. **Workout History:** calendar with streak, weekly volume chart, list of past sessions.
```

---

## PARTİ 3: Beslenme detayları (5 ekran)

```
**Page Structure (5 mobile screens):**
1. **Barcode Result:** product photo, name and brand; portion selector (stepper plus unit chips: porsiyon, gram); macro breakdown with kcal; meal picker chips; "Öğüne ekle" button.
2. **Photo Estimate Result:** the taken photo on top; detected foods as editable rows (name, portion, kcal) with a confidence tag; total kcal and macros; "Yanlış mı? Düzelt" link; "Onayla" button.
3. **Add Food / Search:** pill search bar; tabs Son kullanılan | Favoriler | Tümü; result rows with kcal and a + button; "Özel yemek oluştur" row; quick "Hızlı kalori ekle" entry.
4. **Hydration Log:** large water glass progress 1.2 L / 2.5 L; quick add buttons 200 ml, 300 ml, Şişe; custom amount field; daily goal editor; today's entries list with undo; 7-day history bars.
5. **Calories In vs Out:** weekly bar chart comparing intake with band-measured burn; net calorie line; weight trend overlay; plain-language summary card ("Bu hafta ortalama 320 kcal açık").
```

---

## PARTİ 4: Bant ve sağlık (6 ekran)

```
**Page Structure (6 mobile screens):**
1. **Connect Your Band:** Bluetooth permission explanation; scanning list showing "VitaxBand" with a signal-strength indicator; connecting progress; success state.
2. **My Band:** connection status, battery 98%, firmware, last sync, "Şimdi senkronla", "Bandımı bul"; settings rows: wear detection, time format, automatic heart-rate interval, sedentary reminder, alarms; detected sensors list with "Destekleniyor / Desteklenmiyor" badges.
3. **Heart:** live measure button with a pulse animation hint, 24-hour heart-rate line chart with min and max, 30-day resting-HR trend, heart-rate zones, HRV/stress card; one-line "Tıbbi cihaz değildir" footnote.
4. **Sleep:** last night 7s 12dk, sleep score, stage timeline (derin / hafif / uyanık), bed and wake times, 7-night bar chart, consistency card.
5. **Optional Sensors:** SpO2 97% with day chart, blood pressure, skin temperature. For each, show both the supported state and the "Bandınız desteklemiyor" placeholder.
6. **Connection States:** three compact states on one screen each: disconnected banner with "Yeniden bağlan", syncing progress, sync failed with "Tekrar dene"; plus a full-screen empty state for "Band bağlı değil".
```

---

## PARTİ 5: AI antrenör, veri ve profil (6 ekran)

```
**Page Structure (6 mobile screens):**
1. **Weekly Plan (AI generated):** 7-day calendar with workout and rest days; daily calorie and protein targets; "Bu plan neden?" card explaining the plan with the user's own data (sleep, resting HR, workouts); "Yeniden oluştur" and "Kabul et" buttons.
2. **Insights:** weekly and monthly report with plain-language correlation cards (sleep vs next-day resting heart rate, steps vs weight, calorie balance, recovery trend); period toggle Hafta | Ay.
3. **Data Vault:** storage used; list of what is stored (heart-rate stream, steps, sleep, workouts, meals, weight); sync history log; export CSV/JSON; backup; delete data; per-category toggles for what the AI coach may read.
4. **Profile and Goals:** height, weight, age, sex, activity level; goal selector (Ver / Koru / Al); auto-calculated editable calorie and macro targets; units.
5. **Notifications and Alerts:** toggles for sedentary reminder, low battery, high resting HR, hydration reminders, bedtime reminder, with time pickers.
6. **Welcome and First-run Setup:** friendly welcome; goal choice; height and weight entry; connect-your-band step; progress dots; "Atla" option.
```
