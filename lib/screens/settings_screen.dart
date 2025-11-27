/// Settings Screen
/// Configure Azure, Odoo, and app settings
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import 'common/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Azure Settings
  final _azureAccountController = TextEditingController();
  final _azureKeyController = TextEditingController();
  final _azureContainerController = TextEditingController();

  // App Settings
  int _screenshotInterval = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _azureAccountController.dispose();
    _azureKeyController.dispose();
    _azureContainerController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _azureAccountController.text =
          prefs.getString(AppConstants.settingsAzureStorageAccount) ?? '';
      _azureKeyController.text =
          prefs.getString(AppConstants.settingsAzureAccessKey) ?? '';
      _azureContainerController.text =
          prefs.getString(AppConstants.settingsAzureContainerName) ??
              'employee-screenshots';
      _screenshotInterval =
          prefs.getInt(AppConstants.settingsScreenshotInterval) ?? 5;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.settingsAzureStorageAccount, _azureAccountController.text);
    await prefs.setString(
        AppConstants.settingsAzureAccessKey, _azureKeyController.text);
    await prefs.setString(
        AppConstants.settingsAzureContainerName, _azureContainerController.text);
    await prefs.setInt(
        AppConstants.settingsScreenshotInterval, _screenshotInterval);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0d0d0d),
        drawer: AppDrawer(currentPage: DrawerPage.settings),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3fd884))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d0d),
      drawer: const AppDrawer(currentPage: DrawerPage.settings),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Azure Settings
                  const Text(
                    'Azure Blob Storage',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _azureAccountController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Storage Account Name',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF3fd884), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _azureKeyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Access Key',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF3fd884), width: 2),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _azureContainerController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Container Name',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF3fd884), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1c4d2c),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
