/// Azure Service
/// Handles file uploads to Azure Blob Storage
/// Manages authentication and blob operations

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../constants/azure_config.dart';
import '../../models/screenshot_model.dart';
import 'database_helper.dart';

class AzureService {
  AzureConfig _config;

  AzureService(this._config);

  /// Update Azure configuration
  void updateConfig(AzureConfig config) {
    _config = config;
  }

  /// Upload a file to Azure Blob Storage
  /// Returns the blob URL if successful, null otherwise
  Future<String?> uploadFile(File file, String blobName) async {
    try {
      if (!_config.isValid()) {
        print('Azure configuration is invalid');
        return null;
      }

      final fileBytes = await file.readAsBytes();
      final url = '${_config.containerUrl}/$blobName';
      
      // Generate authorization header
      final dateString = HttpDate.format(DateTime.now().toUtc());
      final authHeader = _generateAuthorizationHeader(
        storageAccount: _config.storageAccount,
        accessKey: _config.accessKey,
        method: 'PUT',
        url: url,
        contentLength: fileBytes.length,
        contentType: 'image/png',
        date: dateString,
        blobName: blobName,
      );

      // Upload to Azure
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'x-ms-version': '2021-08-06',
          'x-ms-date': dateString,
          'x-ms-blob-type': 'BlockBlob',
          'Content-Type': 'image/png',
          'Content-Length': fileBytes.length.toString(),
          'Authorization': authHeader,
        },
        body: fileBytes,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      if (response.statusCode == 201) {
        print('File uploaded successfully: $blobName');
        return url;
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading file to Azure: $e');
      return null;
    }
  }

  /// Upload a screenshot and update database
  Future<bool> uploadScreenshot(ScreenshotModel screenshot) async {
    try {
      final file = File(screenshot.localPath);
      if (!await file.exists()) {
        print('Screenshot file not found: ${screenshot.localPath}');
        return false;
      }

      // Generate blob name
      final blobName = 'screenshots/${screenshot.taskId}/${screenshot.id}.png';
      
      // Upload to Azure
      final azureUrl = await uploadFile(file, blobName);
      
      if (azureUrl != null) {
        // Update database with Azure URL
        final updatedScreenshot = screenshot.copyWith(
          azureUrl: azureUrl,
          uploaded: true,
        );
        
        await DatabaseHelper.instance.updateScreenshot(updatedScreenshot);
        print('Screenshot uploaded and database updated');
        return true;
      }

      return false;
    } catch (e) {
      print('Error in uploadScreenshot: $e');
      return false;
    }
  }

  /// Generate Azure Shared Key authorization header
  String _generateAuthorizationHeader({
    required String storageAccount,
    required String accessKey,
    required String method,
    required String url,
    required int contentLength,
    required String contentType,
    required String date,
    required String blobName,
  }) {
    // Create the string to sign
    final canonicalizedHeaders = 'x-ms-blob-type:BlockBlob\n'
        'x-ms-date:$date\n'
        'x-ms-version:2021-08-06';
    
    final canonicalizedResource = '/$storageAccount/${_config.containerName}/$blobName';

    final stringToSign = '$method\n'  // HTTP Verb
        '\n'  // Content-Encoding
        '\n'  // Content-Language
        '$contentLength\n'  // Content-Length
        '\n'  // Content-MD5
        '$contentType\n'  // Content-Type
        '\n'  // Date
        '\n'  // If-Modified-Since
        '\n'  // If-Match
        '\n'  // If-None-Match
        '\n'  // If-Unmodified-Since
        '\n'  // Range
        '$canonicalizedHeaders\n'
        '$canonicalizedResource';

    // Sign the string
    final key = base64.decode(accessKey);
    final hmac = Hmac(sha256, key);
    final signature = base64.encode(hmac.convert(utf8.encode(stringToSign)).bytes);

    return 'SharedKey $storageAccount:$signature';
  }

  /// Test Azure connection
  Future<bool> testConnection() async {
    try {
      if (!_config.isValid()) {
        return false;
      }

      // Try to list blobs in container (HEAD request)
      final url = '${_config.containerUrl}?restype=container&comp=list&maxresults=1';
      final dateString = HttpDate.format(DateTime.now().toUtc());
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-ms-version': '2021-08-06',
          'x-ms-date': dateString,
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      return response.statusCode == 200 || response.statusCode == 404; // 404 means auth worked but container may not exist
    } catch (e) {
      print('Azure connection test failed: $e');
      return false;
    }
  }

  /// Upload pending screenshots in batch
  Future<Map<String, int>> uploadPendingScreenshots() async {
    int successCount = 0;
    int failureCount = 0;

    try {
      final pendingScreenshots = await DatabaseHelper.instance.getScreenshotsToUpload();
      
      for (final screenshot in pendingScreenshots) {
        final success = await uploadScreenshot(screenshot);
        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      }
    } catch (e) {
      print('Error uploading pending screenshots: $e');
    }

    return {
      'success': successCount,
      'failure': failureCount,
    };
  }

  /// Delete a blob from Azure
  Future<bool> deleteBlob(String blobName) async {
    try {
      final url = '${_config.containerUrl}/$blobName';
      final dateString = HttpDate.format(DateTime.now().toUtc());

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'x-ms-version': '2021-08-06',
          'x-ms-date': dateString,
        },
      );

      return response.statusCode == 202;
    } catch (e) {
      print('Error deleting blob: $e');
      return false;
    }
  }
}
