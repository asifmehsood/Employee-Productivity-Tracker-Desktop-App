# Idle Time Tracking with Timer Extension - Test Instructions

## How It Works

When you schedule a task for 2 minutes (13:25 to 13:27) and go idle for 1 minute:
- **Timer pauses** - stops counting toward 13:27
- **Auto-stop is cancelled** - task won't stop at 13:27
- When you return, **end time extends to 13:28** (original + 1 min idle)
- **You still get 2 full minutes** to work on your task

## Quick Test (3-5 minutes)

### Test Steps

1. **Create a task with 2-minute duration**
   - Start time: 2 minutes from now (e.g., 13:25)
   - End time: 2 minutes after start (e.g., 13:27)
   - Example: If current time is 13:23, set start=13:25, end=13:27

2. **Wait for task to auto-start**
   - Console shows: "=== STARTING IDLE MONITORING ==="
   - Console shows: "Scheduled end time: 13:27:00"
   - Status: "ACTIVE TASK" (green)

3. **Go idle immediately** (don't touch keyboard/mouse for 1+ minute)
   - After 1 minute idle, you'll see:
     ```
     >>> USER BECAME IDLE <<<
     Idle start time recorded: 13:25:30
     Auto-stop timer cancelled due to idle
     ```
   - Orange notification: "You've been idle for 1 minute. Timer paused automatically."
   - Status: "PAUSED (IDLE)" (orange)

4. **Original end time passes (13:27) while you're still idle**
   - **Nothing happens** ✅
   - Task remains paused
   - Auto-stop doesn't trigger (was cancelled)

5. **Return and move mouse** (e.g., at 13:27:30 - after 2 minutes idle)
   - Console shows:
     ```
     >>> USER BECAME ACTIVE <<<
     Idle duration: 120 seconds (120000 ms)
     
     === EXTENDING SCHEDULED END TIME ===
     Previous end time: 13:27:00
     Idle duration: 120s
     New end time: 13:29:00
     === END TIME EXTENDED ===
     
     === SCHEDULING AUTO-STOP ===
     Scheduled end time: 13:29:00
     Duration until stop: 1 minutes 30 seconds
     ```
   - Green notification: "Welcome back! Timer resumed."
   - Status: "ACTIVE TASK" (green)
   - **You now have until 13:29** to complete your 2-minute task

6. **Task auto-completes at new end time (13:29)**
   - Console shows: "=== AUTO-STOP TRIGGERED ===" at 13:29:00
   - Task stops at the extended time

7. **Check Dashboard**
   - Navigate to Dashboard
   - Look at task duration
   - **Expected**: Should show **2:00** (2 minutes of actual work)
   - Total elapsed: 13:25 to 13:29 = 4 minutes
   - Idle time: 2 minutes
   - Work time: 4 - 2 = 2 minutes ✅

## What to Look For

### ✅ Success Indicators

**Console Output:**
```
>>> USER BECAME IDLE <<<
Idle start time recorded: 13:25:30.123456
Auto-stop timer cancelled due to idle

>>> USER BECAME ACTIVE <<<
Idle duration: 120 seconds (120000 ms)

=== EXTENDING SCHEDULED END TIME ===
Previous end time: 13:27:00
Idle duration: 120s
New end time: 13:29:00
=== END TIME EXTENDED ===

=== SCHEDULING AUTO-STOP ===
Scheduled end time: 13:29:00
Duration until stop: 1 minutes 30 seconds
```

**UI Indicators:**
- ✅ Orange notification when idle
- ✅ "Auto-stop timer cancelled" message when idle
- ✅ Green notification when active
- ✅ "New end time" message shows extended time
- ✅ Status shows "PAUSED (IDLE)" when idle
- ✅ Task doesn't stop at original end time
- ✅ Task stops at new extended end time
- ✅ Dashboard duration shows only work time (excludes idle)

## Troubleshooting

**If idle detection doesn't trigger:**
- Make sure you don't move the mouse or touch keyboard for full 60+ seconds
- Check console for ">>> USER BECAME IDLE <<<" message

**If duration is not updated:**
- Check console for "=== ADDING IDLE DURATION TO TASK ===" message
- Verify "New total paused duration" is greater than "Previous total paused duration"

**If dashboard still shows full time:**
- Refresh the dashboard (navigate away and back)
- Check the `totalPausedDuration` value in the database

## Expected Final Result

### Example Timeline
- **Task scheduled**: 13:25 to 13:27 (2 minutes)
- **Task started**: 13:25:00
- **User went idle**: 13:25:30 (30 seconds of work)
- **User returned**: 13:27:30 (2 minutes idle)
- **New end time**: 13:29:30 (original 13:27 + 2 min idle)
- **User worked**: 13:27:30 to 13:29:30 (2 more minutes)
- **Task completed**: 13:29:30

### Final Calculations
- **Total elapsed time**: 13:25 to 13:29:30 = 4.5 minutes
- **Idle time**: 2 minutes (recorded in totalPausedDuration)
- **Active work time**: 4.5 - 2 = 2.5 minutes
- **Dashboard displays**: 2:30 (2 minutes 30 seconds)

### Key Verification Points
1. ✅ **Timer stops** when idle (doesn't count toward end time)
2. ✅ **Original end time passes** without task stopping (13:27 → nothing)
3. ✅ **End time extends** by idle duration (13:27 → 13:29:30)
4. ✅ **User gets full scheduled duration** (2 minutes of work)
5. ✅ **Dashboard shows accurate work time** (excludes idle)

✅ **Success**: Task extends its end time when you go idle, ensuring you get the full scheduled work duration!
