# FitPact / SquadPledge — Plan de Implementare v2.1

> Audit score: 8.4/10 → target: 9.5/10
> Constrângeri: max 150 linii/sub-task, max 2 fișiere/sub-task
> Target Flutter: ^3.22.0

---

## Pachete Externe (Global)

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.11.0
  google_mlkit_pose_detection: ^0.12.0
  sqflite: ^2.4.1
  path_provider: ^2.1.5
  supabase_flutter: ^2.8.4
  firebase_core: ^3.12.0
  firebase_messaging: ^15.2.0
  flutter_local_notifications: ^18.1.0
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  crypto: ^3.0.6
  uuid: ^4.5.1
  go_router: ^14.8.0
  flutter_bloc: ^9.1.0
  equatable: ^2.0.7
```

---

## Dependency Graph

```
Task 1 ──► Task 2 ──► Task 4 ──► Task 5 ──► Task 11
              │                    │
              ▼                    ▼
           Task 3               Task 6
                                 │
                                 ▼
                              Task 7
                                 │
                                 ▼
                              Task 8
                                 │
                                 ▼
                              Task 9 ──► Task 10 ──► Task 12
```

⚠️ **Dependency Warnings:**
- **Task 5** depinde de **Task 4** (CameraMLPipeline) — nu începe UI înainte ca pipeline-ul să fie gata
- **Task 6** depinde de modelele din **Task 1** (enums, extensions)
- **Task 7** (auth) poate rula **în paralel** cu **Task 6**
- **Task 8** depinde de **Task 7** (auth) + **Task 6** (offline)
- **Task 10** depinde de **Task 7** (auth pentru userId)
- **Task 12** rulează după **toate** taskurile

---

## Task 1: MathAndBaseEngine (6 sub-taskuri)

**Pachete:** `vector_math`, `crypto`

### 1a — Point3D (~80 linii, 1 fișier)
- **Fișier:** `lib/core/math/point_3d.dart`
- `Point3D(x, y, z)` cu `distanceTo`, `angleBetween`, `dot`, `cross`, `normalize`, `scale`, `operator +`
- **DoD:** ✅ Toate metodele ✅ Teste unitare ✅ dartdoc pe fiecare metodă

### 1b — AngleCalculator (~70 linii, 1 fișier)
- **Fișier:** `lib/core/math/angle_calculator.dart`
- `AngleCalculator.calculate(Point3D a, Point3D b, Point3D c)` → unghi la B; `isInRange`, `isWithinThreshold`
- **DoD:** ✅ Calcule verificabile matematic ✅ Teste cu valori cunoscute ✅ Edge case: puncte coliniare

### 1c — Enums & Extensions (~60 linii, 1 fișier)
- **Fișier:** `lib/core/enums/exercise_enums.dart`
- `ExerciseType`, `ExercisePhase`, `RepQuality`, `SyncStatus`, `DeviceOrientation` cu metode display
- **DoD:** ✅ Toate enums-urile definite ✅ Metode de display ✅ Testate toate valorile

### 1d — BaseExerciseStateMachine (~100 linii, 1 fișier)
- **Fișier:** `lib/core/math/base_exercise_state_machine.dart`
- Clasă abstractă cu stare curentă, istoric tranziții, `transition(phase)`, `reset()`, `canTransitionTo(phase)`
- **DoD:** ✅ Tranziții validate ✅ Istoric păstrat ✅ Testat fiecare combo

### 1e — Core Utils (~50 linii, 1 fișier)
- **Fișier:** `lib/core/utils/extensions.dart`
- Extensions: `double.roundToDecimals`, `toRadians`, `toDegrees`, `List<Point3D>.average`, `.centerOfMass`
- **DoD:** ✅ Extensions implementate ✅ Testate cu valori de frontieră

### 1f — Tests Math (~130 linii, 2 fișiere)
- **Fișiere:** `test/core/math/angle_math_test.dart` + `test/core/utils/extensions_test.dart`
- **DoD:** ✅ Coverage > 90% ✅ Edge cases ✅ Performanță (1000 calcule < 100ms)

---

## Task 2: PushUpSquatEngine (5 sub-taskuri)

**Pachete:** — (doar dependințe interne pe Task 1)
⚠️ **Rulează după Task 1**

### 2a — PushUpStateMachine structură+tranziții (~120 linii)
- **Fișier:** `lib/features/exercise/pushup_state_machine.dart`
- Faze: setup→down→up→recovery; detectează unghi cot 90° (down), braț întins (up)
- **DoD:** ✅ Faze implementate ✅ Tranziții corecte ✅ Edge: rep din poziție incorectă → reset cu warning

### 2b — PushUpFormValidator (~120 linii)
- **Fișier:** `lib/features/exercise/pushup_form_validator.dart`
- `validateShoulderAngle`, `validateElbowAngle`, `validateBodyAlignment`, `validateDepth` → `FormFeedback` cu scor + mesaj
- **DoD:** ✅ Validări implementate ✅ Scor 0.0–1.0 ✅ Edge: unghiuri lipsă → incomplete

### 2c — SquatStateMachine (~140 linii)
- **Fișier:** `lib/features/exercise/squat_state_machine.dart`
- Faze: setup→down→up→recovery; unghi genunchi 90° (down), 170°+ (up)
- **DoD:** ✅ Faze + tranziții ✅ Detecție adâncime ✅ Edge: squat parțial → nu contează

### 2d — Tests PushUp (~120 linii)
- **Fișier:** `test/features/exercise/pushup_test.dart`
- **DoD:** ✅ Tranziții acoperite ✅ Validare testată ✅ Dispose testat (fără memory leaks)

### 2e — Tests Squat (~100 linii)
- **Fișier:** `test/features/exercise/squat_test.dart`
- **DoD:** ✅ Tranziții squat ✅ Detecție adâncime ✅ Reset între seturi

---

## Task 3: PlankBurpeeEngine (5 sub-taskuri)

**Pachete:** —
⚠️ **Rulează după Task 1. Poate rula în paralel cu Task 2.**

### 3a — PlankStateMachine (~120 linii)
- **Fișier:** `lib/features/exercise/plank_state_machine.dart`
- Faze: setup→hold→recovery; timer durată hold; detectează cădere șolduri
- **DoD:** ✅ Timer ✅ Detecție cădere (unghi > 15°) ✅ Edge: ridicare în timpul hold → reset

### 3b — PlankScorer (~100 linii)
- **Fișier:** `lib/features/exercise/plank_scorer.dart`
- Scor: durată hold, aliniere corp, stabilitate (deviație standard)
- **DoD:** ✅ Scor corect ✅ Factori ponderați ✅ Edge: plank < 5s → scor 0

### 3c — BurpeeStateMachine (~140 linii)
- **Fișier:** `lib/features/exercise/burpee_state_machine.dart`
- Faze: setup→down→plank→jump→up→recovery; secvență 5 pași
- **DoD:** ✅ 5 faze implementate ✅ Tranziții în ordine ✅ Edge: săritură incompletă → nu contează

### 3d — Tests Plank (~120 linii)
- **Fișier:** `test/features/exercise/plank_test.dart`
- **DoD:** ✅ Timer testat cu fake_async ✅ Cădere detectată ✅ Scor verificat

### 3e — Tests Burpee (~120 linii)
- **Fișier:** `test/features/exercise/burpee_test.dart`
- **DoD:** ✅ Fiecare fază testată ✅ Secvența completă ✅ Fără tranziții invalide

---

## Task 4: CameraMLPipeline (6 sub-taskuri)

**Pachete:** `camera`, `google_mlkit_pose_detection`
⚠️ **Rulează după Task 1**

### 4a — PoseDetectorService init (~90 linii)
- **Fișier:** `lib/features/camera/pose_detector_service.dart`
- Inițializare detector ML Kit, configurare accuracy mode, lifecycle
- **DoD:** ✅ Detector inițializat ✅ Configurare ✅ dispose()

### 4b — PoseDetectorService procesare (~120 linii)
- **Fișier:** `lib/features/camera/pose_detector_service.dart` (adaugă la 4a)
- `processImage(InputImage)` → `List<Point3D>`; mapare + filtrare confidence
- **DoD:** ✅ Landmarks mapate ✅ Filtrare ✅ InputImage invalid → listă goală

### 4c — FrameProcessor (~130 linii)
- **Fișier:** `lib/features/camera/frame_processor.dart`
- Procesare frame-uri max 15fps, caching, skip când ocupat
- **DoD:** ✅ Rată controlată ✅ Skip corect ✅ Ultimul rezultat disponibil

### 4d — CameraService + Preview (~120 linii, 2 fișiere)
- **Fișiere:** `lib/features/camera/camera_service.dart` + `lib/features/camera/camera_preview_widget.dart`
- Inițiere cameră, zoom/flash, comutare față/spate
- **DoD:** ✅ Camera pornește ✅ Preview ✅ Comutare ✅ Zoom/flash

### 4e — PipelineCoordinator (~100 linii)
- **Fișier:** `lib/features/camera/pipeline_coordinator.dart`
- Coordinare: cameră→detector→stateMachine→UI; buffer 3 frame-uri
- **DoD:** ✅ Componente conectate ✅ Flux complet ✅ Buffer gestionat

### 4f — Error handling cameră+ML (~80 linii)
- **Fișier:** `lib/features/camera/camera_error_handler.dart`
- Permisiuni refuzate, cameră indisponibilă, baterie < 15%, detector timeout
- **DoD:** ✅ Fiecare eroare tratată ✅ Fallback la mod manual ✅ Mesaj utilizator

---

## Task 5: WorkoutUIAndFeedback (10 sub-taskuri)

**Pachete:** `flutter_bloc`, `shimmer`, `lottie`
⚠️ **Rulează după Task 4**

### 5a — PosePainter schelet (~130 linii)
- **Fișier:** `lib/features/ui/pose_painter.dart`
- CustomPainter — oase între landmark-uri, verde (bun) / roșu (greșit)
- **DoD:** ✅ Schelet desenat ✅ Culori corecte ✅ Se redesenează la update

### 5b — PosePainter unghiuri+text (~80 linii)
- **Fișier:** `lib/features/ui/pose_painter.dart` (adaugă la 5a)
- Valori unghi lângă articulații, text feedback, highlight problemă
- **DoD:** ✅ Unghiuri afișate ✅ Text feedback ✅ Highlight articulație

### 5c — RepCounterOverlay (~100 linii)
- **Fișier:** `lib/features/ui/rep_counter_overlay.dart`
- Contor mare centrat sus, animație la creștere, indicator fază
- **DoD:** ✅ Contor afișat ✅ Animație ✅ Fază curentă vizibilă

### 5d — FeedbackOverlay (~100 linii)
- **Fișier:** `lib/features/ui/feedback_overlay.dart`
- FormFeedback iconiță+text, animație fade, culoare verde/galben/roșu
- **DoD:** ✅ Feedback afișat ✅ Animație ✅ Culoare corectă

### 5e — ManualModeScreen layout (~80 linii)
- **Fișier:** `lib/features/ui/manual_mode_screen.dart`
- Buton "+1 Rep", timer, contor
- **DoD:** ✅ Layout ✅ Buton funcțional ✅ Timer afișat

### 5f — ManualModeScreen logică (~70 linii)
- **Fișier:** `lib/features/ui/manual_mode_screen.dart` (adaugă la 5e)
- Undo, reset, validare, feedback vizual
- **DoD:** ✅ Undo ✅ Reset ✅ Validare ✅ Feedback

### 5g — WorkoutCameraScreen layout (~80 linii)
- **Fișier:** `lib/features/ui/workout_camera_screen.dart`
- Scaffold cu AppBar, Stack cameră+overlays, butoane pauză/stop/switch
- **DoD:** ✅ Layout ✅ Butoane ✅ Stack corect

### 5h — WorkoutCameraScreen integrare (~70 linii)
- **Fișier:** `lib/features/ui/workout_camera_screen.dart` (adaugă la 5g)
- Lifecycle, stream subscription, error boundaries, navigare final
- **DoD:** ✅ Lifecycle gestionat ✅ Stream-uri ✅ Navigare ✅ Erori

### 5i — Error/loading/empty states workout (~100 linii)
- **Fișier:** `lib/features/ui/workout_error_states.dart`
- Shimmer loading, empty state („no camera"), error state cu retry, offline banner
- **DoD:** ✅ 3 stări implementate ✅ Retry funcțional ✅ Fără ecran alb

### 5j — Onboarding flow (~120 linii)
- **Fișier:** `lib/ui/screens/onboarding_screen.dart`
- 3 ecrane: bun venit, cum funcționează, permisiuni; paginator + skip
- **DoD:** ✅ 3 pași ✅ Skip ✅ Permisiuni cerute la pasul 3 ✅ Navigare la login

---

## Task 6: RoomOfflineSync (7 sub-taskuri)

**Pachete:** `sqflite`, `path`, `path_provider`, `uuid`
⚠️ **Rulează după Task 1. Poate rula în paralel cu Task 4.**

### 6a — WorkoutSession model (~60 linii)
- **Fișier:** `lib/core/models/workout_session.dart`
- `WorkoutSession(id, userId, exerciseType, startTime, endTime, repCount, formAverage, status)` + fromJson/toJson
- **DoD:** ✅ Câmpuri ✅ Serializare ✅ Imutabil

### 6b — RepRecord model (~50 linii)
- **Fișier:** `lib/core/models/rep_record.dart`
- `RepRecord(id, sessionId, timestamp, phaseDurations, formFeedback, landmarksJson)`
- **DoD:** ✅ Câmpuri ✅ Serializare ✅ Relație many-to-one

### 6c — SyncQueueEntry model (~50 linii)
- **Fișier:** `lib/core/models/sync_queue_entry.dart`
- `SyncQueueEntry(id, entityType, entityId, action, payload, status, retryCount, createdAt)`
- **DoD:** ✅ Câmpuri ✅ Status machine ✅ Timestamp

### 6d — LocalDatabaseService CRUD (~130 linii)
- **Fișier:** `lib/core/storage/database_service.dart`
- `insert`, `update`, `delete`, `getById`, `getAll` pentru WorkoutSession + RepRecord
- **DoD:** ✅ CRUD funcțional ✅ Transaction support ✅ Erori tratate

### 6e — LocalDatabaseService queries (~100 linii)
- **Fișier:** `lib/core/storage/database_service.dart` (adaugă la 6d)
- `getSessionsByDateRange`, `getUnsyncedSessions`, `getLastNSessions`, `getStreakData`
- **DoD:** ✅ Query-uri funcționale ✅ Performanță ✅ Indexuri

### 6f — SyncManager queue+retry (~80 linii)
- **Fișier:** `lib/core/storage/sync_manager.dart`
- FIFO queue, retry backoff exponențial (max 3), mark failed
- **DoD:** ✅ Queue FIFO ✅ Backoff ✅ Max retry

### 6g — SyncManager conflict resolution (~70 linii)
- **Fișier:** `lib/core/storage/sync_manager.dart` (adaugă la 6f)
- last-write-wins cu timestamp, server wins, notificare utilizator
- **DoD:** ✅ Conflict rezolvat ✅ Server wins ✅ Notificare

---

## Task 7: SupabaseDDLAndAuth (7 sub-taskuri)

**Pachete:** `supabase_flutter`, `supabase`
⚠️ **Poate rula în paralel cu Task 6.**

### 7a — SQL tabele (~100 linii)
- **Fișier:** `supabase/migrations/001_initial_schema.sql`
- `profiles`, `workout_sessions`, `rep_records`, `challenges`, `challenge_members`, `proofs`
- **DoD:** ✅ Tabele create ✅ ENUM-uri ✅ Indexuri ✅ Constrângeri

### 7b — SQL RLS (~60 linii)
- **Fișier:** `supabase/migrations/002_rls_policies.sql`
- Profile: select own. Sessions: insert own, select own+squad. Challenges: select public.
- **DoD:** ✅ RLS activate ✅ Politici corecte ✅ Testat cu auth.uid()

### 7c — Google Sign-In (~80 linii)
- **Fișier:** `lib/core/auth/supabase_auth_service.dart`
- Configurare client, `signInWithProvider(Provider.google)`, session persistence, logout
- **DoD:** ✅ Login funcțional ✅ Logout ✅ Token refresh

### 7d — Magic Link (~60 linii)
- **Fișier:** `lib/core/auth/supabase_auth_service.dart` (adaugă la 7c)
- `signInWithOtp(email)`, `signInAnonymously()`, upgrade cont anonim
- **DoD:** ✅ Magic Link trimis ✅ Cont anonim ✅ Upgrade

### 7e — Auth state listener (~50 linii)
- **Fișier:** `lib/core/auth/auth_state_listener.dart`
- Stream authState, redirect login, refresh token
- **DoD:** ✅ Stream ✅ Redirect ✅ Refresh automat

### 7f — GDPR consent flow (~120 linii)
- **Fișier:** `lib/ui/screens/gdpr_consent_screen.dart`
- Consimțământ primul login, opțiuni analytics/personalizare, drept ștergere
- **DoD:** ✅ Ecran ✅ Opțiuni ✅ Logare în baza de date ✅ Ștergere cont

### 7g — Error handling rețea+auth (~80 linii)
- **Fișier:** `lib/core/auth/auth_error_handler.dart`
- Network timeout, invalid credentials, rate limit, token expired
- **DoD:** ✅ Fiecare eroare tratată ✅ Mesaj utilizator ✅ Retry

---

## Task 8: ChallengeLoop (8 sub-taskuri)

**Pachete:** `supabase_flutter` (realtime)
⚠️ **Rulează după Task 7 + Task 6**

### 8a — Challenge model (~50 linii)
- **Fișier:** `lib/core/models/challenge.dart`
- `Challenge(id, title, exerciseType, goalReps, durationDays, status)` + fromMap/toMap
- **DoD:** ✅ Câmpuri ✅ Serializare ✅ Imutabil

### 8b — ChallengeMember model (~40 linii)
- **Fișier:** `lib/core/models/challenge_member.dart`
- `ChallengeMember(challengeId, profileId, joinedAt, totalReps, livesRemaining)`
- **DoD:** ✅ Câmpuri ✅ Serializare

### 8c — Create/join/leave logic (~120 linii)
- **Fișier:** `lib/core/repositories/challenge_repository.dart`
- `createChallenge`, `joinChallenge`, `leaveChallenge` + validări (max 10 membri)
- **DoD:** ✅ CRUD ✅ Validări ✅ Erori tratate

### 8d — Invite code generation (~70 linii)
- **Fișier:** `lib/core/repositories/invite_code_repository.dart`
- Generare cod 6 char alfanumeric, `generateInviteCode`, `joinByInviteCode`
- **DoD:** ✅ Cod generat ✅ Unic ✅ Join funcțional

### 8e — Invite code rate limiting (~50 linii)
- **Fișier:** `lib/core/repositories/invite_code_repository.dart` (adaugă la 8d)
- Max 5 încercări/minut, reset la timeout
- **DoD:** ✅ Limită ✅ Reset ✅ Prevenție brute-force

### 8f — Squad feed + real-time (~120 linii)
- **Fișier:** `lib/ui/widgets/squad_feed_widget.dart`
- Stream Supabase Realtime, actualizare leaderboard live, widget feed
- **DoD:** ✅ Realtime ✅ Leaderboard live ✅ Widget funcțional

### 8g — Leaderboard + lives system (~120 linii)
- **Fișier:** `lib/ui/screens/leaderboard_screen.dart`
- Sortare totalReps, 3 lives, refresh la midnight
- **DoD:** ✅ Leaderboard ✅ Lives ✅ Refresh

### 8h — Error/loading/empty states challenge (~100 linii)
- **Fișier:** `lib/ui/widgets/challenge_error_states.dart`
- Shimmer loading, empty („no challenges"), error retry, offline
- **DoD:** ✅ 3 stări ✅ Retry ✅ Fără ecran alb

---

## Task 9: AntiCheatAndProof (7 sub-taskuri)

**Pachete:** `crypto`
⚠️ **Rulează după Task 6 + Task 7**

### 9a — ProofGenerator JSON (~80 linii)
- **Fișier:** `lib/core/proof/proof_generator.dart`
- 3-5 snapshot-uri landmark per rep, JSON array ProofFrame
- **DoD:** ✅ Snapshot-uri ✅ JSON ✅ Metadata incluse

### 9b — ProofGenerator HMAC (~80 linii)
- **Fișier:** `lib/core/proof/proof_generator.dart` (adaugă la 9a)
- HMAC-SHA256, atașare semnătură, verificare integritate
- **DoD:** ✅ HMAC ✅ Verificare ✅ Cheie derivată

### 9c — Layer 1 (~80 linii)
- **Fișier:** `lib/core/anti_cheat/layer_1_on_device.dart`
- Frecvență frame, mișcare plauzibilă, frame-uri identice
- **DoD:** ✅ Detectare ✅ Threshold ✅ Fără false positives

### 9d — Layer 2 (~80 linii)
- **Fișier:** `lib/core/anti_cheat/layer_2_on_device.dart`
- Durată minimă per rep, range unghi complet, varianță
- **DoD:** ✅ Durată ✅ Range ✅ Varianță

### 9e — Layer 3 (~80 linii)
- **Fișier:** `lib/core/anti_cheat/layer_3_server.dart`
- Timestamp-uri, HMAC, deviceId cross-check
- **DoD:** ✅ Timestamp ✅ HMAC ✅ DeviceId

### 9f — Layer 4 (~80 linii)
- **Fișier:** `lib/core/anti_cheat/layer_4_community.dart`
- 3 membri random, threshold 2/3
- **DoD:** ✅ Selecție random ✅ Threshold ✅ Rezultat final

### 9g — Tests anti-cheat (~120 linii)
- **Fișier:** `test/core/anti_cheat/anti_cheat_test.dart`
- Proof generation + HMAC, Layer 1-2 suspect, Layer 3 timestamp invalid
- **DoD:** ✅ Coverage > 80% ✅ Edge cases ✅ Fără false positives

---

## Task 10: FCMNotifications (5 sub-taskuri)

**Pachete:** `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
⚠️ **Rulează după Task 7**

