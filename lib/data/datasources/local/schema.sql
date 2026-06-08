-- Database Schema for ClockOut
-- This file contains the table definitions for the app's SQLite database.

CREATE TABLE IF NOT EXISTS Logs (
    log_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    date_added TEXT NOT NULL,
    bonus_time TEXT DEFAULT ('0') NOT NULL,
    user_edited NUMERIC DEFAULT (0) NOT NULL,
    clocked_in_time TEXT,
    clocked_out_time INTEGER,
    online_work INTEGER DEFAULT (0)
);

CREATE TABLE IF NOT EXISTS UserSettings (
    settings_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    accent_color TEXT,
    clock_format TEXT,
    time_delay INTEGER DEFAULT (30) NOT NULL
);
