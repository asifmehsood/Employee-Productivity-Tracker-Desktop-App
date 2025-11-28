/// Task List Screen
/// Displays all tasks with filtering options
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../core/utils/date_time_helper.dart';
import 'task_detail_screen.dart';
import 'common/app_drawer.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  String _filter = 'all';
  int? _hoveredIndex;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d0d0d),
      drawer: const AppDrawer(currentPage: DrawerPage.allTasks),
      appBar: AppBar(
        title: const Text('All Tasks', style: TextStyle(fontWeight: FontWeight.w600)),
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
            builder: (context, taskProvider, _) {
              final tasks = _getFilteredTasks(taskProvider);
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a1a),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3fd884).withOpacity(0.3), width: 1),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) => setState(() => _filter = value),
                            color: const Color(0xFF1a1a1a),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: const Color(0xFF3fd884).withOpacity(0.3), width: 1),
                            ),
                            icon: Row(
                              children: [
                                Icon(
                                  _getFilterIcon(_filter),
                                  color: const Color(0xFF3fd884),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getFilterLabel(_filter),
                                  style: const TextStyle(
                                    color: Color(0xFF3fd884),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF3fd884),
                                ),
                              ],
                            ),
                            itemBuilder: (context) => [
                              _buildMenuItem('all', 'All Tasks', Icons.list),
                              _buildMenuItem('active', 'Active', Icons.play_circle),
                              _buildMenuItem('scheduled', 'Scheduled', Icons.schedule),
                              _buildMenuItem('paused', 'Paused', Icons.pause_circle),
                              _buildMenuItem('completed', 'Completed', Icons.check_circle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    
                    // Task List
                    if (tasks.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF3fd884).withOpacity(0.1),
                                    const Color(0xFF2d7a47).withOpacity(0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getFilterIcon(_filter),
                                size: 64,
                                color: const Color(0xFF3fd884).withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No ${_getFilterLabel(_filter).toLowerCase()} found',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start by creating a new task',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...tasks.asMap().entries.map((entry) {
                        final index = entry.key;
                        final task = entry.value;
                        return _buildTaskCard(task, taskProvider, index);
                      }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3fd884).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3fd884) : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF3fd884) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(
                Icons.check,
                color: Color(0xFF3fd884),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'active':
        return Icons.play_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'paused':
        return Icons.pause_circle;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.list;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'active':
        return 'Active';
      case 'scheduled':
        return 'Scheduled';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      default:
        return 'All Tasks';
    }
  }

  List<TaskModel> _getFilteredTasks(TaskProvider provider) {
    switch (_filter) {
      case 'active':
        return provider.activeTasks;
      case 'scheduled':
        final now = DateTime.now();
        return provider.tasks.where((t) => t.isActive && t.startTime.isAfter(now)).toList();
      case 'paused':
        return provider.pausedTasks;
      case 'completed':
        return provider.completedTasks;
      default:
        return provider.tasks;
    }
  }

  Widget _buildTaskCard(TaskModel task, TaskProvider provider, int index) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hoveredIndex == index
                ? [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF0d0d0d),
                  ]
                : [
                    const Color(0xFF0d0d0d),
                    const Color(0xFF0d0d0d),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hoveredIndex == index
                ? const Color(0xFF3fd884).withOpacity(0.5)
                : const Color(0xFF3fd884).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: _hoveredIndex == index
              ? [
                  BoxShadow(
                    color: const Color(0xFF3fd884).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(task: task),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF3fd884).withOpacity(0.1),
            highlightColor: const Color(0xFF3fd884).withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Status Icon with Glow Effect
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getStatusColor(task.status).withOpacity(0.3),
                          _getStatusColor(task.status).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(task.status).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: _hoveredIndex == index
                          ? [
                              BoxShadow(
                                color: _getStatusColor(task.status).withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _getStatusIcon(task.status),
                      color: _getStatusColor(task.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Name
                        Text(
                          task.taskName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (task.taskDescription.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.taskDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Duration and Time Row
                        Row(
                          children: [
                            // Duration Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3fd884).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF3fd884).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Color(0xFF3fd884),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    task.formattedDuration,
                                    style: const TextStyle(
                                      color: Color(0xFF3fd884),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Date Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateTimeHelper.formatDateTime(task.startTime),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Arrow Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hoveredIndex == index
                          ? const Color(0xFF3fd884).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: _hoveredIndex == index
                          ? const Color(0xFF3fd884)
                          : Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.play_circle;
      case 'paused':
        return Icons.pause_circle;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF3fd884);
      case 'paused':
        return const Color(0xFF6dd4a8);
      case 'completed':
        return const Color(0xFF2d7a47);
      default:
        return Colors.grey;
    }
  }
}