### 10a — FCM init+token (~60 linii)
- **Fișier:** `lib/core/notifications/fcm_service.dart`
- Configurare Firebase Messaging, token registration
- **DoD:** ✅ Firebase inițializat ✅ Token înregistrat

### 10b — FCM token refresh (~50 linii)
- **Fișier:** `lib/core/notifications/fcm_service.dart` (adaugă la 10a)
- Refresh handler, subscribe/unsubscribe topics
- **DoD:** ✅ Refresh ✅ Topics

### 10c — Notification types + deep linking (~100 linii)
- **Fișier:** `lib/core/notifications/notification_handler.dart`
- 6 tipuri: reminder, streak, last-life, member dropped, challenge done, dispute + deep link
- **DoD:** ✅ 6 tipuri ✅ Deep link navighează corect

### 10d — Streak notifier (~100 linii)
- **Fișier:** `lib/core/notifications/streak_notifier.dart`
- Streak calculator (3/7/14/30/60), trigger notificare la milestone
- **DoD:** ✅ Calculator ✅ Trigger ✅ Fără duplicate

### 10e — Deep link routing setup (~80 linii)
- **Fișier:** `lib/core/routing/deep_link_handler.dart`
- Configurare go_router, mapare notification type → screen
- **DoD:** ✅ GoRouter configurat ✅ Mapare ✅ Fallback la home

