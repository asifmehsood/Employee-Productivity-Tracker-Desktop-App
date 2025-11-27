/// Task Form Screen
/// Form to create a new task with scheduling
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  bool _isSubmitting = false;
  
  // Focus nodes for animations
  final _taskNameFocus = FocusNode();
  final _taskDescriptionFocus = FocusNode();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDescriptionController.dispose();
    _taskNameFocus.dispose();
    _taskDescriptionFocus.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task', style: TextStyle(fontWeight: FontWeight.w600)),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 120.0, 24.0, 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 32),
                      
                      // Task Name Field
                      _buildAnimatedField(
                        child: _buildTaskNameField(),
                        delay: 100,
                      ),
                      const SizedBox(height: 24),
                      
                      // Task Description Field
                      _buildAnimatedField(
                        child: _buildDescriptionField(),
                        delay: 200,
                      ),
                      const SizedBox(height: 24),
                      
                      // Date Time Pickers Row
                      _buildAnimatedField(
                        child: _buildDateTimePickers(),
                        delay: 300,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Submit Button
                      _buildAnimatedField(
                        child: _buildSubmitButton(),
                        delay: 400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1c4d2c),
                const Color(0xFF2d7a47),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1c4d2c).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.assignment_add,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Plan Your Next Task',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Schedule and track your productivity',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedField({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildTaskNameField() {
    return TextFormField(
      controller: _taskNameController,
      focusNode: _taskNameFocus,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
          hintText: 'Task Name',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1c4d2c).withOpacity(0.3),
                  const Color(0xFF2d7a47).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task_alt, color: Color(0xFF1c4d2c), size: 20),
          ),
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1c4d2c), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      onChanged: (value) {
        // Revalidate on text change to clear error and turn border green
        if (value.isNotEmpty) {
          _formKey.currentState?.validate();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '⚠️ Please enter a task name';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _taskDescriptionController,
      focusNode: _taskDescriptionFocus,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      maxLines: 4,
      decoration: InputDecoration(
          hintText: 'Task Description',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1c4d2c).withOpacity(0.3),
                  const Color(0xFF2d7a47).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFF1c4d2c), size: 20),
          ),
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[800]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1c4d2c), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      textCapitalization: TextCapitalization.sentences,
      );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        // Start DateTime
        _DateTimePickerCard(
          icon: Icons.play_circle_outline,
          label: 'Start Time',
          dateTime: _startDateTime,
          onTap: _pickStartDateTime,
          isEnabled: true,
        ),
        const SizedBox(height: 16),
        
        // End DateTime
        _DateTimePickerCard(
          icon: Icons.stop_circle_outlined,
          label: 'Stop Time',
          dateTime: _endDateTime,
          onTap: _pickEndDateTime,
          isEnabled: _startDateTime != null,
          helperText: _startDateTime == null ? 'Select start time first' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Consumer2<TaskProvider, AuthProvider>(
      builder: (context, taskProvider, authProvider, child) {
        return _AnimatedSubmitButton(
          isSubmitting: _isSubmitting,
          onPressed: () => _submitForm(taskProvider, authProvider),
        );
      },
    );
  }

  Future<void> _pickStartDateTime() async {
    // Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    // Pick Time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _startDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      // Reset end time if it's before the new start time
      if (_endDateTime != null && _endDateTime!.isBefore(_startDateTime!)) {
        _endDateTime = null;
      }
    });
  }

  Future<void> _pickEndDateTime() async {
    if (_startDateTime == null) return;

    // Pick Date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime!,
      firstDate: _startDateTime!,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    // Determine initial time and valid time range
    TimeOfDay initialTime;
    if (pickedDate.year == _startDateTime!.year &&
        pickedDate.month == _startDateTime!.month &&
        pickedDate.day == _startDateTime!.day) {
      // Same day: time must be after start time
      initialTime = TimeOfDay(
        hour: _startDateTime!.hour,
        minute: _startDateTime!.minute + 1,
      );
    } else {
      // Different day: any time is valid
      initialTime = TimeOfDay.now();
    }

    // Pick Time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !mounted) return;

    final tentativeEndDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validate that end time is after start time
    if (tentativeEndDateTime.isBefore(_startDateTime!) ||
        tentativeEndDateTime.isAtSameMomentAs(_startDateTime!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _endDateTime = tentativeEndDateTime;
    });
  }

  Future<void> _submitForm(
    TaskProvider taskProvider,
    AuthProvider authProvider,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date/time selection
    if (_startDateTime == null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF1c4d2c).withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1c4d2c).withOpacity(0.3),
                      const Color(0xFF2d7a47).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF1c4d2c),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Start Time Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Please select task start time to continue.',
            style: TextStyle(
              color: Color(0xFFb0b0b0),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1c4d2c),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_endDateTime == null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFF1c4d2c).withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1c4d2c).withOpacity(0.3),
                      const Color(0xFF2d7a47).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF1c4d2c),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stop Time Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Please select task stop time to continue.',
            style: TextStyle(
              color: Color(0xFFb0b0b0),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1c4d2c),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final task = await taskProvider.startNewTask(
      employeeId: authProvider.employeeId,
      employeeName: authProvider.employeeName,
      taskName: _taskNameController.text.trim(),
      taskDescription: _taskDescriptionController.text.trim(),
      scheduledStartTime: _startDateTime,
      scheduledEndTime: _endDateTime,
    );

    setState(() => _isSubmitting = false);

    if (task != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task created successfully!'),
          backgroundColor: const Color(0xFF1c4d2c),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate to home page (Task Creation page)
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create task')),
      );
    }
  }
}

