# Idle Detection Feature with Timer Extension

## Overview
The idle detection feature automatically pauses the timer when the user is inactive for 1 minute. **When the user returns, the scheduled end time is automatically extended by the idle duration**, ensuring the user gets the full scheduled work time. Idle time is also subtracted from the total task duration for accurate reporting.

## Key Features

### 1. **Timer Pause on Idle**
When the user is idle for 1 minute:
- Timer stops counting toward the end time
- Window tracking stops
- Auto-stop timer is cancelled
- UI shows "PAUSED (IDLE)" status

### 2. **Scheduled End Time Extension**
When the user returns:
- Idle duration is calculated (e.g., 5 minutes)
- **Scheduled end time is extended** by the idle duration
- New end time = Original end time + Idle duration
- Auto-stop timer is rescheduled with the new end time
- User gets the full scheduled work duration

### 3. **Accurate Duration Tracking**
- Idle time is added to `totalPausedDuration`
- Task duration automatically excludes idle time
- Dashboard shows only active work time

## How It Works

### 1. Idle Detection Service (`lib/core/services/idle_detector_service.dart`)
- **Technology**: Uses Windows API `GetLastInputInfo()` to detect keyboard and mouse activity
- **Check Interval**: Monitors activity every 5 seconds
- **Idle Threshold**: 1 minute (60 seconds) of inactivity triggers pause
- **Active Threshold**: 2 seconds of activity resumes the timer

### 2. Timer Service Integration (`lib/core/services/timer_service.dart`)
- Starts idle monitoring when task timer starts
- **Records idle start time** when user goes idle
- **Calculates idle duration** when user becomes active
- Pauses window tracking during idle periods
- Resumes window tracking when user becomes active
- **Notifies TaskProvider with idle duration** for database update

### 3. Task Provider Updates (`lib/providers/task_provider.dart`)
- **Receives idle duration from TimerService**
- **Automatically adds idle time to `totalPausedDuration`**
- Updates task in database with new paused duration
- Ensures accurate time tracking without manual intervention

### 4. User Notifications
- **Idle Alert**: Shows orange warning notification when timer pauses due to inactivity
  - Message: "You've been idle for 1 minute. Timer paused automatically."
- **Resume Alert**: Shows green success notification when timer resumes
  - Message: "Welcome back! Timer resumed."

### 5. UI Status Updates
The active task card shows different status labels:
- `ACTIVE TASK` (green) - Normal working state
- `PAUSED (IDLE)` (orange) - Automatically paused due to inactivity
- `PAUSED TASK` (orange) - Manually paused by user
- `SCHEDULED TASK` (blue) - Task scheduled for future start

## Technical Implementation

### Idle Duration Tracking Flow

```dart
// 1. User goes idle
_handleIdle() {
  _idleStartTime = DateTime.now();  // Record when idle started
  _windowTracker.stopTracking();    // Stop window tracking
  onIdleStateChanged?.call(true);   // Notify UI
}

// 2. User becomes active
_handleActive() {
  // Calculate how long user was idle
  idleDuration = DateTime.now() - _idleStartTime;
  idleDurationMs = idleDuration.inMilliseconds;
  
  // Notify TaskProvider to update task duration
  onIdleDurationCalculated?.call(idleDurationMs);
  
  _windowTracker.startTracking();   // Resume window tracking
  onIdleStateChanged?.call(false);  // Notify UI
}

// 3. TaskProvider adds idle time to totalPausedDuration
_addIdleDurationToTask(taskId, idleDurationMs) {
  task.totalPausedDuration += idleDurationMs;
  await _db.updateTask(task);  // Save to database
}
```

### Duration Calculation in TaskModel

The task's `duration` getter automatically subtracts `totalPausedDuration`:

```dart
Duration get duration {
  var calculatedDuration = endTime.difference(startTime);
  
  // Subtract all paused time (includes idle time)
  calculatedDuration = calculatedDuration - Duration(milliseconds: totalPausedDuration);
  
  // If currently paused, exclude current pause time too
  if (isPaused && pausedAt != null) {
    calculatedDuration = calculatedDuration - DateTime.now().difference(pausedAt!);
  }
  
  return calculatedDuration;
}
```

