import 'package:flutter/material.dart';
import 'call_page.dart';
import 'call_config.dart';

/// Utility class for initiating audio calls throughout the app.
///
/// DEPRECATED: This class is superseded by ZegoCallService which uses
/// Zego's built-in call invitation system. Kept for backward compatibility.
class CallHelper {
  /// Starts an audio call between two users
  @Deprecated('Use ZegoCallService.instance.sendCallInvitation() instead')
  static Future<void> startAudioCall({
    required BuildContext context,
    required String calleeUserId,
    required String calleeName,
    required String callerUserId,
    required String callerName,
    String? customCallId,
  }) async {
    // Validate Zego configuration
    if (CallConfig.appId == 0) {
      _showError(context, 'Call configuration error: Invalid App ID');
      return;
    }

    if (CallConfig.appSign.isEmpty && CallConfig.token.isEmpty) {
      _showError(context, 'Call configuration error: Missing authentication');
      return;
    }

    // Generate unique call ID from both user IDs
    final callID =
        customCallId ?? generateCallIdForPair(callerUserId, calleeUserId);

    // Navigate to call screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          callID: callID,
          userID: callerUserId,
          userName: callerName,
        ),
      ),
    );
  }

  /// Generates a consistent call ID from two user IDs
  /// Ensures the same call ID is generated regardless of who initiates
  static String generateCallIdForPair(String userId1, String userId2) {
    // Sort IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return 'call_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Shows error message to user
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
