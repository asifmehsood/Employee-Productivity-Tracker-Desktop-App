/// Home Screen
/// Main dashboard showing active task, timer, and quick actions
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../core/utils/date_time_helper.dart';
import '../core/constants/app_constants.dart';
import 'task_detail_screen.dart';
import 'common/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Setup notification callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.onShowNotification = (message, {bool isWarning = false}) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isWarning ? Icons.warning_amber : Icons.check_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(message)),
                ],
              ),
              backgroundColor: isWarning
                  ? Colors.orange[700]
                  : const Color(0xFF1c4d2c),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Work Session',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0d0d0d),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0d0d0d),
                const Color(0xFF1c4d2c).withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(currentPage: DrawerPage.taskCreation),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF1a1a1a), Color(0xFF0d0d0d)],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1c4d2c).withOpacity(0.05),
                Colors.transparent,
                const Color(0xFF1c4d2c).withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Consumer2<TaskProvider, AuthProvider>(
            builder: (context, taskProvider, authProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Task Section
                    taskProvider.hasActiveTask
                        ? _buildActiveTaskSection(taskProvider)
                        : _buildNoActiveTaskSection(context, authProvider),

                    // Statistics
                    const SizedBox(height: 24),
                    _buildStatistics(taskProvider),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTaskSection(TaskProvider taskProvider) {
    final task = taskProvider.activeTask!;
    final timerService = taskProvider.timerService;
    final now = DateTime.now();

    // Determine status label and color based on actual task status
    String statusLabel;
    Color statusColor;

    if (task.status == AppConstants.taskStatusPaused) {
      statusLabel = 'PAUSED TASK';
      statusColor = Colors.orange[700]!;
    } else if (taskProvider.isIdlePaused) {
      statusLabel = 'PAUSED (IDLE)';
      statusColor = Colors.orange[700]!;
    } else if (task.startTime.isAfter(now)) {
      statusLabel = 'SCHEDULED TASK';
      statusColor = Colors.blue;
    } else {
      statusLabel = 'ACTIVE TASK';
      statusColor = Colors.green;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              task.taskName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (task.taskDescription.isNotEmpty)
              Text(
                task.taskDescription,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // Timer Display
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                // Force rebuild by accessing the provider
                final taskProvider = context.watch<TaskProvider>();
                final currentTask = taskProvider.activeTask;
                if (currentTask == null) {
                  return const Text('No active task');
                }
                // Pass idlePausedAt to getDuration so timer stops during idle
                final duration = currentTask.getDuration(
                  idlePausedAt: taskProvider.idlePausedAt,
                );
                final totalHours = duration.inHours;
                final minutes = duration.inMinutes.remainder(60);
                final seconds = duration.inSeconds.remainder(60);
                final formattedTime =
                    '${totalHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                // Real-time console logging every 10 seconds
                if (seconds % 10 == 0) {
                  print(
                    '╔═══════════════════════════════════════════════════════════════╗',
                  );
                  print(
                    '║ TIMER UPDATE - ${DateTime.now().toString().substring(11, 19)}                                     ║',
                  );
                  print(
                    '╠═══════════════════════════════════════════════════════════════╣',
                  );
                  print('║ Task: ${currentTask.taskName.padRight(54)}║');
                  print(
                    '║ Status: ${currentTask.status.toUpperCase().padRight(52)}║',
                  );
                  print(
                    '║ Timer Display: $formattedTime                                      ║',
                  );
                  print(
                    '║                                                               ║',
                  );
                  print(
                    '║ Timing Details:                                               ║',
                  );
                  print(
                    '║   Start Time: ${currentTask.startTime.toString().substring(11, 19).padRight(44)}║',
                  );
                  if (currentTask.scheduledEndTime != null) {
                    print(
                      '║   Scheduled End: ${currentTask.scheduledEndTime.toString().substring(11, 19).padRight(41)}║',
                    );
                  }
                  print(
                    '║   Current Time: ${DateTime.now().toString().substring(11, 19).padRight(42)}║',
                  );
                  print(
                    '${'║   Raw Duration: ${duration.inSeconds}s (${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s)'
                            .padRight(64)}║',
                  );
                  print(
                    '║                                                               ║',
                  );
                  print(
                    '║ Pause Info:                                                   ║',
                  );
                  print(
                    '${'║   Total Paused: ${currentTask.totalPausedDuration}ms (${(currentTask.totalPausedDuration / 1000).toStringAsFixed(1)}s)'
                            .padRight(64)}║',
                  );
                  if (taskProvider.isIdlePaused) {
                    print(
                      '║   ⚠️  IDLE PAUSED: YES                                          ║',
                    );
                    if (taskProvider.idlePausedAt != null) {
                      final idleDuration = DateTime.now().difference(
                        taskProvider.idlePausedAt!,
                      );
                      print(
                        '║   Idle Since: ${taskProvider.idlePausedAt.toString().substring(11, 19).padRight(45)}║',
                      );
                      print(
                        '${'║   Idle Duration: ${idleDuration.inSeconds}s'
                                .padRight(64)}║',
                      );
                    }
                  } else {
                    print(
                      '║   Idle Paused: NO                                             ║',
                    );
                  }
                  if (currentTask.isPaused && currentTask.pausedAt != null) {
                    print(
                      '║   ⏸️  MANUALLY PAUSED at ${currentTask.pausedAt.toString().substring(11, 19).padRight(27)}║',
                    );
                  }
                  print(
                    '╚═══════════════════════════════════════════════════════════════╝\n',
                  );
                }

                return Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),

            const SizedBox(height: 8),
            Text(
              task.startTime.isAfter(now)
                  ? 'Will start: ${DateTimeHelper.formatDateTime(task.startTime)}'
                  : 'Started: ${DateTimeHelper.formatDateTime(task.startTime)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Screenshot Info
            if (timerService.isRunning)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d7a47).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3fd884).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Color(0xFF3fd884),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Screenshot Capture Active',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3fd884),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Interval: ${timerService.intervalMinutes} minutes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Show Pause button when task is active and has started
                if (task.status == AppConstants.taskStatusActive &&
                    !task.startTime.isAfter(now))
                  _PauseButton(
                    onPressed: () async {
                      await _pauseTask(taskProvider, task.id);
                    },
                  ),
                // Show Resume (Play) button when task is paused
                if (task.status == AppConstants.taskStatusPaused &&
                    !task.startTime.isAfter(now))
                  _PlayButton(
                    onPressed: () async {
                      await _resumeTask(taskProvider, task.id);
                    },
                  ),
                // Show Stop & Complete button when task has started
                if (!task.startTime.isAfter(now)) ...[
                  const SizedBox(width: 24),
                  _StopButton(
                    onPressed: () async {
                      await _stopTask(taskProvider, task.id);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveTaskSection(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a1a1a),
              const Color(0xFF0d0d0d),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer Display (00:00:00)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1c4d2c).withOpacity(0.3),
                      const Color(0xFF2d7a47).withOpacity(0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1c4d2c).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  size: 80,
                  color: Color(0xFF3fd884),
                ),
              ),
              const SizedBox(height: 32),
              
              // Timer Text
              const Text(
                '00:00:00',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ready to track your work',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Play Button
              _PlayButton(
                onPressed: () => _startWorkSession(context, authProvider),
              ),
              
              const SizedBox(height: 24),
              
              // Info Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InfoChip(
                    icon: Icons.camera_alt,
                    text: 'Auto Screenshot',
                    color: const Color(0xFF3fd884),
                  ),
                  const SizedBox(width: 16),
                  _InfoChip(
                    icon: Icons.track_changes,
                    text: 'Activity Tracking',
                    color: const Color(0xFF5ba3ff),
                  ),
                  const SizedBox(width: 16),
                  _InfoChip(
                    icon: Icons.analytics_outlined,
                    text: 'Analytics',
                    color: const Color(0xFFffa726),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics(TaskProvider taskProvider) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        // Watch for real-time updates
        final provider = context.watch<TaskProvider>();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1a1a1a), const Color(0xFF0d0d0d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1c4d2c).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1c4d2c).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Tasks',
                provider.tasks.length.toString(),
                Icons.format_list_bulleted_rounded,
                color: const Color(0xFF6dd4a8),
                bgColor: const Color(0xFF1c4d2c).withOpacity(0.2),
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                'Active',
                provider.runningTasks.length.toString(),
                Icons.play_circle_outline_rounded,
                color: const Color(0xFF3fd884),
                bgColor: const Color(0xFF3fd884).withOpacity(0.2),
              ),
              _buildVerticalDivider(),
              _buildStatItem(
                'Completed',
                provider.completedTasks.length.toString(),
                Icons.check_circle_outline_rounded,
                color: const Color(0xFF5ba3ff),
                bgColor: const Color(0xFF5ba3ff).withOpacity(0.2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 50,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF1c4d2c).withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: _StatCard(
        label: label,
        value: value,
        icon: icon,
        color: color,
        bgColor: bgColor,
      ),
    );
  }

  Future<void> _startWorkSession(BuildContext context, AuthProvider authProvider) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    final now = DateTime.now();
    final endTime = now.add(const Duration(hours: 8)); // Default 8 hour work session

    final task = await taskProvider.startNewTask(
      employeeId: authProvider.employeeId,
      employeeName: authProvider.employeeName,
      taskName: 'Work Session ${DateTimeHelper.formatDate(now)}',
      taskDescription: 'Productivity tracking session',
      scheduledStartTime: now,
      scheduledEndTime: endTime,
    );

    if (task != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Work session started! Tracking in progress...'),
            ],
          ),
          backgroundColor: const Color(0xFF1c4d2c),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pauseTask(TaskProvider taskProvider, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Task'),
        content: const Text('Are you sure you want to pause this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pause'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await taskProvider.pauseTask(taskId);
    }
  }

  Future<void> _resumeTask(TaskProvider taskProvider, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Task'),
        content: const Text('Are you sure you want to resume this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await taskProvider.resumeTask(taskId);
      if (!success && context.mounted) {
        // Show message if resume was blocked (stop time reached)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Task has reached its scheduled end time and has been completed.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _stopTask(TaskProvider taskProvider, String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Task'),
        content: const Text(
          'Are you sure you want to stop and complete this task?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await taskProvider.stopTask(taskId);
    }
  }
}

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: _isHovered ? widget.bgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.3),
                      widget.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0, end: double.parse(widget.value)),
                builder: (context, value, child) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                      height: 1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Start Session Button Widget