### Windows API Integration
```dart
// Get last input time from Windows
final lastInputInfo = calloc<LASTINPUTINFO>();
GetLastInputInfo(lastInputInfo);

// Calculate idle time
final currentTime = GetTickCount();
final idleMilliseconds = currentTime - lastInputInfo.ref.dwTime;
```

### Callback Architecture
The service uses callbacks to communicate state changes:
```dart
// In TaskProvider.initialize()
_timerService.onIdleStateChanged = (isIdle) {
  // Update UI state and show notifications
};

_timerService.onIdleDurationCalculated = (idleDurationMs) {
  // Add idle duration to task's totalPausedDuration
  await _addIdleDurationToTask(_activeTask!.id, idleDurationMs);
};
```

### Window Tracking Behavior
- **Active**: Window tracking runs every 5 seconds, recording app usage
- **Idle**: Window tracking stops, no app usage data is recorded
- **Resume**: Window tracking restarts automatically

## User Experience Flow - Complete Example

### Scenario: 2-minute scheduled task with 1-minute idle period

**Setup:**
- Task scheduled from **13:25 to 13:27** (2 minutes)
- User goes idle at **13:26** (1 minute into the task)
- User returns at **13:27** (was idle for 1 minute)

**What Happens:**

1. **Task Starts (13:25:00)**
   - Timer begins
   - Window tracking starts
   - Idle monitoring starts
   - Auto-stop scheduled for: **13:27:00**
   - Status: "ACTIVE TASK" (green)

2. **User Goes Idle (13:26:00)**
   ```
   >>> USER BECAME IDLE <<<
   Idle start time recorded: 13:26:00
   Auto-stop timer cancelled due to idle
   ```
   - Timer **stops counting**
   - Window tracking stops
   - Auto-stop timer **cancelled**
   - Orange notification: "You've been idle for 1 minute. Timer paused automatically."
   - Status: "PAUSED (IDLE)" (orange)

3. **Original End Time Passes (13:27:00)**
   - **Nothing happens** - auto-stop timer was cancelled
   - Timer remains paused
   - User is still idle

4. **User Returns (13:27:10) - After 1 minute 10 seconds of idle**
   ```
   >>> USER BECAME ACTIVE <<<
   Idle duration: 70 seconds (70000 ms)
   
   === ADDING IDLE DURATION TO TASK ===
   Previous total paused duration: 0ms
   New total paused duration: 70000ms
   
   === EXTENDING SCHEDULED END TIME ===
   Previous end time: 13:27:00
   Idle duration: 70s
   New end time: 13:28:10
   === END TIME EXTENDED ===
   
   === SCHEDULING AUTO-STOP ===
   Scheduled end time: 13:28:10
   Duration until stop: 1 minutes 0 seconds
   ```
   - Idle duration calculated: **1 minute 10 seconds**
   - Scheduled end time extended: **13:27:00 + 1:10 = 13:28:10**
   - Auto-stop rescheduled for: **13:28:10**
   - Timer resumes
   - Window tracking resumes
   - Green notification: "Welcome back! Timer resumed."
   - Status: "ACTIVE TASK" (green)

5. **User Works Until New End Time (13:28:10)**
   - User has **1 minute** to complete their work
   - Timer counts from 13:27:10 to 13:28:10

6. **Task Auto-Completes (13:28:10)**
   ```
   === AUTO-STOP TRIGGERED ===
   Task stopped successfully
   ```
   - Task stops at the extended end time
   - Total time: **13:25:00 to 13:28:10 = 3 minutes 10 seconds**
   - Idle time: **1 minute 10 seconds**
   - **Actual work time**: **3:10 - 1:10 = 2 minutes** ✅
   - Dashboard shows: **2:00** (the scheduled duration)

### Summary
- **Scheduled duration**: 2 minutes
- **User went idle**: 1 minute 10 seconds
- **End time extended by**: 1 minute 10 seconds
- **User got to work**: Full 2 minutes (as scheduled)
- **Dashboard shows**: 2 minutes (accurate work time)

## Benefits

1. **True Time Extension**: Timer actually stops and extends the end time, not just subtracts later
2. **Full Scheduled Duration**: User always gets the full scheduled work time, regardless of idle periods
3. **Accurate Time Tracking**: Dashboard shows actual work time, excluding idle periods
4. **Automatic Operation**: No manual adjustments needed
5. **Transparent**: Clear console logs show all time calculations
6. **Reliable**: Uses native Windows API for precise activity detection
7. **Fair Tracking**: Lunch breaks, meetings, and interruptions don't reduce work time
8. **Flexible**: Handles multiple idle periods with cumulative extensions

