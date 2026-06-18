## Business logic
1. Core Entities
   * ActiveSession: Represents a single work session. It tracks clockedInAt,
     nextAlarmIn, and the alarmEnabled state.
   * LogEntry: Represents a historical, completed session. It contains
     calculated metrics like the duration, bonus time, and whether it was
     user-edited.
   * UserSettings: Stores user preferences, most notably the alarmDelayMinutes,
     which dictates the interval for repeating alerts after a shift ends.

  2. The Clock Lifecycle (Managed by ClockBloc)
  The system revolves around an 8-hour shift standard:
   * Clock In: Starts the session. The app calculates the exact time the shift
     ends (T + 8 hours) and schedules the initial alerts.
   * During Shift: A real-time timer ticks down. The user can manually edit
     their clockedInAt time via a time picker. If edited, the system
     recalculates the end-of-shift time and completely reschedules all pending
     alerts to match the new timeline.
   * Shift End (T + 8 hours): The initial alert fires. The UI transitions from a
     standard timer to a large "Clock out" state, showing a countdown to the
     next alert.
   * Indefinite Repeat Loop: After the initial 8 hours, the system enters an
     infinite loop. It schedules an alert every alarmDelayMinutes (e.g., every
     30 minutes) indefinitely until the user explicitly hits "Clock out."

  3. Decoupled Alert System (Sound vs. Notification)
  The app separates aggressive hardware alarms from system notifications to
  respect user preferences while ensuring they don't miss their clock-out:
   * The Alarm Toggle: This specifically controls the loud, hardware-level
     alarm/ringing.
   * Continuous Notifications: System notifications (which always wake the
     device screen) are always scheduled, regardless of the alarm toggle.
       * If the toggle is ON, the notification is paired with a loud hardware
         alarm.
       * If the toggle is OFF, the app delivers a "silent" notification that
         wakes the screen and shows the message, allowing the user to work in
         peace while still being reminded.
   * "Stop the Alarm": If a loud alarm is ringing, the user can hit "Stop the
     Alarm". This silences the current ringing immediately but keeps the user
     clocked in, and the countdown to the next repeating alert continues
     undisturbed.

  4. Background Resilience
   * Self-Sustaining Loop: The notification system uses background isolates (via
     awesome_notifications). When an alert is dismissed while the app is killed,
     the notification reads its own payload (which contains the user's
     alarmDelayMinutes and sound preferences) and automatically schedules the
     next repeat in the background. This guarantees the infinite loop survives
     app restarts or crashes.
   * State Persistence: The active session and the current state of the alarm
     toggle are saved to the local SQLite database. If the app is closed and
     reopened, it seamlessly resumes the countdown and resyncs the hardware
     alarms to match the background notifications.