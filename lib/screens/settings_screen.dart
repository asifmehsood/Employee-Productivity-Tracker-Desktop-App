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
        drawer: AppDrawer(currentPage: DrawerPage.settings),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(currentPage: DrawerPage.settings),
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Azure Settings
            const Text(
              'Azure Blob Storage',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _azureAccountController,
              decoration: const InputDecoration(
                labelText: 'Storage Account Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _azureKeyController,
              decoration: const InputDecoration(
                labelText: 'Access Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _azureContainerController,
              decoration: const InputDecoration(
                labelText: 'Container Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // App Settings
            const Text(
              'Application Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Screenshot Interval'),
              subtitle: Text('$_screenshotInterval minutes'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: _screenshotInterval.toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  label: '$_screenshotInterval min',
                  onChanged: (value) {
                    setState(() => _screenshotInterval = value.toInt());
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
