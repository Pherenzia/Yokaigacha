import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/privacy_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _privacyConsent = false;
  bool _analyticsConsent = false;
  bool _crashlyticsConsent = false;
  bool _dataCollectionConsent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    setState(() {
      _isLoading = true;
    });

    await PrivacyService.initialize();
    
    setState(() {
      _privacyConsent = PrivacyService.hasPrivacyConsent;
      _analyticsConsent = PrivacyService.hasAnalyticsConsent;
      _crashlyticsConsent = PrivacyService.hasCrashlyticsConsent;
      _dataCollectionConsent = PrivacyService.hasDataCollectionConsent;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildConsentSection(),
                  const SizedBox(height: 24),
                  _buildDataManagementSection(),
                  const SizedBox(height: 24),
                  _buildLegalSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.privacy_tip,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Privacy & Data Protection',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We respect your privacy and give you control over your data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Collection Consent',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildConsentSwitch(
              title: 'Privacy Policy Consent',
              subtitle: 'I agree to the privacy policy and terms of service',
              value: _privacyConsent,
              onChanged: (value) {
                setState(() {
                  _privacyConsent = value;
                });
                PrivacyService.setPrivacyConsent(value);
              },
            ),
            const SizedBox(height: 16),
            _buildConsentSwitch(
              title: 'Analytics Data',
              subtitle: 'Help improve the app by sharing anonymous usage data',
              value: _analyticsConsent,
              onChanged: (value) {
                setState(() {
                  _analyticsConsent = value;
                });
                PrivacyService.setAnalyticsConsent(value);
              },
            ),
            const SizedBox(height: 16),
            _buildConsentSwitch(
              title: 'Crash Reports',
              subtitle: 'Send crash reports to help fix bugs',
              value: _crashlyticsConsent,
              onChanged: (value) {
                setState(() {
                  _crashlyticsConsent = value;
                });
                PrivacyService.setCrashlyticsConsent(value);
              },
            ),
            const SizedBox(height: 16),
            _buildConsentSwitch(
              title: 'Data Collection',
              subtitle: 'Allow collection of game data for features',
              value: _dataCollectionConsent,
              onChanged: (value) {
                setState(() {
                  _dataCollectionConsent = value;
                });
                PrivacyService.setDataCollectionConsent(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDataActionButton(
              title: 'Export My Data',
              subtitle: 'Download a copy of your game data',
              icon: Icons.download,
              color: AppTheme.primaryColor,
              onTap: _exportUserData,
            ),
            const SizedBox(height: 12),
            _buildDataActionButton(
              title: 'Delete All Data',
              subtitle: 'Permanently delete all your game data',
              icon: Icons.delete_forever,
              color: AppTheme.errorColor,
              onTap: _deleteAllData,
            ),
            const SizedBox(height: 12),
            _buildDataActionButton(
              title: 'Reset Privacy Settings',
              subtitle: 'Reset all privacy consent settings',
              icon: Icons.refresh,
              color: AppTheme.warningColor,
              onTap: _resetPrivacySettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legal Documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildLegalButton(
              title: 'Privacy Policy',
              onTap: () => _showDocument('Privacy Policy', PrivacyService.getPrivacyPolicyText()),
            ),
            const SizedBox(height: 12),
            _buildLegalButton(
              title: 'Terms of Service',
              onTap: () => _showDocument('Terms of Service', PrivacyService.getTermsOfServiceText()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.description, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.secondaryTextColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUserData() async {
    try {
      final data = await PrivacyService.exportUserData();
      if (data != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Data Export'),
              content: const Text('Your data has been exported successfully. You can find it in the app\'s data directory.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data collection consent required to export data.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your game data. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PrivacyService.deleteAllUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data has been deleted successfully.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete data: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _resetPrivacySettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text(
          'This will reset all your privacy consent settings. You will need to provide consent again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PrivacyService.resetAllConsents();
        await _loadConsentStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy settings have been reset.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reset settings: $e'),
            ),
          );
        }
      }
    }
  }

  void _showDocument(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

