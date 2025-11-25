/// Auth Provider
/// Manages employee/user authentication and profile information
/// Handles login state and employee details

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import '../core/constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  EmployeeModel? _currentEmployee;
  bool _isLoggedIn = false;

  // Getters
  EmployeeModel? get currentEmployee => _currentEmployee;
  bool get isLoggedIn => _isLoggedIn;
  String get employeeId => _currentEmployee?.id ?? '';
  String get employeeName => _currentEmployee?.name ?? '';

  /// Initialize and load saved employee data
  Future<void> initialize() async {
    await _loadEmployeeData();
  }

  /// Load employee data from shared preferences
  Future<void> _loadEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString(AppConstants.settingsEmployeeId);
      final employeeName = prefs.getString(AppConstants.settingsEmployeeName);

      if (employeeId != null && employeeName != null) {
        _currentEmployee = EmployeeModel(
          id: employeeId,
          name: employeeName,
          email: '', // Can be added later if needed
          createdAt: DateTime.now(),
        );
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading employee data: $e');
    }
  }

  /// Login/Set employee information
  Future<bool> login({
    required String employeeId,
    required String employeeName,
    String? email,
    String? department,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.settingsEmployeeId, employeeId);
      await prefs.setString(AppConstants.settingsEmployeeName, employeeName);

      _currentEmployee = EmployeeModel(
        id: employeeId,
        name: employeeName,
        email: email ?? '',
        department: department ?? '',
        createdAt: DateTime.now(),
      );

      _isLoggedIn = true;
      notifyListeners();

      print('Employee logged in: $employeeName');
      return true;
    } catch (e) {
      print('Error logging in: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.settingsEmployeeId);
      await prefs.remove(AppConstants.settingsEmployeeName);

      _currentEmployee = null;
      _isLoggedIn = false;
      notifyListeners();

      print('Employee logged out');
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  /// Update employee information
  Future<bool> updateEmployee({
    String? name,
    String? email,
    String? department,
  }) async {
    if (_currentEmployee == null) return false;

    try {
      final updatedEmployee = _currentEmployee!.copyWith(
        name: name,
        email: email,
        department: department,
      );

      // Save to preferences
      if (name != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.settingsEmployeeName, name);
      }

      _currentEmployee = updatedEmployee;
      notifyListeners();

      return true;
    } catch (e) {
      print('Error updating employee: $e');
      return false;
    }
  }

  /// Check if employee is set up
  bool isSetup() {
    return _currentEmployee != null &&
           _currentEmployee!.id.isNotEmpty &&
           _currentEmployee!.name.isNotEmpty;
  }
}
