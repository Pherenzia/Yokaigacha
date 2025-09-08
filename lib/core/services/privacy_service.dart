import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PrivacyService {
  static const String _privacyConsentKey = 'privacy_consent';
  static const String _analyticsConsentKey = 'analytics_consent';
  static const String _crashlyticsConsentKey = 'crashlytics_consent';
  static const String _dataCollectionConsentKey = 'data_collection_consent';
  static const String _privacyPolicyVersionKey = 'privacy_policy_version';
  
  // Current privacy policy version - increment when policy changes
  static const String _currentPrivacyPolicyVersion = '1.0.0';

  // Privacy consent status
  static bool _privacyConsentGiven = false;
  static bool _analyticsConsentGiven = false;
  static bool _crashlyticsConsentGiven = false;
  static bool _dataCollectionConsentGiven = false;

  /// Initialize privacy service and check consent status
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    _privacyConsentGiven = prefs.getBool(_privacyConsentKey) ?? false;
    _analyticsConsentGiven = prefs.getBool(_analyticsConsentKey) ?? false;
    _crashlyticsConsentGiven = prefs.getBool(_crashlyticsConsentKey) ?? false;
    _dataCollectionConsentGiven = prefs.getBool(_dataCollectionConsentKey) ?? false;
    
    // Check if privacy policy version has changed
    final lastVersion = prefs.getString(_privacyPolicyVersionKey);
    if (lastVersion != _currentPrivacyPolicyVersion) {
      // Reset all consents if policy version changed
      await resetAllConsents();
      await prefs.setString(_privacyPolicyVersionKey, _currentPrivacyPolicyVersion);
    }
  }

  /// Check if user has given privacy consent
  static bool get hasPrivacyConsent => _privacyConsentGiven;

  /// Check if user has given analytics consent
  static bool get hasAnalyticsConsent => _analyticsConsentGiven;

  /// Check if user has given crashlytics consent
  static bool get hasCrashlyticsConsent => _crashlyticsConsentGiven;

  /// Check if user has given data collection consent
  static bool get hasDataCollectionConsent => _dataCollectionConsentGiven;

  /// Set privacy consent
  static Future<void> setPrivacyConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyConsentKey, consent);
    _privacyConsentGiven = consent;
  }

  /// Set analytics consent
  static Future<void> setAnalyticsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsConsentKey, consent);
    _analyticsConsentGiven = consent;
  }

  /// Set crashlytics consent
  static Future<void> setCrashlyticsConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crashlyticsConsentKey, consent);
    _crashlyticsConsentGiven = consent;
  }

  /// Set data collection consent
  static Future<void> setDataCollectionConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataCollectionConsentKey, consent);
    _dataCollectionConsentGiven = consent;
  }

  /// Reset all consents
  static Future<void> resetAllConsents() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_privacyConsentKey);
    await prefs.remove(_analyticsConsentKey);
    await prefs.remove(_crashlyticsConsentKey);
    await prefs.remove(_dataCollectionConsentKey);
    
    _privacyConsentGiven = false;
    _analyticsConsentGiven = false;
    _crashlyticsConsentGiven = false;
    _dataCollectionConsentGiven = false;
  }

  /// Get user's data export (for GDPR compliance)
  static Future<Map<String, dynamic>?> exportUserData() async {
    if (!_dataCollectionConsentGiven) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    final userData = <String, dynamic>{};
    
    for (final key in allKeys) {
      // Skip privacy-related keys
      if (key.startsWith('privacy_') || key.startsWith('analytics_') || key.startsWith('crashlytics_')) {
        continue;
      }
      
      final value = prefs.get(key);
      if (value != null) {
        userData[key] = value;
      }
    }
    
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'privacyPolicyVersion': _currentPrivacyPolicyVersion,
      'userData': userData,
    };
  }

  /// Delete all user data (for GDPR compliance)
  static Future<void> deleteAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    for (final key in allKeys) {
      // Keep privacy consent settings
      if (!key.startsWith('privacy_') && !key.startsWith('analytics_') && !key.startsWith('crashlytics_')) {
        await prefs.remove(key);
      }
    }
  }

  /// Log analytics event (only if consent given)
  static void logAnalyticsEvent(String eventName, Map<String, dynamic>? parameters) {
    if (!_analyticsConsentGiven) {
      return;
    }
    
    if (kDebugMode) {
      print('Analytics Event: $eventName');
      if (parameters != null) {
        print('Parameters: $parameters');
      }
    }
    
    // TODO: Implement actual analytics logging
    // This would integrate with Firebase Analytics or similar service
  }

  /// Log crash (only if consent given)
  static void logCrash(String error, StackTrace? stackTrace) {
    if (!_crashlyticsConsentGiven) {
      return;
    }
    
    if (kDebugMode) {
      print('Crash: $error');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
    }
    
    // TODO: Implement actual crash reporting
    // This would integrate with Firebase Crashlytics or similar service
  }

  /// Get privacy policy text
  static String getPrivacyPolicyText() {
    return '''
Super Auto Pets Clone - Privacy Policy

Last Updated: ${DateTime.now().toIso8601String().split('T')[0]}

1. Data Collection
We collect minimal data necessary for game functionality:
- Game progress and statistics
- Device information for compatibility
- Crash reports (with your consent)

2. Data Usage
Your data is used to:
- Save your game progress
- Improve game performance
- Provide customer support

3. Data Storage
All data is stored locally on your device. We do not transmit personal data to external servers without your explicit consent.

4. Your Rights
You have the right to:
- Export your data
- Delete your data
- Withdraw consent at any time

5. Contact
For privacy-related questions, contact us at privacy@superautopetsclone.com

By using this app, you agree to this privacy policy.
''';
  }

  /// Get terms of service text
  static String getTermsOfServiceText() {
    return '''
Super Auto Pets Clone - Terms of Service

Last Updated: ${DateTime.now().toIso8601String().split('T')[0]}

1. Acceptance of Terms
By using this app, you agree to these terms.

2. Game Content
This is a fan-made clone for educational purposes. All original game concepts belong to their respective owners.

3. User Conduct
You agree to:
- Use the app responsibly
- Not attempt to reverse engineer the app
- Not use the app for illegal purposes

4. Limitation of Liability
The app is provided "as is" without warranties.

5. Contact
For questions, contact us at support@superautopetsclone.com
''';
  }
}

