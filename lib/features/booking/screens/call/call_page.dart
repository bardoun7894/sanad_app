import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'call_config.dart';

/// Screen that hosts a Zego Voice Call (audio only).
///
/// NOTE: With the Zego built-in call invitation system, this screen is
/// typically rendered automatically by ZegoUIKitPrebuiltCallInvitationService.
/// This file is kept for potential direct-call use cases (e.g., joining
/// a call by ID without the invitation flow).
class CallPage extends StatelessWidget {
  const CallPage({
    Key? key,
    required this.callID,
    required this.userID,
    required this.userName,
  }) : super(key: key);

  final String callID;
  final String userID;
  final String userName;

  @override
  Widget build(BuildContext context) {
    if (!CallConfig.isConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Call')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Calling is not configured for this build. Please set ZEGO_APP_ID and ZEGO_APP_SIGN.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
    config.duration.isVisible = true;

    return ZegoUIKitPrebuiltCall(
      appID: CallConfig.appId,
      appSign: CallConfig.appSign,
      userID: userID,
      userName: userName,
      callID: callID,
      config: config,
    );
  }
}