class _StartSessionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _StartSessionButton({required this.onPressed});

  @override
  State<_StartSessionButton> createState() => _StartSessionButtonState();
}

class _StartSessionButtonState extends State<_StartSessionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 70,
          constraints: const BoxConstraints(minWidth: 300),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1c4d2c).withOpacity(_isHovered ? 0.6 : 0.4),
                blurRadius: _isHovered ? 30 : 20,
                spreadRadius: _isHovered ? 4 : 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Start Work Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Info Chip Widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Play Button Widget
class _PlayButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PlayButton({required this.onPressed});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1c4d2c).withOpacity(_isHovered ? 0.8 : 0.5),
                  blurRadius: _isHovered ? 35 : 25,
                  spreadRadius: _isHovered ? 6 : 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}

// Pause Button Widget
class _PauseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PauseButton({required this.onPressed});

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.orange[700]!, Colors.orange[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(_isHovered ? 0.4 : 0.5),
                  blurRadius: _isHovered ? 35 : 25,
                  spreadRadius: _isHovered ? 6 : 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.pause_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}

// Stop Button Widget
class _StopButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _StopButton({required this.onPressed});

  @override
  State<_StopButton> createState() => _StopButtonState();
}

class _StopButtonState extends State<_StopButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(_isHovered ? 0.4 : 0.5),
                  blurRadius: _isHovered ? 35 : 25,
                  spreadRadius: _isHovered ? 6 : 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}