## Database Schema

The `tasks` table includes:
```sql
totalPausedDuration INTEGER DEFAULT 0  -- Stores cumulative idle time in milliseconds
pausedAt INTEGER                       -- Timestamp when manually paused (or NULL)
```

All idle time periods are automatically accumulated in `totalPausedDuration`.

## Configuration

Current settings (can be modified in `idle_detector_service.dart`):
- **Idle Threshold**: 60 seconds (1 minute)
- **Check Interval**: 5 seconds
- **Resume Threshold**: 2 seconds of activity

## Testing

To test the idle detection and duration tracking feature:

1. **Start a new task** from the home screen at `13:00:00`
2. **Wait 1 minute** without touching keyboard or mouse
3. **Observe**:
   - Orange notification: "You've been idle for 1 minute. Timer paused automatically."
   - Status changes to "PAUSED (IDLE)"
   - Console shows: `Idle start time recorded: 13:01:00`
4. **Wait another 2 minutes** (total 3 minutes idle)
5. **Move the mouse** at `13:04:00`
6. **Observe**:
   - Green notification: "Welcome back! Timer resumed."
   - Status changes to "ACTIVE TASK"
   - Console shows:
     ```
     Idle duration: 180 seconds (180000 ms)
     === ADDING IDLE DURATION TO TASK ===
     Previous total paused duration: 0ms
     New total paused duration: 180000ms
     ```
7. **Work for 5 minutes**, then **stop the task** at `13:09:00`
8. **Check the dashboard**:
   - Total elapsed time: `13:09:00 - 13:00:00 = 9 minutes`
   - Idle time: `3 minutes = 180,000ms`
   - **Displayed duration**: `6 minutes` (9 - 3 = 6 minutes of actual work)

## Console Output Example

```
=== STARTING IDLE MONITORING ===
Idle monitoring started (threshold: 60s)

>>> USER BECAME IDLE <<<
Idle for: 64s (threshold: 60s)
User went idle - pausing timer and window tracking
Idle start time recorded: 2025-12-01 13:17:30.123456

>>> USER BECAME ACTIVE <<<
Idle duration was: 125s
User is active again - resuming timer and window tracking
Idle duration: 125 seconds (125000 ms)

=== ADDING IDLE DURATION TO TASK ===
Task ID: abc-123
Idle Duration: 125000ms (125.0s)
Previous total paused duration: 0ms
New total paused duration: 125000ms
Task updated in database with new paused duration
=== IDLE DURATION ADDED ===
```

## Files Modified

1. **lib/core/services/idle_detector_service.dart** (NEW)
   - Complete idle detection service using Windows API

2. **lib/core/services/timer_service.dart**
   - Added IdleDetectorService integration
   - Added `_isPausedDueToIdle` state
   - Added `_idleStartTime` to track when idle period began
   - Added `onIdleStateChanged` callback
   - Added `onIdleDurationCalculated` callback for duration updates
   - Implemented `_handleIdle()` to record idle start time
   - Implemented `_handleActive()` to calculate and report idle duration
   - Added `getCurrentIdleDuration()` method

3. **lib/providers/task_provider.dart**
   - Added `_isIdlePaused` state
   - Added `onShowNotification` callback for UI notifications
   - Setup idle state change listener in `initialize()`
   - **Added `_addIdleDurationToTask()` method** to update database with idle time
   - Setup idle duration calculator callback to receive idle durations

4. **lib/screens/home_screen.dart**
   - Added notification callback setup in `initState()`
   - Updated status label to show "PAUSED (IDLE)"
   - Shows SnackBar notifications for idle state changes

5. **lib/models/task_model.dart** (EXISTING)
   - `duration` getter automatically subtracts `totalPausedDuration`
   - Includes both manual pause time and automatic idle time

## Future Enhancements

Potential improvements:
- Configurable idle threshold in settings
- Warning notification at 45 seconds (before auto-pause)
- Separate tracking of idle time vs manual pause time in UI
- Option to disable auto-pause for certain task types
- Desktop notification support (Windows native notifications)
- Idle time statistics in reports
- Export idle time data with task reports
