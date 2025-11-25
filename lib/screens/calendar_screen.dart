/// Calendar Screen
/// Shows daily work hours in calendar view

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends Scaffold {
  CalendarScreen({super.key})
      : super(
          appBar: AppBar(
            title: const Text('Work Calendar'),
            elevation: 2,
          ),
          body: const CalendarView(),
        );
}

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _selectedMonth = DateTime.now();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonthSelector(),
        _buildLegend(),
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }
  
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.red.shade100, '< 4 hrs'),
          const SizedBox(width: 12),
          _buildLegendItem(Colors.amber.shade200, '4-8 hrs'),
          const SizedBox(width: 12),
          _buildLegendItem(Colors.green.shade200, '8+ hrs'),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth + firstWeekday,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return Container(); // Empty space before first day
        }
        
        final day = index - firstWeekday + 1;
        final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
        
        return _buildDayCell(date);
      },
    );
  }
  
  Widget _buildDayCell(DateTime date) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: taskProvider.getWorkSessionForDate(date),
          builder: (context, snapshot) {
            final workMinutes = snapshot.data?['totalMinutes'] ?? 0;
            final hasWork = workMinutes > 0;
            final hoursWorked = workMinutes / 60.0;
            
            // Calculate color based on hours worked
            Color? cellColor;
            if (isToday) {
              cellColor = Colors.purple.shade100;
            } else if (hasWork) {
              if (hoursWorked >= 8) {
                // 8+ hours = green (worked full day)
                cellColor = Colors.green.shade200;
              } else if (hoursWorked >= 4) {
                // 4-8 hours = yellow/amber (partial day)
                cellColor = Colors.amber.shade200;
              } else {
                // Less than 4 hours = light red (minimal work)
                cellColor = Colors.red.shade100;
              }
            }
            
            return Card(
              elevation: isToday ? 4 : 1,
              color: cellColor,
              child: InkWell(
                onTap: hasWork
                    ? () => _showDayDetails(context, date, snapshot.data!)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: Colors.black87,
                            ),
                      ),
                      if (hasWork) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatMinutes(workMinutes),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
  
  void _showDayDetails(BuildContext context, DateTime date, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMMM d, yyyy').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Total Time', _formatMinutes(data['totalMinutes'])),
            _buildDetailRow('Tasks Completed', '${data['completed']}'),
            _buildDetailRow('Tasks Active', '${data['active']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