// Animated TextField Wrapper with hover and focus effects
class _AnimatedTextFieldWrapper extends StatefulWidget {
  final Widget child;
  final FocusNode focusNode;

  const _AnimatedTextFieldWrapper({
    required this.child,
    required this.focusNode,
  });

  @override
  State<_AnimatedTextFieldWrapper> createState() => _AnimatedTextFieldWrapperState();
}

class _AnimatedTextFieldWrapperState extends State<_AnimatedTextFieldWrapper> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered || isFocused ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: _isHovered || isFocused
                ? LinearGradient(
                    colors: [
                      const Color(0xFF1a1a1a),
                      const Color(0xFF1c4d2c).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isFocused)
                BoxShadow(
                  color: const Color(0xFF1c4d2c).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              if (_isHovered && !isFocused)
                BoxShadow(
                  color: const Color(0xFF1c4d2c).withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Date Time Picker Card with beautiful animations
class _DateTimePickerCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final DateTime? dateTime;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? helperText;

  const _DateTimePickerCard({
    required this.icon,
    required this.label,
    required this.dateTime,
    required this.onTap,
    required this.isEnabled,
    this.helperText,
  });

  @override
  State<_DateTimePickerCard> createState() => _DateTimePickerCardState();
}

class _DateTimePickerCardState extends State<_DateTimePickerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.dateTime != null;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: AnimatedScale(
        scale: _isHovered && widget.isEnabled ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: widget.isEnabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1a1a1a),
                  hasValue
                      ? const Color(0xFF1c4d2c).withOpacity(0.1)
                      : const Color(0xFF1a1a1a),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasValue
                    ? const Color(0xFF1c4d2c).withOpacity(0.5)
                    : Colors.grey[800]!,
                width: hasValue ? 2 : 1,
              ),
              boxShadow: [
                if (_isHovered && widget.isEnabled)
                  BoxShadow(
                    color: const Color(0xFF1c4d2c).withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasValue
                              ? [const Color(0xFF1c4d2c), const Color(0xFF2d7a47)]
                              : [
                                  Colors.grey[800]!,
                                  Colors.grey[700]!,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (hasValue)
                            BoxShadow(
                              color: const Color(0xFF1c4d2c).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: hasValue ? const Color(0xFF1c4d2c) : Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.dateTime != null
                                ? _formatDisplayDateTime(widget.dateTime!)
                                : 'Tap to select',
                            style: TextStyle(
                              color: widget.dateTime != null ? Colors.white : Colors.grey[600],
                              fontSize: 16,
                              fontWeight: widget.dateTime != null ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: widget.isEnabled ? const Color(0xFF1c4d2c) : Colors.grey[700],
                    ),
                  ],
                ),
                if (widget.helperText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        widget.helperText!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDisplayDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$minute';
  }
}

// Animated Submit Button with loading state
class _AnimatedSubmitButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _AnimatedSubmitButton({
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  State<_AnimatedSubmitButton> createState() => _AnimatedSubmitButtonState();
}

class _AnimatedSubmitButtonState extends State<_AnimatedSubmitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isSubmitting ? SystemMouseCursors.wait : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered && !widget.isSubmitting ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isSubmitting
                  ? [Colors.grey[700]!, Colors.grey[800]!]
                  : [
                      const Color(0xFF1c4d2c),
                      const Color(0xFF2d7a47),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!widget.isSubmitting)
                BoxShadow(
                  color: const Color(0xFF1c4d2c).withOpacity(_isHovered ? 0.6 : 0.4),
                  blurRadius: _isHovered ? 25 : 15,
                  spreadRadius: _isHovered ? 3 : 1,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isSubmitting ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: widget.isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Creating Task...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Create & Start Task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