---

## Task 11: ThemeAndPolish (4 sub-taskuri)

**Pachete:** `google_fonts`, `flutter_svg`

### 11a — Design tokens (~60 linii)
- **Fișier:** `lib/ui/theme/app_colors.dart`
- Action Cyan #00D2FF, Trust Navy #112233, Winner Magenta #F0148C, neutre
- **DoD:** ✅ Culori definite ✅ Constante ✅ Comentarii

### 11b — ThemeData (~80 linii)
- **Fișier:** `lib/ui/theme/app_theme.dart`
- ThemeData cu culori, TextTheme, ButtonTheme, AppBarTheme, CardTheme
- **DoD:** ✅ ThemeData ✅ Toate componentele ✅ Dark mode opțional

### 11c — Typography + splash (~100 linii, 2 fișiere)
- **Fișiere:** `lib/ui/theme/app_typography.dart` + `lib/ui/screens/splash_screen.dart`
- Montserrat Bold (headings), Work Sans (body), splash cu animație
- **DoD:** ✅ Fonturi ✅ Splash ✅ Animație

### 11d — Launcher icon + polish (~80 linii)
- Config android/app/src/main/res/, transition animations, error states
- **DoD:** ✅ Icon ✅ Tranziții ✅ Error states

---

## Task 12: RunAndVerify (3 sub-taskuri)

