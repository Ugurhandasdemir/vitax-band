# Stitch prompt: eksik ekranlar (tüm veri VitaxBand'dan)

Stitch'e yapıştır. Kesilirse A–G gruplarını tek tek ver (her grupta giriş paragrafını tekrar et).
UI dilini İngilizce istersen "UI language: Turkish" satırını sil.

---

Continue the existing "Vital Precision" iPhone app, designed for iPhone SE 3 (375x667, home button, no notch, no bottom safe-area inset; keep every screen usable at this small size). Keep the design system exactly: Inter font, Kinetic Orange #A93100 primary, blue #0060AC secondary, green #006A34 tertiary, canvas #FBF8FF with white cards, 1px hairline borders, 16-24px rounded corners, pill chips, flat surfaces (no shadows), 44px minimum touch targets, bottom tab bar with the 5 existing tabs: Dashboard, Activity, Scan, AI Coach, Exercises. UI language: Turkish.

PRODUCT: one personal app that combines (1) calorie and macro tracking, (2) workout tracking, (3) a private health-data vault fed ONLY by my VitaxBand smart band over Bluetooth, and (4) an AI personal trainer that reads that stored data. There is NO Apple Health / HealthKit anywhere. Every activity and body signal comes from the band: steps, distance, active calories, heart rate (live and history), resting heart rate, HRV/stress, sleep (deep / light / awake), SpO2, blood pressure, skin temperature, battery level, wear status. Only food intake, water, body weight and workout sets/reps are entered manually. Not every band has every sensor, so optional sensors (SpO2, blood pressure, temperature, HRV, ECG) need a clear "Not supported by your band" state.

NAVIGATION CHANGES: top-left avatar opens a Profile hub (Profile & goals, My Band, Data Vault, Notifications, Settings). Replace the bell icon with a small band status chip (connected dot, battery %, last sync time). The Activity tab becomes "Health & Activity" with a segmented control: Today | Heart | Sleep | Workouts | Weight. Replace every "Apple Health Sync" in existing screens with "VitaxBand Sync" (Sync Now button, last synced time). Add a one-line "not a medical device" footnote on heart-rate and blood-pressure screens.

SCREENS (use realistic sample data):

A. Band and connection
1. Connect your band: Bluetooth permission, scanning list showing "VitaxBand" with signal strength, connecting progress, success.
2. My Band: connection status, battery 98%, firmware, last sync, Sync Now, Find my band, wear detection, time format, auto heart-rate interval, sedentary reminder, alarms, detected sensors list with supported/unsupported badges.
3. Disconnected, syncing and sync-failed states (banner plus full empty state).

B. Health (band data)
4. Today vitals: steps 8,432 / 10k, distance, active kcal 412, live heart rate 72 bpm, resting HR 58, readiness score.
5. Heart: live measure button with pulse animation, 24h heart-rate line chart with min/max, 30-day resting-HR trend, HR zones, HRV/stress card.
6. Sleep: last night 7h12m, sleep score, stage timeline (deep / light / awake), bed and wake times, 7-night bar chart, consistency.
7. Optional sensors: SpO2 97% with day chart, blood pressure, skin temperature. Each with its supported state and its unsupported placeholder.

C. Workouts
8. Workout builder (opened from "Add to Workout"): routine name, exercise list with sets/reps, reorder, Start.
9. Active workout, recorded movement by movement from the band: timer, live heart rate with zone bar, kcal burned from the band. Current movement card with its exercise animation, a big Start set / End set button and a Next exercise button. A mode switch at the top: Manual | Auto-suggest. In Auto-suggest, soft banners appear from heart-rate changes: "Heart rate rising, a set may have started" and "Heart rate dropping, rest may have started", each with Confirm / Dismiss (suggestions, never silent). Set logger (weight x reps, check), rest timer that also shows heart-rate recovery (bpm drop in 60 s). A live heart-rate sparkline with each set shaded as a segment.
10. Workout summary: session timeline with the HR curve and every movement/set as a labeled shaded segment; per-movement table (sets, reps x weight, average and peak HR, time under effort, HR recovery after the set, kcal); totals, personal records, notes; controls to edit, merge or split detected segments.
11. Workout history: calendar with streak, weekly volume chart, past sessions list.

D. Nutrition
12. Barcode result: product, portion selector, macros, Add to meal.
13. Photo estimate result: detected foods with editable portions, confidence, total kcal and macros, Confirm.
14. Add food / meal detail: search, recent, favorites, custom food.
15. Hydration log: 200 ml, 300 ml and bottle quick adds, daily goal, history.
16. Calories in vs out: weekly chart of intake vs band-measured burn, plus weight trend.

E. Weight
17. Weight detail: goal, history list, chart with 7D/30D/90D, log-weight sheet.

F. AI personal trainer
18. Coach chat with a real text input bar, suggested prompts, and an inline "Data used" chip row (Sleep 7d, Resting HR, Steps, Meals, Workouts). Tapping a chip shows what the coach read.
19. Daily briefing card for the Dashboard: readiness, today's plan (workout, calories, water), one insight.
20. Weekly plan generated by AI: 7-day calendar, workout and rest days, calorie and protein targets, "Why this plan" explanation citing my own data, Regenerate / Accept.
21. Insights: weekly and monthly report with plain-language correlation cards (sleep vs next-day resting HR, steps vs weight, calorie balance, recovery trend).

G. Data and profile
22. Data Vault: storage used, what is stored, sync history log, export CSV/JSON, backup, delete data, per-category toggles for what the AI coach may read.
23. Profile and goals: height, weight, age, sex, activity level, goal (lose / maintain / gain), auto-calculated editable calorie and macro targets, units.
24. Notifications and alerts: sedentary, low battery, high resting HR, hydration, bedtime.

ALSO update the existing Dashboard: add a compact band card (heart rate, steps, sleep) and the daily coach briefing. Keep all new screens visually consistent with the existing six.
