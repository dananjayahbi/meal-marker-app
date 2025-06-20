# Meal Reminder Mobile App – Development Instructions & Planning

## Overview
This document provides a detailed plan and step-by-step instructions for building a robust Meal Reminder mobile app using Flutter in VS Code. The app will allow users to create, manage, and receive notifications for meal reminders, supporting both one-time and recurring reminders. The instructions are tailored for GitHub Copilot or similar AI agents to execute efficiently.

---

## 1. Project Setup
- **Base Template:** Start from the default Flutter counter app (already generated).

---

## 2. Core Features & Requirements
### 2.1. Reminder CRUD
- **Create:** Users can add new meal reminders (title, description, time, type: one-time or recurring, period for recurring).
- **Read:** List all reminders with details and next trigger time.
- **Update:** Edit any reminder’s details.
- **Delete:** Remove reminders.

### 2.2. Recurring Reminders
- Allow users to set reminders that repeat at custom intervals (e.g., every 3 hours, daily, etc.).
- Store recurrence rules in a structured format.

### 2.3. Notifications
- When a reminder is triggered, push a notification to the device’s notification panel.
- Use a specific vibration pattern for meal notifications.
- Ensure notifications work in the background and after device restarts (use appropriate plugins).

### 2.4. Additional Smart Features (Recommended)
- **Snooze:** Allow users to snooze a reminder for a custom duration.
- **History:** Track and display a log of past reminders and user actions (e.g., dismissed, snoozed).
- **Statistics:** Show stats (e.g., average meals per day, most skipped meal, etc.).

---

## 3. Technical Planning
### 3.1. Packages & Plugins
- `flutter_local_notifications` – For scheduling and displaying notifications.
- `vibration` – For custom vibration patterns.
- `shared_preferences` or `hive` – For local data storage.
- `provider` or `riverpod` – For state management.
- (Optional) `intl` – For date/time formatting.

### 3.2. Data Model
- Define a `MealReminder` class with fields:
  - id (unique)
  - title
  - description
  - time (DateTime)
  - isRecurring (bool)
  - period (Duration or custom string)
  - vibrationPattern (List<int>)
  - status (active, snoozed, dismissed)
  - createdAt, updatedAt

### 3.3. App Structure
- **Screens:**
  - Home/List of Reminders
  - Add/Edit Reminder
  - Reminder Details
  - History/Statistics
- **State Management:**
  - Use Provider/Riverpod for managing reminders and app state.
- **Notification Service:**
  - Encapsulate notification logic in a dedicated service class.

---

## 4. Implementation Steps
### 4.1. Initial Setup
- Clean up the counter app template.
- Add required dependencies to `pubspec.yaml`.
- Set up folder structure: `/models`, `/services`, `/screens`, `/widgets`, `/utils`.

### 4.2. Data Layer
- Implement `MealReminder` model.
- Set up local storage (Hive or SharedPreferences).
- Implement CRUD operations for reminders.

### 4.3. UI Layer
- Build screens for listing, adding, editing, and viewing reminders.
- Add forms for inputting reminder details.
- Implement history/statistics and settings screens.

### 4.4. Notification & Vibration
- Integrate `flutter_local_notifications` for scheduling notifications.
- Integrate `vibration` for custom patterns.
- Ensure notifications trigger even when the app is closed.
- Handle notification tap actions (e.g., mark as done, snooze).

### 4.5. Recurring Logic
- Implement logic for recurring reminders and rescheduling.
- Allow flexible period input (hours, days, custom intervals).

### 4.6. Additional Features
- Implement snooze, history, statistics.

---

## 5. Best Practices & Notes
- Write clean, modular, and well-documented code.
- Use async/await for all I/O operations.
- Handle permissions for notifications and vibration.
- Ensure accessibility and responsive design.

## 7. References
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Vibration Plugin](https://pub.dev/packages/vibration)
- [Hive Database](https://pub.dev/packages/hive)
- [Provider](https://pub.dev/packages/provider)

---

**End of Instructions**
