/// Azure Configuration
/// Contains Azure Blob Storage connection and configuration details
/// 
/// IMPORTANT: These values should be loaded from secure storage or environment
/// Never hardcode production credentials in source code

class AzureConfig {
  // Azure Storage Account Details
  // These will be loaded from SharedPreferences/Settings
  String storageAccount;
  String accessKey;
  String containerName;
  
  AzureConfig({
    required this.storageAccount,
    required this.accessKey,
    required this.containerName,
  });
  
  // Generate the storage account URL
  String get storageUrl => 'https://$storageAccount.blob.core.windows.net';
  
  // Generate the container URL
  String get containerUrl => '$storageUrl/$containerName';
  
  // Generate the connection string
  String get connectionString =>
      'DefaultEndpointsProtocol=https;'
      'AccountName=$storageAccount;'
      'AccountKey=$accessKey;'
      'EndpointSuffix=core.windows.net';
  
  // Validate configuration
  bool isValid() {
    return storageAccount.isNotEmpty &&
           accessKey.isNotEmpty &&
           containerName.isNotEmpty;
  }
  
  // Create from Map (for loading from settings)
  factory AzureConfig.fromMap(Map<String, String> map) {
    return AzureConfig(
      storageAccount: map['storageAccount'] ?? '',
      accessKey: map['accessKey'] ?? '',
      containerName: map['containerName'] ?? '',
    );
  }
  
  // Convert to Map (for saving to settings)
  Map<String, String> toMap() {
    return {
      'storageAccount': storageAccount,
      'accessKey': accessKey,
      'containerName': containerName,
    };
  }
  
  // Default/Empty configuration
  factory AzureConfig.empty() {
    return AzureConfig(
      storageAccount: '',
      accessKey: '',
      containerName: 'employee-screenshots',
    );
  }
}
