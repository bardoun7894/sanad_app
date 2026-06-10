import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/system_settings_provider.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/revenue_split.dart';
import '../../../core/utils/version_compare.dart';
import '../services/admin_chat_service.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _isLoading = false;
  bool _maintenanceMode = false;
  bool _paymentTestMode = false;
  bool _paypalEnabled = true;
  bool _googlePayEnabled = false;
  String _minAppVersion = '1.0.0';
  String _contactEmail = 'support@sanad.sa';
  String _currentPublishedVersion = '';

  // Landing-page hero media (uploaded to Firebase Storage `landing/`).
  String _heroVideoUrl = '';
  String _heroPosterUrl = '';
  bool _heroVideoUploading = false;
  bool _heroPosterUploading = false;
  double _heroUploadProgress = 0;

  // API Key controllers
  final _geminiController = TextEditingController();
  final _zegoAppIdController = TextEditingController();
  final _zegoAppSignController = TextEditingController();
  final _zegoTokenController = TextEditingController();
  final _fcmVapidController = TextEditingController();
  final _paypalClientIdController = TextEditingController();
  final _paypalSecretController = TextEditingController();
  final _freemiusSecretKeyController = TextEditingController();
  final _freemiusBearerTokenController = TextEditingController();
  final _freemiusProductIdController = TextEditingController();

  bool _apiKeysLoading = false;
  bool _apiKeysDirty = false;

  // Track which fields have their values revealed
  final Set<String> _revealedFields = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadApiKeys();
    _loadPackageVersion();
  }

  Future<void> _loadPackageVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final raw = info.version; // e.g. "1.0.0+17" or "1.0.0"
      final plusIdx = raw.indexOf('+');
      final stripped = plusIdx != -1 ? raw.substring(0, plusIdx) : raw;
      if (mounted) setState(() => _currentPublishedVersion = stripped);
    } catch (_) {
      // Non-fatal — leave _currentPublishedVersion empty.
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _zegoAppIdController.dispose();
    _zegoAppSignController.dispose();
    _zegoTokenController.dispose();
    _fcmVapidController.dispose();
    _paypalClientIdController.dispose();
    _paypalSecretController.dispose();
    _freemiusSecretKeyController.dispose();
    _freemiusBearerTokenController.dispose();
    _freemiusProductIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('config')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _maintenanceMode = data['maintenance_mode'] ?? false;
          _paymentTestMode = data['payment_test_mode'] ?? false;
          _paypalEnabled = data['payment_paypal_enabled'] ?? true;
          _googlePayEnabled = data['payment_google_pay_enabled'] ?? false;
          _minAppVersion = data['min_app_version'] ?? '1.0.0';
          _contactEmail = data['contact_email'] ?? 'support@sanad.sa';
          _heroVideoUrl = data['landing_hero_video_url'] ?? '';
          _heroPosterUrl = data['landing_hero_poster_url'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        final s = S(ref.read(languageProvider).language);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.settingsLoadFailed),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadApiKeys() async {
    setState(() => _apiKeysLoading = true);
    try {
      // Load sensitive keys from api_keys (admin-only)
      final apiDoc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('api_keys')
          .get();

      if (apiDoc.exists && apiDoc.data() != null) {
        final data = apiDoc.data()!;
        _geminiController.text = data['gemini_api_key'] as String? ?? '';
        _paypalClientIdController.text =
            data['paypal_client_id'] as String? ?? '';
        _paypalSecretController.text = data['paypal_secret'] as String? ?? '';
        _freemiusSecretKeyController.text =
            data['freemius_secret_key'] as String? ?? '';
        _freemiusBearerTokenController.text =
            data['freemius_bearer_token'] as String? ?? '';
        _freemiusProductIdController.text =
            data['freemius_product_id'] as String? ?? '';
      }

      // Load client-side keys from client_config
      final clientDoc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('client_config')
          .get();

      if (clientDoc.exists && clientDoc.data() != null) {
        final data = clientDoc.data()!;
        _zegoAppIdController.text = (data['zego_app_id']?.toString()) ?? '';
        _zegoAppSignController.text = data['zego_app_sign'] as String? ?? '';
        _zegoTokenController.text = data['zego_token'] as String? ?? '';
        _fcmVapidController.text = data['fcm_vapid_key'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Error loading API keys: $e');
    } finally {
      if (mounted)
        setState(() {
          _apiKeysLoading = false;
          _apiKeysDirty = false;
        });
    }
  }

  Future<void> _saveApiKeys() async {
    setState(() => _apiKeysLoading = true);
    final s = S(ref.read(languageProvider).language);

    try {
      final keys = <String, String>{};
      if (_geminiController.text.isNotEmpty) {
        keys['gemini_api_key'] = _geminiController.text.trim();
      }
      if (_zegoAppIdController.text.isNotEmpty) {
        keys['zego_app_id'] = _zegoAppIdController.text.trim();
      }
      if (_zegoAppSignController.text.isNotEmpty) {
        keys['zego_app_sign'] = _zegoAppSignController.text.trim();
      }
      if (_zegoTokenController.text.isNotEmpty) {
        keys['zego_token'] = _zegoTokenController.text.trim();
      }
      if (_fcmVapidController.text.isNotEmpty) {
        keys['fcm_vapid_key'] = _fcmVapidController.text.trim();
      }
      if (_paypalClientIdController.text.isNotEmpty) {
        keys['paypal_client_id'] = _paypalClientIdController.text.trim();
      }
      if (_paypalSecretController.text.isNotEmpty) {
        keys['paypal_secret'] = _paypalSecretController.text.trim();
      }
      if (_freemiusSecretKeyController.text.isNotEmpty) {
        keys['freemius_secret_key'] = _freemiusSecretKeyController.text.trim();
      }
      if (_freemiusBearerTokenController.text.isNotEmpty) {
        keys['freemius_bearer_token'] =
            _freemiusBearerTokenController.text.trim();
      }
      if (_freemiusProductIdController.text.isNotEmpty) {
        keys['freemius_product_id'] = _freemiusProductIdController.text.trim();
      }

      await AppConfig.saveAllKeys(keys);

      if (mounted) {
        setState(() => _apiKeysDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.apiKeysSaved),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.apiKeysError}: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _apiKeysLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('config')
          .set({key: value}, SetOptions(merge: true));
      if (mounted) {
        final s = S(ref.read(languageProvider).language);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.settingSavedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        final s = S(ref.read(languageProvider).language);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text(s.settingsSaveFailed),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markDirty() {
    if (!_apiKeysDirty) setState(() => _apiKeysDirty = true);
  }

  // ── Revenue Split ──────────────────────────────────────────────────────
  Widget _buildRevenueSplitTile(SystemSettings settings, Color textColor) {
    String pct(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}%';
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.pie_chart_outline_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.adminRevenueSplit,
                    style: AppTypography.labelLarge.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppStrings.adminTherapistShare}: ${pct(settings.revenueTherapistPct)}   •   '
                    '${AppStrings.adminAppCut}: ${pct(settings.revenueAppPct)}   •   '
                    '${AppStrings.adminMaintenanceShare}: ${pct(settings.revenueMaintenancePct)}',
                    style: AppTypography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editRevenueSplit(settings),
              icon: Icon(Icons.edit_outlined,
                  color: textColor.withValues(alpha: 0.7), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRevenueSplit(SystemSettings settings) async {
    final therapistCtrl = TextEditingController(
        text: settings.revenueTherapistPct.toString());
    final appCtrl =
        TextEditingController(text: settings.revenueAppPct.toString());
    final maintCtrl = TextEditingController(
        text: settings.revenueMaintenancePct.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget field(String label, TextEditingController c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: c,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text(AppStrings.adminRevenueSplit),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field(AppStrings.adminTherapistPct, therapistCtrl),
                  field(AppStrings.adminAppPct, appCtrl),
                  field(AppStrings.adminMaintenancePct, maintCtrl),
                  if (errorText != null)
                    Text(errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () {
                    final t = double.tryParse(therapistCtrl.text.trim());
                    final a = double.tryParse(appCtrl.text.trim());
                    final m = double.tryParse(maintCtrl.text.trim());
                    if (t == null ||
                        a == null ||
                        m == null ||
                        !RevenueSplit.sumsTo100(t, a, m)) {
                      setLocal(() =>
                          errorText = AppStrings.adminPercentMustTotal100);
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(AppStrings.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final t = double.parse(therapistCtrl.text.trim());
      final a = double.parse(appCtrl.text.trim());
      final m = double.parse(maintCtrl.text.trim());
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('config')
          .set({
        'revenue_therapist_pct': t,
        'revenue_app_pct': a,
        'revenue_maintenance_pct': m,
      }, SetOptions(merge: true));
      if (mounted) {
        final s = S(ref.read(languageProvider).language);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.settingSavedSuccess)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final s = S(ref.watch(languageProvider).language);
    final isMobile = AdminResponsive.isMobile(context);
    final pagePadding = AdminResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: pagePadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.systemSettings,
                        style: AppTypography.headingMedium.copyWith(
                          color: textColor,
                          fontSize: isMobile ? 22 : null,
                        ),
                      ),
                      Text(
                        s.manageGlobalConfig,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading || _apiKeysLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: pagePadding,
              children: [
                // ── App Gates (most destructive — top of screen) ──────────
                _buildAppGatesSection(s, textColor),

                const SizedBox(height: 32),

                _buildSectionTitle(s.appConfiguration, textColor),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final settingsAsync = ref.watch(systemSettingsProvider);
                    return settingsAsync.when(
                      data: (settings) => _buildSwitchTile(
                        title: s.therapistApplications,
                        subtitle: s.therapistApplicationsDesc,
                        value: settings.enableTherapistApplication,
                        icon: Icons.person_add_alt_1_rounded,
                        color: AppColors.primary,
                        textColor: textColor,
                        onChanged: (val) {
                          ref
                              .read(systemSettingsProvider.notifier)
                              .updateSetting(
                                'enable_therapist_application',
                                val,
                              );
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
                _buildTextSetting(
                  title: s.supportEmailSetting,
                  subtitle: s.supportEmailDesc,
                  value: _contactEmail,
                  icon: Icons.email_outlined,
                  textColor: textColor,
                  onEdit: () => _editStringSetting(
                    s.supportEmailSetting,
                    'contact_email',
                    _contactEmail,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Landing Hero Section ──
                _buildLandingHeroSection(textColor),

                const SizedBox(height: 32),

                // ── Revenue Split Section ──
                _buildSectionTitle(AppStrings.adminRevenueSplit, textColor),
                const SizedBox(height: 4),
                Text(
                  AppStrings.adminRevenueSplitDesc,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final settingsAsync = ref.watch(systemSettingsProvider);
                    return settingsAsync.when(
                      data: (settings) =>
                          _buildRevenueSplitTile(settings, textColor),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // ── API Keys Section ──
                _buildSectionTitle(s.apiKeysTitle, textColor),
                const SizedBox(height: 4),
                Text(
                  s.apiKeysSubtitle,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                _buildApiKeyField(
                  label: s.geminiApiKey,
                  description: s.geminiApiKeyDesc,
                  controller: _geminiController,
                  fieldId: 'gemini',
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFF4285F4),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.zegoAppId,
                  description: s.zegoAppIdDesc,
                  controller: _zegoAppIdController,
                  fieldId: 'zego_id',
                  icon: Icons.videocam_rounded,
                  iconColor: const Color(0xFF0055FF),
                  textColor: textColor,
                  isNumeric: true,
                ),
                _buildApiKeyField(
                  label: s.zegoAppSign,
                  description: s.zegoAppSignDesc,
                  controller: _zegoAppSignController,
                  fieldId: 'zego_sign',
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF0055FF),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.zegoToken,
                  description: s.zegoTokenDesc,
                  controller: _zegoTokenController,
                  fieldId: 'zego_token',
                  icon: Icons.token_rounded,
                  iconColor: const Color(0xFF0055FF),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.fcmVapidKey,
                  description: s.fcmVapidKeyDesc,
                  controller: _fcmVapidController,
                  fieldId: 'fcm_vapid',
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFFFFA000),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.paypalClientId,
                  description: s.paypalClientIdDesc,
                  controller: _paypalClientIdController,
                  fieldId: 'paypal_client_id',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF003087),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.paypalSecret,
                  description: s.paypalSecretDesc,
                  controller: _paypalSecretController,
                  fieldId: 'paypal_secret',
                  icon: Icons.key_rounded,
                  iconColor: const Color(0xFF003087),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.freemiusSecretKey,
                  description: s.freemiusSecretKeyDesc,
                  controller: _freemiusSecretKeyController,
                  fieldId: 'freemius_secret_key',
                  icon: Icons.key_rounded,
                  iconColor: const Color(0xFF8A4FFF),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.freemiusBearerToken,
                  description: s.freemiusBearerTokenDesc,
                  controller: _freemiusBearerTokenController,
                  fieldId: 'freemius_bearer_token',
                  icon: Icons.token_rounded,
                  iconColor: const Color(0xFF8A4FFF),
                  textColor: textColor,
                ),
                _buildApiKeyField(
                  label: s.freemiusProductId,
                  description: s.freemiusProductIdDesc,
                  controller: _freemiusProductIdController,
                  fieldId: 'freemius_product_id',
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF8A4FFF),
                  textColor: textColor,
                  isNumeric: true,
                ),

                const SizedBox(height: 16),

                // Save button
                AnimatedOpacity(
                  opacity: _apiKeysDirty ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _apiKeysDirty && !_apiKeysLoading
                            ? _saveApiKeys
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_apiKeysLoading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.save_rounded,
                                  color: _apiKeysDirty
                                      ? AppColors.primary
                                      : textColor.withValues(alpha: 0.3),
                                  size: 20,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                s.saveAllKeys,
                                style: TextStyle(
                                  color: _apiKeysDirty
                                      ? AppColors.primary
                                      : textColor.withValues(alpha: 0.3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App Gates section ─────────────────────────────────────────────────

  Widget _buildAppGatesSection(S s, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(s.appGatesSectionTitle, textColor),
        const SizedBox(height: 6),
        Text(
          s.appGatesSectionWarning,
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Maintenance toggle
        _buildSwitchTile(
          title: s.maintenanceMode,
          subtitle: s.maintenanceModeDesc,
          value: _maintenanceMode,
          icon: Icons.construction_rounded,
          color: Colors.orange,
          textColor: textColor,
          onChanged: (val) async {
            if (val) {
              // Turning ON maintenance: require explicit confirmation.
              if (!mounted) return;
              final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: Text(s.maintenanceEnableConfirmTitle),
                  content: Text(s.maintenanceEnableConfirmBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.confirm),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
            } else {
              // Turning OFF maintenance: offer to notify users.
              if (!mounted) return;
              final notify = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.maintenanceEndedTitle),
                  content: Text(s.notifyAllOnMaintenanceEnd),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.yes),
                    ),
                  ],
                ),
              );
              if (notify == true) {
                try {
                  await FirebaseFirestore.instance
                      .collection('system_settings')
                      .doc('config')
                      .set({
                    'maintenance_notify_pending': true,
                  }, SetOptions(merge: true));
                } catch (e) {
                  debugPrint('Failed to set notify flag: $e');
                }
              }
            }
            if (!mounted) return;
            setState(() => _maintenanceMode = val);
            await _saveSetting('maintenance_mode', val);
          },
        ),

        // Min app version tile
        _buildTextSetting(
          title: s.minimumAppVersion,
          subtitle: s.minimumAppVersionDesc,
          value: _minAppVersion,
          icon: Icons.mobile_friendly_rounded,
          textColor: textColor,
          onEdit: () => _editMinAppVersion(s),
        ),

        // Payment test-mode toggle — routes card (Freemius) checkout to the
        // sandbox so the live gateway can be verified without real charges.
        _buildSwitchTile(
          title: s.paymentTestMode,
          subtitle: s.paymentTestModeDesc,
          value: _paymentTestMode,
          icon: Icons.science_rounded,
          color: Colors.deepPurple,
          textColor: textColor,
          onChanged: (val) async {
            if (val) {
              // Turning ON test mode disables real charges for everyone —
              // require explicit confirmation.
              if (!mounted) return;
              final confirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: Text(s.paymentTestEnableConfirmTitle),
                  content: Text(s.paymentTestEnableConfirmBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.confirm),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
            }
            if (!mounted) return;
            setState(() => _paymentTestMode = val);
            await _saveSetting('payment_test_mode', val);
          },
        ),

        // PayPal visibility toggle — show/hide the PayPal option in the app's
        // payment-method screen without an app release.
        _buildSwitchTile(
          title: s.paypalVisibility,
          subtitle: s.paypalVisibilityDesc,
          value: _paypalEnabled,
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFF003087),
          textColor: textColor,
          onChanged: (val) async {
            setState(() => _paypalEnabled = val);
            await _saveSetting('payment_paypal_enabled', val);
          },
        ),

        // Google Pay / Apple Pay visibility toggle — show/hide the native
        // wallet option in the app's payment-method screen without an app
        // release. Off by default.
        _buildSwitchTile(
          title: s.googlePayVisibility,
          subtitle: s.googlePayVisibilityDesc,
          value: _googlePayEnabled,
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF4285F4),
          textColor: textColor,
          onChanged: (val) async {
            setState(() => _googlePayEnabled = val);
            await _saveSetting('payment_google_pay_enabled', val);
          },
        ),
      ],
    );
  }

  // ── Min App Version editor (Fix #1) ───────────────────────────────────

  Future<void> _editMinAppVersion(S s) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: _minAppVersion);
    final semverRe = RegExp(r'^\d+\.\d+\.\d+$');

    final newVersion = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCurve,
        title: Text(s.minimumAppVersion),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentPublishedVersion.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${s.currentPublishedVersion}: $_currentPublishedVersion',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: s.minimumAppVersion,
                  hintText: '1.2.3',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || !semverRe.hasMatch(v.trim())) {
                    return s.minVersionInvalid;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newVersion == null || newVersion == _minAppVersion) return;

    // Determine if this is a version bump past current published version.
    // Only bump past current published requires a confirm dialog.
    final needsConfirm = _currentPublishedVersion.isNotEmpty &&
        compareSemver(newVersion, _currentPublishedVersion) > 0;

    if (needsConfirm) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(s.minVersionConfirmTitle),
          content: Text(s.minVersionConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.confirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    setState(() => _minAppVersion = newVersion);
    await _saveSetting('min_app_version', newVersion);

    // Offer to push a "new update available" notification to all users.
    // The force-update gate enforces the version on next launch; this
    // broadcast actively tells users an update is waiting.
    if (!mounted) return;
    final notify = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.notifyUpdateTitle),
        content: Text(s.notifyUpdatePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    if (notify != true) return;
    try {
      await AdminChatService().broadcastNotificationToAllUsers(
        title: s.notifyUpdateTitle,
        body: s.notifyUpdateBody,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.notifyUpdateSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.error}: $e')),
      );
    }
  }

  // ── Builders ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: textColor.withValues(alpha: 0.4),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSetting({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color textColor,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: ListTile(
          onTap: onEdit,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.edit_outlined,
            color: textColor.withValues(alpha: 0.2),
            size: 18,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required String description,
    required TextEditingController controller,
    required String fieldId,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    bool isNumeric = false,
  }) {
    final s = S(ref.watch(languageProvider).language);
    final isRevealed = _revealedFields.contains(fieldId);
    final hasValue = controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + label + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hasValue
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasValue ? s.apiKeyConfigured : s.apiKeyNotConfigured,
                    style: TextStyle(
                      color: hasValue
                          ? Colors.green.shade400
                          : Colors.orange.shade400,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: !isRevealed && !isNumeric,
                    onChanged: (_) => _markDirty(),
                    keyboardType: isNumeric
                        ? TextInputType.number
                        : TextInputType.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      letterSpacing: isRevealed || isNumeric ? 0 : 2,
                    ),
                    decoration: InputDecoration(
                      hintText: isNumeric ? '0' : 'sk-...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.2),
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      filled: true,
                      fillColor: textColor.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: textColor.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: textColor.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: iconColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isNumeric) ...[
                  const SizedBox(width: 8),
                  // Reveal/hide toggle
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (isRevealed) {
                            _revealedFields.remove(fieldId);
                          } else {
                            _revealedFields.add(fieldId);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: textColor.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          isRevealed
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          size: 18,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Landing-page hero media upload ──────────────────────────────────────
  Future<void> _pickAndUploadHero({required bool isVideo}) async {
    setState(() {
      if (isVideo) {
        _heroVideoUploading = true;
      } else {
        _heroPosterUploading = true;
      }
      _heroUploadProgress = 0;
    });
    try {
      final picker = ImagePicker();
      final XFile? picked = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              imageQuality: 85,
            );
      if (picked == null) {
        if (mounted) {
          setState(() {
            _heroVideoUploading = false;
            _heroPosterUploading = false;
          });
        }
        return;
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : (isVideo ? 'mp4' : 'jpg');
      final kind = isVideo ? 'video' : 'poster';
      final contentType = isVideo ? 'video/$ext' : 'image/$ext';
      final ref = FirebaseStorage.instance.ref('landing/hero_${kind}_$ts.$ext');
      final bytes = await picked.readAsBytes();
      final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
      task.snapshotEvents.listen((s) {
        if (!mounted) return;
        if (s.totalBytes > 0) {
          setState(() => _heroUploadProgress = s.bytesTransferred / s.totalBytes);
        }
      });
      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        if (isVideo) {
          _heroVideoUrl = url;
          _heroVideoUploading = false;
        } else {
          _heroPosterUrl = url;
          _heroPosterUploading = false;
        }
        _heroUploadProgress = 0;
      });
      await _saveSetting(
        isVideo ? 'landing_hero_video_url' : 'landing_hero_poster_url',
        url,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _heroVideoUploading = false;
        _heroPosterUploading = false;
      });
      final s = S(ref.read(languageProvider).language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.settingsSaveFailed}: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _clearHero({required bool isVideo}) async {
    setState(() {
      if (isVideo) {
        _heroVideoUrl = '';
      } else {
        _heroPosterUrl = '';
      }
    });
    await _saveSetting(
      isVideo ? 'landing_hero_video_url' : 'landing_hero_poster_url',
      '',
    );
  }

  Widget _buildLandingHeroSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('فيديو الصفحة الرئيسية · Landing Hero', textColor),
        const SizedBox(height: 4),
        Text(
          'الفيديو الذي يظهر في خلفية أعلى الموقع (sanadtherapy.com). '
          'إذا لم يُرفع فيديو يظهر تصميم متدرّج بدلاً منه.',
          style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12),
        ),
        const SizedBox(height: 16),
        _buildHeroMediaTile(
          label: 'فيديو الخلفية (Hero video)',
          url: _heroVideoUrl,
          uploading: _heroVideoUploading,
          isVideo: true,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        _buildHeroMediaTile(
          label: 'صورة الغلاف (Poster — اختياري)',
          url: _heroPosterUrl,
          uploading: _heroPosterUploading,
          isVideo: false,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildHeroMediaTile({
    required String label,
    required String url,
    required bool uploading,
    required bool isVideo,
    required Color textColor,
  }) {
    final hasMedia = url.startsWith('http');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVideo ? Icons.movie_creation_rounded : Icons.image_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                ),
              ),
              if (hasMedia)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'مرفوع',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ),
            ],
          ),
          if (hasMedia) ...[
            const SizedBox(height: 8),
            Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: uploading ? null : () => _pickAndUploadHero(isVideo: isVideo),
                icon: uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(hasMedia ? Icons.refresh_rounded : Icons.upload_rounded, size: 18),
                label: Text(uploading ? 'جارٍ الرفع…' : (hasMedia ? 'استبدال' : 'رفع')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              if (hasMedia && !uploading) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _clearHero(isVideo: isVideo),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  label: const Text('حذف', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ],
          ),
          if (uploading && _heroUploadProgress > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _heroUploadProgress, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Future<void> _editStringSetting(
    String title,
    String dbKey,
    String currentValue,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final s = S(ref.read(languageProvider).language);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCurve,
        title: Text('${s.editTitle} $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(s.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentValue) {
      if (dbKey == 'contact_email') {
        setState(() => _contactEmail = result);
      }
      _saveSetting(dbKey, result);
    }
  }
}
