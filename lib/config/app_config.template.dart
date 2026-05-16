/// Template configuration file for the Student Support System
/// 
/// IMPORTANT: Do NOT commit app_config.dart with your actual API key!
/// 
/// Setup Instructions:
/// 1. Copy this file and rename it to 'app_config.dart'
/// 2. Get a FREE Groq API key from: https://console.groq.com
/// 3. Replace 'YOUR_GROQ_API_KEY_HERE' with your actual API key
/// 4. The key should start with 'gsk_'
/// 5. Never commit your actual app_config.dart file to git

class AppConfig {
  // TODO: Add your Groq API key here
  // Get your FREE API key from: https://console.groq.com
  // Example: static const String groqApiKey = 'gsk_your_api_key_here';
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  
  // Groq API endpoint
  static const String groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Model selection - Llama 3 70B for best quality
  static const String groqModel = 'llama-3.1-70b-versatile';
  
  // API timeout in seconds
  static const int apiTimeout = 30;
  
  // Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 2;
  
  // Rate limiting - minimum time between requests (milliseconds)
  static const int minRequestInterval = 1000;

  /// Check if API key is properly configured
  static bool get isConfigured {
    return groqApiKey.isNotEmpty && 
           groqApiKey != 'YOUR_GROQ_API_KEY_HERE' &&
           groqApiKey.startsWith('gsk_');
  }

  /// Get configuration error message
  static String get configurationError {
    if (groqApiKey.isEmpty || groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
      return 'Groq API key not configured. Please add your API key in app_config.dart';
    }
    if (!groqApiKey.startsWith('gsk_')) {
      return 'Invalid Groq API key format. Key should start with "gsk_"';
    }
    return 'Configuration error';
  }
}
