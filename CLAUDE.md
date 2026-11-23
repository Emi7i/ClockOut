# ClockOut

Flutter app (Android-first) for clocking in/out of an 8-hour shift, with
repeating end-of-shift alerts, a log history, and a calendar view of logs.

## Commands

```
flutter pub get
flutter analyze          # must stay clean
flutter test             # unit, widget, integration and architecture tests
flutter run -d <device>  # `flutter devices` lists them
```

Widget tests load real fonts (Roboto from the Flutter SDK cache, Iceland from
`assets/fonts`). Without that, flutter_test's wide placeholder font causes
false RenderFlex overflow errors.

## Architecture

Clean architecture under `lib/`, state via `flutter_bloc`, storage via
`sqflite`. Layer rules are **enforced by `test/architecture/`** — run the
tests after moving imports around.

| Layer | Path | May import |
|---|---|---|
| Core | `core/` (constants, utils, services) | nothing app-specific |
| Domain | `domain/` (entities, repositories, use cases) | core |
| Data | `data/` (DB, DTOs, mappers, repo impls) | domain, core |
| Common widgets | `common_widgets/` | core only — **not** domain, data or features |
| Features | `features/<name>/{bloc,screens,widgets}` | domain, core, common_widgets |

- Features must not import data, other features' blocs, or repositories from
  `screens/` / `widgets/` (blocs may use repositories).
- `lib/app_shell.dart` owns navigation: tab 0 Clock, tab 1 Logs, Settings as an
  overlay, Calendar as a pushed route (calendar icon in `AppTopBar`).
- DI happens in `lib/main.dart`; `GetLogsUseCase` and `LogRepository` are
  provided through `RepositoryProvider`.
- UI uses `package:material_ui/material_ui.dart`, not `material.dart`.
- Tokens live in `core/constants` (`AppColors`, `AppTextStyles`,
  `AppDimensions`). Add new colors/styles there rather than inline.
- The live accent color is the user's pick:
  `Theme.of(context).colorScheme.primary` (never hard-code the default).

## Design

The app is being **redesigned from Figma** ("Orbit App – Earth Day Night",
file `XPIeLgaUoCSYFzCVQ5coOY`). The calendar screen (node `55:4335`) is the
first redesigned screen: Roboto, near-black surfaces, accent color taken from
the user's setting where Figma uses blue. Clock, Logs and Settings screens
still use the old layout until they are redone (they now share the new fonts).

SVG assets are exported from Figma as SVG (rendered with `flutter_svg`). If a
PNG is ever needed, export it at **512x512** — Figma's native size is too
small and looks pixelated.

## Business rules

### Logs and bonus time
- Shift standard is **8 hours** (`AppConstants.shiftDuration`).
- Clocking out *after* the shift end rounds **down** to 30-minute steps
  (`LogEntry.computeBonusTime`), so 15 minutes over adds nothing and is still a
  normal shift. Clocking out *before* the shift end gives the exact deficit.
- `LogEntry.status`: `onTime` (bonus 0), `early` (positive bonus), `late`
  (negative bonus, i.e. left early).
- **There is only ever one log per day.** The calendar indexes logs by day and
  would only show one if two shared a date.
- **Log types** (`LogType`, `LogEntry.type`): `normal` (clocked in/out in the
  app), `remote` (`onlineWork`) and `vacation` (`vacation`, DB column added in
  schema v3). Remote and vacation days are **added manually** (never clocked
  through the app), have no clock times and a zero bonus. Remote counts as an
  8h day.
- Manual logs are made in the calendar's **add/edit popup** (`LogEditorPopup`)
  and built with `LogEntry.manual`. Normal entries need both times (leave after
  enter) and get a computed bonus. A day that already has a log can't get
  another.
- Adding, editing and deleting single logs happens **only** in that popup. The
  old edit dialog and the Logs tab's edit mode were removed.

