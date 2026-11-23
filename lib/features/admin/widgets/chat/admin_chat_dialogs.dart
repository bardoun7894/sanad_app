import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/admin_chat_service.dart';
import '../admin_bento_ui.dart';

/// Bilingual 2026 Bento dialog to search any patient and start a support chat.
class AdminNewChatDialog extends ConsumerStatefulWidget {
  final void Function(ChatThread thread) onSelectThread;

  const AdminNewChatDialog({super.key, required this.onSelectThread});

  @override
  ConsumerState<AdminNewChatDialog> createState() => _AdminNewChatDialogState();
}

class _AdminNewChatDialogState extends ConsumerState<AdminNewChatDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _error = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final results = await AdminChatService().searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  void _startChat(Map<String, dynamic> user) {
    final thread = ChatThread(
      userId: user['uid'] as String,
      userEmail: user['email'] as String? ?? 'Unknown',
      userName: user['name'] as String? ?? '',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    );
    Navigator.of(context).pop();
    widget.onSelectThread(thread);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = ref.watch(languageProvider).language == AppLanguage.arabic;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.add_comment_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isAr ? 'محادثة جديدة' : 'New Conversation',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AdminBento.textPrimary(isDark),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isAr
                    ? 'ابحث بالاسم أو البريد أو الهاتف...'
                    : 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AdminBento.border(isDark)),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final email = user['email'] as String? ?? '';
                    final name = user['name'] as String? ?? email;
                    final phone = user['phone'] as String? ?? '';
                    final avatarUrl = user['avatar_url'] as String?;
                    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.14,
                        ),
                        backgroundImage: hasAvatar
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: !hasAvatar
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        phone.isNotEmpty ? '$email • $phone' : email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminBento.textSecondary(isDark),
                        ),
                      ),
                      onTap: () => _startChat(user),
                    );
                  },
                ),
              )
            else if (_searchController.text.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isAr ? 'لم يتم العثور على مستخدمين' : 'No users found',
                  style: TextStyle(color: AdminBento.textSecondary(isDark)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
      ],
    );
  }
}

/// Bilingual 2026 Bento dialog to broadcast a support message to all users.
class AdminBroadcastChatDialog extends ConsumerStatefulWidget {
  const AdminBroadcastChatDialog({super.key});

  @override
  ConsumerState<AdminBroadcastChatDialog> createState() =>
      _AdminBroadcastChatDialogState();
}

class _AdminBroadcastChatDialogState
    extends ConsumerState<AdminBroadcastChatDialog> {
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _isSuccess = false;
  String? _result;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast(bool isAr) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _isSuccess = false;
        _result = isAr ? 'الرجاء كتابة رسالة' : 'Please enter a message';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _result = null;
    });

    try {
      final report = await AdminChatService().broadcastMessageWithReport(
        message,
      );
      if (mounted) {
        setState(() {
          _isSending = false;
          _isSuccess = report.isSuccess;
          _result = report.isSuccess
              ? (isAr
                    ? 'تم إرسال الرسالة إلى ${report.sentCount} مستخدم.'
                    : 'Message sent to ${report.sentCount} users.')
              : (isAr
                    ? 'تم الإرسال: ${report.sentCount} • فشل: ${report.failedCount}'
                    : 'Sent: ${report.sentCount}, Failed: ${report.failedCount}');
        });
        if (report.isSuccess) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isSuccess = false;
          _result = isAr ? 'خطأ: $e' : 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = ref.watch(languageProvider).language == AppLanguage.arabic;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isAr ? 'رسالة جماعية' : 'Broadcast Message',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AdminBento.textPrimary(isDark),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'سيتم إرسال هذه الرسالة إلى جميع المستخدمين المسجلين.'
                  : 'This message will be sent to all registered users.',
              style: TextStyle(
                color: AdminBento.textSecondary(isDark),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isAr
                    ? 'اكتب نص الرسالة الجماعية...'
                    : 'Enter your broadcast message...',
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isSuccess ? AppColors.statusSuccess : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    color: _isSuccess
                        ? AppColors.statusSuccess
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : () => _sendBroadcast(isAr),
          icon: _isSending
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(
            _isSending
                ? (isAr ? 'جاري الإرسال...' : 'Sending...')
                : (isAr ? 'إرسال للجميع' : 'Send to All'),
          ),
        ),
      ],
    );
  }
}
