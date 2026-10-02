import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_user.dart' show AuthProvider;
import '../services/app_store_purchase_controller.dart';
import 'subscription_provider.dart';

bool get usesAppStoreSubscriptions =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

final appStoreProvider = ChangeNotifierProvider<AppStorePurchaseController>((
  ref,
) {
  final functions = FirebaseFunctions.instance;
  final controller = AppStorePurchaseController(
    store: InAppPurchase.instance,
    currentUserId: () {
      final user = ref.read(authProvider).user;
      return user != null && user.provider != AuthProvider.anonymous
          ? user.uid
          : null;
    },
    prepare: () async {
      final result = await functions
          .httpsCallable('prepareAppStorePurchase')
          .call<void>();
      return (result.data as Map)['accountToken'] as String;
    },
    verify: (signedTransaction) async {
      final result = await functions
          .httpsCallable('verifyAppStorePurchase')
          .call({'signedTransaction': signedTransaction});
      final data = result.data as Map;
      if (data['success'] != true)
        throw StateError('App Store verification failed');
      return data['active'] == true;
    },
    refresh: () => ref.read(subscriptionProvider.notifier).checkSubscription(),
  );
  ref.listen(
    authProvider.select((auth) => (auth.user?.uid, auth.user?.provider)),
    (_, _) => unawaited(controller.onAccountChanged()),
  );
  unawaited(controller.initialize());
  return controller;
});