### Calendar screen (`features/calendar/`)
- Sunday–Saturday month grid; swipe to change month (`SensitivePagePhysics`
  turns the page after ~15% of a drag). Drag the handle below the grid to
  condense to one week (tap toggles).
- Each day cell always reserves room for a cat above the number.
- Agenda below the grid lists **every day of the visible month**, with
  "No event" on empty days. Tapping a date scrolls to it; swiping months
  switches the list (starting at today, or the 1st).
- Cat per log (`CatAssets.forLog`): vacation → Vacation; remote → Remote work;
  bonus → Bonus time; left early → Early leave; otherwise → Worker. Titles:
  "Bonus N minutes", "Left early N minutes", "Just in time", "Remote work",
  "Vacation".
- **Edit pen:** every log row has one. It opens the same popup the add button
  opens, prefilled and titled "Edit log" with a "Save" button and a small red
  trash can in the top right (deletes the log).
- **Add button** (`AddLogLauncher`, bottom right): one controller turns the plus
  180° + 45° (0.625 turns — only the plus, not its frame) while the popup
  scales up in the middle of the screen (scaled to nearly full width), over a
  dimming tap-to-close scrim that leaves the button undimmed.
- **Popup layout** (Figma node `64:5813`), all centered: title, **Type** slider
  (Normal / Remote / Vacation), then the date and Time enter / Time leave
  (remote disables the times). Choosing **Vacation** replaces everything below
  the type with a **From / To** date range (one range picker), saving one
  vacation log per day. Days that already have a log are skipped. Editing a
  vacation can stretch it over more days. The type slider only rests on its
  three keypoints: tapping a segment slides the thumb there, dragging snaps to
  the segment under the finger.

### Clock lifecycle (`ClockBloc`)
- **Clock in** starts a session and schedules alerts for shift end (T + 8h).
- **During the shift** a timer counts down. The user can edit `clockedInAt`;
  the end time is recalculated and all pending alerts are rescheduled.
- **At shift end** the UI switches to a large "Clock out" state with a
  countdown to the next alert, and alerts repeat every `alarmDelayMinutes`
  (e.g. 30) indefinitely until the user clocks out.

### Alerts
Alarm sound and notifications are decoupled:
- The **alarm toggle** controls only the loud hardware alarm (`alarm` package).
- Notifications (`flutter_local_notifications`) are **always** scheduled and
  wake the screen. Toggle on → paired with the alarm; off → a silent
  notification.
- **"Stop the Alarm"** silences the current ring but keeps the user clocked in;
  the countdown to the next repeat continues.
- The loop survives app kills: dismissing a notification while the app is dead
  reads its payload (delay, sound preference) and schedules the next repeat.
- The active session and alarm toggle are persisted in SQLite, so reopening
  the app resumes the countdown and re-syncs alarms.

### Entities
- `ActiveSession`: `clockedInAt`, `nextAlarmIn`, `alarmEnabled`.
- `LogEntry`: date, bonus time, clock in/out, `userEdited`, `onlineWork`.
- `UserSettings`: accent color, clock format (12/24h), `alarmDelayMinutes`.

## TODO / known gaps
- **Theming:** only the dark cat set is used. Light variants exist in
  `assets/cats/` (`*_cat.svg`); switch in `CatAssets._variant` when light mode
  is added.
- **Calendar:** the header's collapse chevron and "more options" button do
  nothing yet. Tapping a grayed-out day from an adjacent month selects it but
  can't scroll the agenda to it (it isn't in the shown month).
- **Redesign:** bring Clock, Logs and Settings screens to the new Figma style.
- **Vacation cat is a placeholder** (`assets/cats/vacation_cat*.svg`) — replace
  with the real light and dark art.
- **Hours totals:** `LogsBloc` sums hours from clock times, so remote and
  vacation days currently count as 0h (remote is meant to count as 8h).
  Undecided: whether remote/vacation should count toward the weekly/monthly
  totals.