**Pachete:** `integration_test`
⚠️ **Rulează ultimul, după toate taskurile**

### 12a — E2E test (~100 linii)
- **Fișier:** `test/integration/e2e_test.dart`
- Login → join challenge → camera rep detection → proof submission → squad feed update
- **DoD:** ✅ Tot flow-ul ✅ Assert-uri ✅ Fără crash

### 12b — Regression suite (~100 linii)
- **Fișier:** `test/integration/regression_test.dart`
- Toate testele unitare + integrare, release build check
- **DoD:** ✅ Toate testele ✅ Release build ✅ Zero warnings

### 12c — Performance + crashes test (~80 linii)
- **Fișier:** `test/integration/performance_test.dart`
- Memorie cameră prelungită, offline queue, 1000 frame-uri
- **DoD:** ✅ Fără memory leaks ✅ Queue funcțional ✅ Frame-uri procesate

---

## Sumar

| Task | Sub-taskuri | DoD | Pachete | Depinde de |
|------|:-----------:|:---:|:-------:|:----------:|
| 1. Math & Base | **6** | ✅ | vector_math, crypto | — |
| 2. PushUp & Squat | **5** | ✅ | — | Task 1 |
| 3. Plank & Burpee | **5** | ✅ | — | Task 1 |
| 4. Camera & ML | **6** | ✅ | camera, mlkit | Task 1 |
| 5. Workout UI | **10** | ✅ | bloc, shimmer, lottie | Task 4 |
| 6. Offline Sync | **7** | ✅ | sqflite, uuid | Task 1 |
| 7. Supabase & Auth | **7** | ✅ | supabase_flutter | — (paralel cu 6) |
| 8. Challenge Loop | **8** | ✅ | supabase_flutter | Task 6+7 |
| 9. Anti-Cheat | **7** | ✅ | crypto | Task 6+7 |
| 10. Notifications | **5** | ✅ | firebase, fcm | Task 7 |
| 11. Theme & Polish | **4** | ✅ | google_fonts | — |
| 12. Run & Verify | **3** | ✅ | integration_test | Toate |
| **Total** | **73** | — | — | — |
