/// Dashboard Screen
/// Shows comprehensive productivity analytics and statistics
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../core/utils/date_time_helper.dart';
import '../core/services/database_helper.dart';
import 'dart:math' as math;
import 'common/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'Day'; // Day, Week, Month, Year
  List<Map<String, dynamic>> _appUsageData = [];

  @override
  void initState() {
    super.initState();
    _loadAppUsageData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload app usage data when dependencies change (e.g., task completed)
    _loadAppUsageData();
  }

  Future<void> _loadAppUsageData() async {
    try {
      final data = await DatabaseHelper.instance.getRecentAppUsage(limit: 10);
      if (mounted) {
        setState(() {
          _appUsageData = data;
        });
      }
    } catch (e) {
      print('Error loading app usage data: $e');
      if (mounted) {
        setState(() {
          _appUsageData = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentPage: DrawerPage.dashboard),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0d0d0d),
            ],
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
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date Header and Period Filter
                    _buildDateHeader(),
                    const SizedBox(height: 16),
                    _buildPeriodFilter(),
                    const SizedBox(height: 24),

                    // Top Row: Work Hours, Percent Target, Focus Percent, Daily Summary
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Work Hours & Timeline)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildWorkHoursCard(taskProvider),
                                  const SizedBox(height: 24),
                                  _buildTimelineCard(taskProvider),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            
                            // Right Column (Daily Summary & Quick Insights)
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildDailySummaryCard(taskProvider),
                                  const SizedBox(height: 24),
                                  _buildQuickInsightsCard(taskProvider),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    // Bottom Row: Categories, Apps & Websites, Tasks
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCategoriesCard(taskProvider)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildAppsWebsitesCard(taskProvider)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildTasksCard(taskProvider)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper method to get filtered tasks based on selected period
  List<dynamic> _getFilteredTasks(TaskProvider taskProvider) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Day':
        // Check if there are tasks for today
        final todayTasks = taskProvider.tasks.where((task) {
          if (task.scheduledStartTime == null) return false;
          final taskDate = task.scheduledStartTime!;
          return taskDate.year == now.year &&
                 taskDate.month == now.month &&
                 taskDate.day == now.day;
        }).toList();
        
        // If no tasks today, get previous day's tasks
        if (todayTasks.isEmpty) {
          final yesterday = now.subtract(const Duration(days: 1));
          return taskProvider.tasks.where((task) {
            if (task.scheduledStartTime == null) return false;
            final taskDate = task.scheduledStartTime!;
            return taskDate.year == yesterday.year &&
                   taskDate.month == yesterday.month &&
                   taskDate.day == yesterday.day;
          }).toList();
        }
        return todayTasks;
        
      case 'Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return taskProvider.tasks.where((task) {
          if (task.scheduledStartTime == null) return false;
          final taskDate = task.scheduledStartTime!;
          return taskDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 taskDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        
      case 'Month':
        return taskProvider.tasks.where((task) {
          if (task.scheduledStartTime == null) return false;
          final taskDate = task.scheduledStartTime!;
          return taskDate.year == now.year && taskDate.month == now.month;
        }).toList();
        
      case 'Year':
        return taskProvider.tasks.where((task) {
          if (task.scheduledStartTime == null) return false;
          final taskDate = task.scheduledStartTime!;
          return taskDate.year == now.year;
        }).toList();
        
      default:
        return taskProvider.tasks;
    }
  }

  // Helper method to get target hours based on period
  double _getTargetHours() {
    switch (_selectedPeriod) {
      case 'Day':
        return 8.0;
      case 'Week':
        return 40.0; // 5 days * 8 hours
      case 'Month':
        return 160.0; // ~20 working days * 8 hours
      case 'Year':
        return 2080.0; // 52 weeks * 40 hours
      default:
        return 8.0;
    }
  }

  // Helper method to categorize application names
  String _categorizeApp(String appName) {
    final appLower = appName.toLowerCase();
    
    // Productive - Development & Work Tools
    if (appLower.contains('vs code') || appLower.contains('visual studio') ||
        appLower.contains('pycharm') || appLower.contains('intellij') ||
        appLower.contains('android studio') || appLower.contains('eclipse') ||
        appLower.contains('xcode') || appLower.contains('sublime') ||
        appLower.contains('github') || appLower.contains('gitlab') ||
        appLower.contains('stack overflow') || appLower.contains('stackoverflow')) {
      return 'Development';
    }
    
    // Productive - Documentation & Office
    if (appLower.contains('word') || appLower.contains('excel') ||
        appLower.contains('powerpoint') || appLower.contains('outlook') ||
        appLower.contains('notion') || appLower.contains('evernote') ||
        appLower.contains('onenote') || appLower.contains('google docs') ||
        appLower.contains('sheets') || appLower.contains('slides')) {
      return 'Productivity';
    }
    
    // Design Tools
    if (appLower.contains('photoshop') || appLower.contains('illustrator') ||
        appLower.contains('figma') || appLower.contains('sketch') ||
        appLower.contains('canva') || appLower.contains('gimp') ||
        appLower.contains('inkscape') || appLower.contains('blender') ||
        appLower.contains('after effects') || appLower.contains('premiere')) {
      return 'Design';
    }
    
    // Communication Tools
    if (appLower.contains('slack') || appLower.contains('teams') ||
        appLower.contains('discord') || appLower.contains('zoom') ||
        appLower.contains('skype') || appLower.contains('telegram') ||
        appLower.contains('whatsapp') || appLower.contains('messenger') ||
        appLower.contains('gmail') || appLower.contains('mail')) {
      return 'Communication';
    }
    
    // Entertainment - Unproductive
    if (appLower.contains('youtube') || appLower.contains('netflix') ||
        appLower.contains('spotify') || appLower.contains('twitch') ||
        appLower.contains('hulu') || appLower.contains('prime video') ||
        appLower.contains('vlc') || appLower.contains('media player') ||
        appLower.contains('steam') || appLower.contains('epic games')) {
      return 'Entertainment';
    }
    
    // Social Media - Unproductive
    if (appLower.contains('facebook') || appLower.contains('twitter') ||
        appLower.contains('instagram') || appLower.contains('tiktok') ||
        appLower.contains('reddit') || appLower.contains('pinterest') ||
        appLower.contains('linkedin') && !appLower.contains('job') ||
        appLower.contains('snapchat')) {
      return 'Social Media';
    }
    
    // System Utilities
    if (appLower.contains('explorer') || appLower.contains('finder') ||
        appLower.contains('terminal') || appLower.contains('powershell') ||
        appLower.contains('cmd') || appLower.contains('notepad') ||
        appLower.contains('settings') || appLower.contains('control panel')) {
      return 'Utilities';
    }
    
    // Browsers (general - check content inside browser for more specific categorization)
    if (appLower.contains('chrome') || appLower.contains('firefox') ||
        appLower.contains('edge') || appLower.contains('safari') ||
        appLower.contains('opera') || appLower.contains('brave')) {
      return 'Browsing';
    }
    
    // Default to Other
    return 'Other';
  }

  // Helper method to calculate categories from app usage data
  List<Map<String, dynamic>> _calculateCategories(List<dynamic> tasks) {
    final Map<String, int> categorySeconds = {};
    
    // Use app usage data if available
    if (_appUsageData.isNotEmpty) {
      for (var usage in _appUsageData) {
        final appName = usage['app_name'] as String? ?? 'Unknown';
        final seconds = (usage['duration_seconds'] as int?) ?? 0;
        
        if (seconds > 0) {
          final category = _categorizeApp(appName);
          
          final currentSeconds = categorySeconds[category] ?? 0;
          categorySeconds[category] = currentSeconds + seconds;
        }
      }
    } else {
      // Fallback to task-based categorization if no app usage data
      final completedTasks = tasks.where((t) => t.status == 'completed').toList();
      
      for (var task in completedTasks) {
        final category = task.taskName.contains('Design') ? 'Design' :
                        task.taskName.contains('Dev') || task.taskName.contains('Code') ? 'Development' :
                        task.taskName.contains('Meet') ? 'Communication' : 'Productivity';
        
        final seconds = task.duration.inSeconds.toInt();
        final currentSeconds = categorySeconds[category] ?? 0;
        categorySeconds[category] = (currentSeconds + seconds).toInt();
      }
    }
    
    final totalSeconds = categorySeconds.values.fold<int>(0, (sum, secs) => sum + secs);
    
    if (totalSeconds == 0) {
      return [
        {'name': 'No Data', 'percent': 0, 'duration': '0min', 'color': const Color(0xFF666666)},
      ];
    }
    
    // Define colors for each category with semantic meaning
    final categoryColors = {
      'Development': const Color(0xFF2196F3),      // Blue - Productive
      'Productivity': const Color(0xFF4CAF50),     // Green - Productive
      'Design': const Color(0xFF9C27B0),           // Purple - Creative
      'Communication': const Color(0xFFFF9800),    // Orange - Collaborative
      'Entertainment': const Color(0xFFF44336),    // Red - Unproductive
      'Social Media': const Color(0xFFE91E63),     // Pink - Unproductive
      'Browsing': const Color(0xFF607D8B),         // Grey - Neutral
      'Utilities': const Color(0xFF00BCD4),        // Cyan - System
      'Other': const Color(0xFF9E9E9E),            // Grey - Unknown
    };
    
    // Sort categories by duration (descending)
    final sortedEntries = categorySeconds.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.map((entry) {
      final percent = ((entry.value / totalSeconds) * 100).round();
      final hours = entry.value ~/ 3600;
      final minutes = (entry.value % 3600) ~/ 60;
      final duration = hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';
      final color = categoryColors[entry.key] ?? const Color(0xFF9E9E9E);
      
      return {
        'name': entry.key,
        'percent': percent,
        'duration': duration,
        'color': color,
      };
    }).toList()..sort((a, b) => (b['percent'] as int).compareTo(a['percent'] as int));
  }

  // Build period filter widget
  Widget _buildPeriodFilter() {
    return Row(
      children: [
        _buildPeriodButton('Day'),
        const SizedBox(width: 12),
        _buildPeriodButton('Week'),
        const SizedBox(width: 12),
        _buildPeriodButton('Month'),
        const SizedBox(width: 12),
        _buildPeriodButton('Year'),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPeriod = period;
            });
          },
          onHover: (hovering) {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
          gradient: isSelected 
            ? const LinearGradient(
                colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          color: isSelected ? null : const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2d7a47) : const Color(0xFF3a3a3a),
            width: 1,
          ),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFb0b0b0),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today Nice Day ⭐',
          style: TextStyle(
            color: Color(0xFFb0b0b0),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateTimeHelper.formatDate(now),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkHoursCard(TaskProvider taskProvider) {
    final filteredTasks = _getFilteredTasks(taskProvider);
    final completedTasks = filteredTasks.where((t) => t.status == 'completed').toList();
    final totalMinutes = completedTasks.fold<int>(0, (sum, task) => (sum + task.duration.inMinutes.toInt()) as int);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final targetHours = _getTargetHours();
    final actualHours = totalMinutes / 60;
    final percentOfTarget = ((actualHours / targetHours) * 100).clamp(0, 100).toInt();

    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Work Hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Work Hours Display
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$hours',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'hr ',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFFb0b0b0),
                        ),
                      ),
                      Text(
                        '$minutes',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'min',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFFb0b0b0),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Percent of Target
                _HoverGlowBox(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Percent of Target',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '%',
                                style: TextStyle(
                                  color: Color(0xFF1c4d2c),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$percentOfTarget%',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: ' of ${targetHours.toInt()}hr',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTimelineCard(TaskProvider taskProvider) {
    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
        child: SizedBox(
          height: 370,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.timeline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Timeline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildTimelineGraph(taskProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineGraph(TaskProvider taskProvider) {
    final filteredTasks = _getFilteredTasks(taskProvider);
    final completedTasks = filteredTasks.where((t) => t.status == 'completed').toList();
    
    return InteractiveTimelineChart(tasks: completedTasks);
  }

  Widget _buildDailySummaryCard(TaskProvider taskProvider) {
    final filteredTasks = _getFilteredTasks(taskProvider);
    final completedTasks = filteredTasks.where((t) => t.status == 'completed').toList();
    final totalMinutes = completedTasks.fold<int>(0, (sum, task) => (sum + task.duration.inMinutes.toInt()) as int);
    
    // Productive: focus time (50%)
    // Unproductive: meetings + breaks (50%)
    final productiveMinutes = (totalMinutes * 0.5).toInt();
    final unproductiveMinutes = (totalMinutes * 0.5).toInt();

    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
        child: SizedBox(
          height: 290,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pie_chart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
              // Interactive Donut Chart
              Expanded(
                child: InteractiveDonutChart(
                  productiveMinutes: productiveMinutes,
                  unproductiveMinutes: unproductiveMinutes,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }  Widget _buildQuickInsightsCard(TaskProvider taskProvider) {
    final filteredTasks = _getFilteredTasks(taskProvider);
    final totalTasks = filteredTasks.length;
    final completedTasks = filteredTasks.where((t) => t.status == 'completed').length;
    final activeTasks = taskProvider.runningTasks.length;
    
    // Calculate average task duration
    final completedTasksList = filteredTasks.where((t) => t.status == 'completed');
    double totalDuration = 0;
    for (var task in completedTasksList) {
      totalDuration += task.duration.inMinutes;
    }
    final avgDuration = completedTasksList.isNotEmpty 
        ? (totalDuration / completedTasksList.length).toInt()
        : 0;
    
    // Calculate productivity score
    final productivityScore = totalTasks > 0 
        ? ((completedTasks / totalTasks) * 100).toInt() 
        : 0;

    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
        child: SizedBox(
          height: 370,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insights, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Quick Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              
              // Productivity Score with circular progress
              Center(
                child: Column(
                  children: [
                    _HoverGlowBox(
                      glowColor: productivityScore >= 80
                          ? const Color(0xFF3fd884)
                          : productivityScore >= 50
                              ? const Color(0xFFf39c12)
                              : const Color(0xFFe74c3c),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: productivityScore / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFF2a2a2a),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                productivityScore >= 80
                                    ? const Color(0xFF1c4d2c)
                                    : productivityScore >= 50
                                        ? const Color(0xFFf39c12)
                                        : const Color(0xFFe74c3c),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$productivityScore%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Score',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),              // Stats Grid
              _buildInsightRow(
                Icons.task_alt,
                'Active Tasks',
                activeTasks.toString(),
                const Color(0xFF1c4d2c),
              ),
              const SizedBox(height: 10),
              _buildInsightRow(
                Icons.check_circle_outline,
                'Completed',
                completedTasks.toString(),
                const Color(0xFF2d7a47),
              ),
              const SizedBox(height: 10),
              _buildInsightRow(
                Icons.schedule,
                'Avg Duration',
                '${avgDuration}min',
                const Color(0xFF3a9254),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildCategoriesCard(TaskProvider taskProvider) {
    final filteredTasks = _getFilteredTasks(taskProvider);
    final categories = _calculateCategories(filteredTasks);

    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
      child: SizedBox(
        height: 300, // Fixed height matching Apps & Websites
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                    onPressed: _loadAppUsageData,
                    tooltip: 'Refresh categories',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: categories.isEmpty || (categories.length == 1 && categories[0]['name'] == 'No Data')
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.pie_chart_outline,
                            size: 48,
                            color: Color(0xFF666666),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No category data yet',
                            style: TextStyle(
                              color: Color(0xFFb0b0b0),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Complete tasks to see categories',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildCategoryItem(
                            percent: cat['percent'] as int,
                            label: cat['name'] as String,
                            duration: cat['duration'] as String,
                            color: cat['color'] as Color,
                          ),
                        )).toList(),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required int percent,
    required String label,
    required String duration,
    required Color color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(2),
              child: CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 4,
                backgroundColor: const Color(0xFF2a2a2a),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              duration,
              style: const TextStyle(
                color: Color(0xFFb0b0b0),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsWebsitesCard(TaskProvider taskProvider) {
    // Calculate total duration for percentage calculation
    final totalDuration = _appUsageData.fold<int>(
      0,
      (sum, app) => sum + (app['total_duration'] as int? ?? 0),
    );

    // Define colors for different apps
    final colors = [
      const Color(0xFF1c4d2c),
      const Color(0xFF2d7a47),
      const Color(0xFF3a9254),
      const Color(0xFF47aa61),
      const Color(0xFF54c26e),
      const Color(0xFF61d27b),
      const Color(0xFF6ee288),
      const Color(0xFF7bf295),
      const Color(0xFF88ffa2),
      const Color(0xFF95ffaf),
    ];

    // Transform app usage data for display
    final apps = _appUsageData.asMap().entries.map((entry) {
      final index = entry.key;
      final app = entry.value;
      final duration = app['total_duration'] as int? ?? 0;
      final percent = totalDuration > 0 ? ((duration / totalDuration) * 100).round() : 0;
      
      // Format duration
      final hours = duration ~/ 3600;
      final minutes = (duration % 3600) ~/ 60;
      final durationStr = hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';

      return {
        'name': app['app_name'] as String,
        'percent': percent,
        'duration': durationStr,
        'color': colors[index % colors.length],
      };
    }).toList();

    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
        child: SizedBox(
          height: 300, // Fixed height
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Apps & Websites',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF3fd884), size: 20),
                      onPressed: _loadAppUsageData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: apps.isEmpty
                      ? const Center(
                          child: Text(
                            'No app usage data yet.\nStart a task to track applications.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFb0b0b0),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: apps.map((app) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildAppItem(
                                percent: app['percent'] as int,
                                label: app['name'] as String,
                                duration: app['duration'] as String,
                                color: app['color'] as Color,
                              ),
                            )).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppItem({
    required int percent,
    required String label,
    required String duration,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 4,
            backgroundColor: const Color(0xFF2a2a2a),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
        Text(
          duration,
          style: const TextStyle(
            color: Color(0xFFb0b0b0),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTasksCard(TaskProvider taskProvider) {
    final tasks = taskProvider.tasks.where((t) => t.status == 'completed').take(4).toList();
    
    return _AnimatedHoverCard(
      child: Card(
        elevation: 8,
        shadowColor: const Color(0xFF1c4d2c).withOpacity(0.3),
      child: SizedBox(
        height: 300, // Fixed height matching other cards
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Projects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No completed tasks yet',
                        style: TextStyle(
                          color: Color(0xFFb0b0b0),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: tasks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final task = entry.value;
                          final colors = [
                            const Color(0xFF1c4d2c),
                            const Color(0xFF2d7a47),
                            const Color(0xFF3a9254),
                            const Color(0xFF47aa61),
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildTaskItem(
                              percent: math.min(100, (task.duration.inMinutes * 2)),
                              label: task.taskName,
                              duration: task.formattedDuration,
                              color: colors[index % colors.length],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTaskItem({
    required int percent,
    required String label,
    required String duration,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    duration,
                    style: const TextStyle(
                      color: Color(0xFFb0b0b0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF2a2a2a),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Hover Glow Box Widget for small interactive elements
class _HoverGlowBox extends StatefulWidget {
  final Widget child;
  final Color glowColor;

  const _HoverGlowBox({
    required this.child,
    this.glowColor = const Color(0xFF3fd884),
  });

  @override
  State<_HoverGlowBox> createState() => _HoverGlowBoxState();
}

class _HoverGlowBoxState extends State<_HoverGlowBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withOpacity(0.15 * _glowAnimation.value),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 3 * _glowAnimation.value,
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// Animated Hover Card Widget for Dashboard Cards
class _AnimatedHoverCard extends StatefulWidget {
  final Widget child;

  const _AnimatedHoverCard({required this.child});

  @override
  State<_AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<_AnimatedHoverCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _controller.forward();
      },
      onExit: (_) {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1c4d2c).withOpacity(0.3 * _elevationAnimation.value),
                    blurRadius: 20 * _elevationAnimation.value,
                    spreadRadius: 2 * _elevationAnimation.value,
                    offset: Offset(0, 4 * _elevationAnimation.value),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// Interactive Donut Chart Widget with Hover Effect
class InteractiveDonutChart extends StatefulWidget {
  final int productiveMinutes;
  final int unproductiveMinutes;

  const InteractiveDonutChart({
    super.key,
    required this.productiveMinutes,
    required this.unproductiveMinutes,
  });

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart> with SingleTickerProviderStateMixin {
  String? _hoveredSegment;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
      onHover: (event) {
        // Calculate which segment is being hovered
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(event.position);
        final center = Offset(box.size.width / 2, box.size.height / 2);
        
        final dx = localPosition.dx - center.dx;
        final dy = localPosition.dy - center.dy;
        final distance = math.sqrt(dx * dx + dy * dy);
        final radius = math.min(box.size.width, box.size.height) / 2 - 20;
        final innerRadius = radius * 0.6;
        
        // Check if within donut area
        if (distance >= innerRadius && distance <= radius) {
          var angle = math.atan2(dy, dx);
          if (angle < 0) angle += 2 * math.pi;
          
          // Adjust angle to start from top
          angle = (angle + math.pi / 2) % (2 * math.pi);
          
          final total = widget.productiveMinutes + widget.unproductiveMinutes;
          final productiveAngle = (widget.productiveMinutes / total) * 2 * math.pi;
          
          final newSegment = angle < productiveAngle ? 'Productive' : 'Unproductive';
          if (_hoveredSegment != newSegment) {
            setState(() {
              _hoveredSegment = newSegment;
            });
            _animationController.forward();
          }
        } else {
          if (_hoveredSegment != null) {
            setState(() {
              _hoveredSegment = null;
            });
            _animationController.reverse();
          }
        }
      },
      onExit: (_) {
        setState(() {
          _hoveredSegment = null;
        });
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: InteractiveDonutChartPainter(
              productiveMinutes: widget.productiveMinutes,
              unproductiveMinutes: widget.unproductiveMinutes,
              hoveredSegment: _hoveredSegment,
              animationValue: _scaleAnimation.value,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

// Interactive Timeline Chart Widget with Hover Tooltip
class InteractiveTimelineChart extends StatefulWidget {
  final List tasks;

  const InteractiveTimelineChart({
    super.key,
    required this.tasks,
  });

  @override
  State<InteractiveTimelineChart> createState() => _InteractiveTimelineChartState();
}

class _InteractiveTimelineChartState extends State<InteractiveTimelineChart> with SingleTickerProviderStateMixin {
  String? _tooltipText;
  int? _hoveredTaskIndex;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context, Offset position, String text) {
    _removeOverlay();
    
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(position);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 15,
        top: offset.dy - 70,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * _glowAnimation.value),
              child: Opacity(
                opacity: _glowAnimation.value,
                child: Material(
                  elevation: 1000,
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1c4d2c), Color(0xFF2d7a47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3fd884), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3fd884).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Productivity',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text.split('\n')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Color(0xFF3fd884),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                text.split('\n').length > 1 ? text.split('\n')[1] : '',
                                style: const TextStyle(
                                  color: Color(0xFF3fd884),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(event.position);
            
            // Check if hovering over a task bar
            final hourWidth = constraints.maxWidth / 24;
            bool foundTask = false;
            
            for (var i = 0; i < widget.tasks.length; i++) {
              final task = widget.tasks[i];
              if (task.scheduledStartTime == null) continue;
              
              final startHour = task.scheduledStartTime!.hour + task.scheduledStartTime!.minute / 60;
              final duration = task.duration.inMinutes / 60;
              final endHour = math.min(24, startHour + duration);
              
              final x1 = startHour * hourWidth;
              final x2 = endHour * hourWidth;
              
              if (localPosition.dx >= x1 && localPosition.dx <= x2 && 
                  localPosition.dy >= 10 && localPosition.dy <= constraints.maxHeight - 20) {
                if (_hoveredTaskIndex != i) {
                  setState(() {
                    _hoveredTaskIndex = i;
                    final hours = duration.floor();
                    final minutes = ((duration - hours) * 60).round();
                    _tooltipText = '${task.taskName}\n${hours}h ${minutes}m';
                  });
                  _animationController.forward();
                  _showOverlay(context, localPosition, _tooltipText!);
                }
                foundTask = true;
                return;
              }
            }
            
            if (!foundTask && _hoveredTaskIndex != null) {
              setState(() {
                _tooltipText = null;
                _hoveredTaskIndex = null;
              });
              _animationController.reverse();
              _removeOverlay();
            }
          },
          onExit: (_) {
            setState(() {
              _tooltipText = null;
              _hoveredTaskIndex = null;
            });
            _animationController.reverse();
            _removeOverlay();
          },
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: TimelinePainter(
                  tasks: widget.tasks,
                  hoveredTaskIndex: _hoveredTaskIndex,
                  glowValue: _glowAnimation.value,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Custom Painter for Timeline Graph
class TimelinePainter extends CustomPainter {
  final List tasks;
  final int? hoveredTaskIndex;
  final double glowValue;

  TimelinePainter({
    required this.tasks,
    this.hoveredTaskIndex,
    this.glowValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw hour labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    final hourWidth = size.width / 24;
    
    // Draw grid lines and labels
    for (int i = 0; i <= 24; i += 3) {
      final x = i * hourWidth;
      
      // Draw grid line
      final gridPaint = Paint()
        ..color = const Color(0xFF2a2a2a)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height - 20), gridPaint);
      
      // Draw hour label
      textPainter.text = TextSpan(
        text: '${i % 12 == 0 ? 12 : i % 12} ${i < 12 ? 'am' : 'pm'}',
        style: const TextStyle(
          color: Color(0xFF808080),
          fontSize: 11,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 18));
    }
    
    // Draw task blocks
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      if (task.scheduledStartTime == null) continue;
      
      final isHovered = hoveredTaskIndex == i;
      
      final startHour = task.scheduledStartTime!.hour + task.scheduledStartTime!.minute / 60;
      final duration = task.duration.inMinutes / 60;
      final endHour = math.min(24, startHour + duration);
      
      final x1 = startHour * hourWidth;
      final x2 = endHour * hourWidth;
      final blockHeight = size.height - 30;
      
      final rect = Rect.fromLTWH(x1, 10, x2 - x1, blockHeight);
      
      // Draw glow effect when hovering
      if (isHovered && glowValue > 0) {
        final glowPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF3fd884).withOpacity(0.25 * glowValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(3 * glowValue),
            const Radius.circular(6),
          ),
          glowPaint,
        );
      }
      
      // Gradient colors - slightly brighter when hovered
      final gradient = LinearGradient(
        colors: isHovered && glowValue > 0
          ? [
              const Color(0xFF1f5a35),
              const Color(0xFF2d7a47),
              const Color(0xFF47aa61),
            ]
          : [
              const Color(0xFF1c4d2c),
              const Color(0xFF2d7a47),
              const Color(0xFF3fd884),
            ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
      
      paint.shader = gradient.createShader(rect);
      
      // Scale effect when hovering
      final drawRect = isHovered && glowValue > 0
          ? Rect.fromLTWH(
              x1 - (1.5 * glowValue),
              10 - (1 * glowValue),
              (x2 - x1) + (3 * glowValue),
              blockHeight + (2 * glowValue),
            )
          : rect;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(drawRect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) => true;
}

// Interactive Custom Painter for Donut Chart with Hover Effect
class InteractiveDonutChartPainter extends CustomPainter {
  final int productiveMinutes;
  final int unproductiveMinutes;
  final String? hoveredSegment;
  final double animationValue;

  InteractiveDonutChartPainter({
    required this.productiveMinutes,
    required this.unproductiveMinutes,
    this.hoveredSegment,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 20;
    final innerRadius = baseRadius * 0.6;
    
    final total = productiveMinutes + unproductiveMinutes;
    if (total == 0) {
      // Draw empty state circle
      final emptyPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseRadius - innerRadius
        ..color = const Color(0xFF2a2a2a);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (baseRadius + innerRadius) / 2),
        0,
        2 * math.pi,
        false,
        emptyPaint,
      );
      return;
    }
    
    double startAngle = -math.pi / 2;
    
    // Draw Productive segment (green)
    final productiveAngle = (productiveMinutes / total) * 2 * math.pi;
    final hoverScale = hoveredSegment == 'Productive' ? animationValue : 1.0;
    final productiveRadius = baseRadius + (6 * (hoverScale - 1.0));
    final productiveStroke = (baseRadius - innerRadius) + (4 * (hoverScale - 1.0));
    
    // Draw glow effect when hovering
    if (hoveredSegment == 'Productive') {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = productiveStroke + 8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3fd884).withOpacity(0.2 * (hoverScale - 1.0) * 12.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (productiveRadius + innerRadius) / 2),
        startAngle,
        productiveAngle,
        false,
        glowPaint,
      );
    }
    
    final productivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = productiveStroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: hoveredSegment == 'Productive'
          ? [const Color(0xFF1f5a35), const Color(0xFF2d7a47), const Color(0xFF47aa61)]
          : [const Color(0xFF1c4d2c), const Color(0xFF2d7a47), const Color(0xFF3fd884)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: productiveRadius));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (productiveRadius + innerRadius) / 2),
      startAngle,
      productiveAngle,
      false,
      productivePaint,
    );
    
    startAngle += productiveAngle;
    
    // Draw Unproductive segment (red/orange)
    final unproductiveAngle = (unproductiveMinutes / total) * 2 * math.pi;
    final hoverScaleUnprod = hoveredSegment == 'Unproductive' ? animationValue : 1.0;
    final unproductiveRadius = baseRadius + (6 * (hoverScaleUnprod - 1.0));
    final unproductiveStroke = (baseRadius - innerRadius) + (4 * (hoverScaleUnprod - 1.0));
    
    // Draw glow effect when hovering
    if (hoveredSegment == 'Unproductive') {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unproductiveStroke + 8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFf39c12).withOpacity(0.2 * (hoverScaleUnprod - 1.0) * 12.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (unproductiveRadius + innerRadius) / 2),
        startAngle,
        unproductiveAngle,
        false,
        glowPaint,
      );
    }
    
    final unproductivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unproductiveStroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: hoveredSegment == 'Unproductive'
          ? [const Color(0xFFe74c3c), const Color(0xFFff8a42)]
          : [const Color(0xFFe74c3c), const Color(0xFFf39c12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: unproductiveRadius));
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (unproductiveRadius + innerRadius) / 2),
      startAngle,
      unproductiveAngle,
      false,
      unproductivePaint,
    );
    
    // Draw percentage text only when hovering
    if (hoveredSegment == 'Productive') {
      // Draw percentage text for productive
      final productivePercent = ((productiveMinutes / total) * 100).toInt();
      final productiveTextAngle = -math.pi / 2 + (productiveAngle / 2);
      final productiveTextRadius = (baseRadius + innerRadius) / 2;
      final productiveTextPosition = Offset(
        center.dx + productiveTextRadius * math.cos(productiveTextAngle),
        center.dy + productiveTextRadius * math.sin(productiveTextAngle),
      );
      
      _drawText(
        canvas,
        '$productivePercent%',
        productiveTextPosition,
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(1, 1),
            ),
          ],
        ),
      );
    }
    
    if (hoveredSegment == 'Unproductive') {
      // Draw percentage text for unproductive
      final unproductivePercent = ((unproductiveMinutes / total) * 100).toInt();
      final unproductiveTextAngle = -math.pi / 2 + productiveAngle + (unproductiveAngle / 2);
      final unproductiveTextRadius = (baseRadius + innerRadius) / 2;
      final unproductiveTextPosition = Offset(
        center.dx + unproductiveTextRadius * math.cos(unproductiveTextAngle),
        center.dy + unproductiveTextRadius * math.sin(unproductiveTextAngle),
      );
      
      _drawText(
        canvas,
        '$unproductivePercent%',
        unproductiveTextPosition,
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black54,
              blurRadius: 4,
              offset: Offset(1, 1),
            ),
          ],
        ),
      );
    }
  }
  
  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(InteractiveDonutChartPainter oldDelegate) {
    return oldDelegate.hoveredSegment != hoveredSegment ||
           oldDelegate.productiveMinutes != productiveMinutes ||
           oldDelegate.unproductiveMinutes != unproductiveMinutes ||
           oldDelegate.animationValue != animationValue;
  }
}

// Old Donut Chart Painter (kept for backwards compatibility)
class DonutChartPainter extends CustomPainter {
  final int focusMinutes;
  final int meetingMinutes;
  final int breaksMinutes;

  DonutChartPainter({
    required this.focusMinutes,
    required this.meetingMinutes,
    required this.breaksMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final innerRadius = radius * 0.6;
    
    final total = focusMinutes + meetingMinutes + breaksMinutes;
    if (total == 0) return;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius - innerRadius
      ..strokeCap = StrokeCap.round;
    
    double startAngle = -math.pi / 2;
    
    // Draw Focus segment
    final focusAngle = (focusMinutes / total) * 2 * math.pi;
    paint.color = const Color(0xFF1c4d2c);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      focusAngle,
      false,
      paint,
    );
    startAngle += focusAngle;
    
    // Draw Meeting segment
    final meetingAngle = (meetingMinutes / total) * 2 * math.pi;
    paint.color = const Color(0xFF4a90e2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      meetingAngle,
      false,
      paint,
    );
    startAngle += meetingAngle;
    
    // Draw Breaks segment
    final breaksAngle = (breaksMinutes / total) * 2 * math.pi;
    paint.color = const Color(0xFF2d7a47);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
      startAngle,
      breaksAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => true;
}
