# Firestore Connectivity Troubleshooting Plan

## Issue Analysis
Based on the log output, the following issues were identified:

### 1. **Primary Issue: DNS Resolution Failure**
```
Unable to resolve host firestore.googleapis.com
No address associated with hostname
```
**Root Cause**: Device cannot resolve Firebase domain names
**Impact**: Firestore operates in offline mode, no real-time updates

### 2. **Secondary Issue: Google API Unavailability**
```
API: Phenotype.API is not available on this device
ConnectionResult{statusCode=DEVELOPER_ERROR}
```
**Root Cause**: Google Play Services issues or device compatibility
**Impact**: Some Firebase features may not work correctly

### 3. **Network Connectivity Issues**
```
Connection failed 1 times. Most recent error: Status{code=UNAVAILABLE}
```
**Root Cause**: Intermittent network or firewall blocking
**Impact**: App functionality degraded but not completely broken

## Immediate Action Plan

### Phase 1: Network Diagnostics
1. **Check Device Network Connection**
   - Verify Wi-Fi/mobile data is enabled
   - Test other apps for internet connectivity
   - Check DNS settings on device

2. **Test Firebase Domain Resolution**
   ```bash
   # Test DNS resolution
   nslookup firestore.googleapis.com
   ping firestore.googleapis.com
   ```

3. **Check Firewall/Proxy Settings**
   - Ensure no firewall blocking Firebase domains
   - Check if using corporate network with restrictions
   - Test with different network (mobile data vs Wi-Fi)

### Phase 2: Firebase Configuration Verification
1. **Verify Firebase Project Status**
   - Check Firebase Console → Project Settings
   - Ensure Firestore database is created and enabled
   - Verify billing is enabled (if required)

2. **Check API Keys and Configuration**
   - Verify `google-services.json` matches Firebase project
   - Check API key restrictions in Google Cloud Console
   - Ensure Firestore API is enabled

3. **Test Firestore Rules Deployment**
   - Verify rules are deployed to Firebase
   - Test with Firebase Emulator Suite
   - Check for rule syntax errors

### Phase 3: App-Level Fixes
1. **Add Network Security Configuration** (Android)
   Create `android/app/src/main/res/xml/network_security_config.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <network-security-config>
       <domain-config cleartextTrafficPermitted="true">
           <domain includeSubdomains="true">firestore.googleapis.com</domain>
           <domain includeSubdomains="true">firebasestorage.googleapis.com</domain>
       </domain-config>
       <base-config cleartextTrafficPermitted="false">
           <trust-anchors>
               <certificates src="system" />
               <certificates src="user" />
           </trust-anchors>
       </base-config>
   </network-security-config>
   ```

2. **Update AndroidManifest.xml**
   ```xml
   <application
       android:networkSecurityConfig="@xml/network_security_config"
       ...>
   ```

3. **Implement Network Connectivity Monitoring**
   Add connectivity check before Firestore operations:
   ```dart
   final connectivityResult = await Connectivity().checkConnectivity();
   if (connectivityResult == ConnectivityResult.none) {
     // Use offline cache
     return await _getFromLocalCache();
   }
   ```

### Phase 4: Offline-First Implementation
1. **Enable Firestore Offline Persistence**
   ```dart
   FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```

2. **Implement Local Cache Fallback**
   - Use Hive for critical data
   - Implement retry logic with exponential backoff
   - Add offline queue for write operations

3. **Add Network State Provider**
   ```dart
   final networkStateProvider = StreamProvider<bool>((ref) {
     final connectivity = Connectivity();
     return connectivity.onConnectivityChanged.map((result) {
       return result != ConnectivityResult.none;
     });
   });
   ```

## Diagnostic Tools Implementation

### 1. Firestore Connectivity Test Function
```dart
Future<bool> testFirestoreConnectivity() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final testDoc = firestore.collection('_test').doc('connection');
    await testDoc.set({'timestamp': FieldValue.serverTimestamp()});
    await testDoc.delete();
    return true;
  } catch (e) {
    print('Firestore connectivity test failed: $e');
    return false;
  }
}
```

### 2. Network Diagnostic Screen
Create a diagnostic screen that shows:
- Current network status
- Firebase connection status
- DNS resolution test results
- Firestore rules test results

### 3. Logging Enhancement
Add detailed logging for network operations:
```dart
class NetworkLogger extends Interceptor {
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    log('Network error: ${err.message}', error: err);
    super.onError(err, handler);
  }
}
```

## Long-Term Solutions

### 1. Implement App Check
Add Firebase App Check to prevent unauthorized access:
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
```

### 2. Add Automatic Retry Logic
Implement retry with exponential backoff for network operations:
```dart
Future<T> retryNetworkOperation<T>(
  Future<T> Function() operation,
  int maxRetries = 3,
) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: pow(2, i).toInt()));
    }
  }
  throw Exception('Max retries exceeded');
}
```

### 3. Create Offline Sync Queue
Implement a queue for offline operations:
```dart
class OfflineSyncQueue {
  final Queue<SyncOperation> _queue = Queue();
  
  Future<void> addOperation(SyncOperation operation) async {
    _queue.add(operation);
    await _saveQueueToStorage();
    await _processQueueWhenOnline();
  }
}
```

## Testing Procedure

### 1. Test Scenarios
- [ ] App with no internet connection
- [ ] App with intermittent connection
- [ ] App behind firewall/proxy
- [ ] App with DNS issues
- [ ] App with expired Firebase credentials

### 2. Expected Outcomes
- App should work offline with cached data
- App should sync when connection restored
- User should see appropriate error messages
- Critical functions should have fallbacks

### 3. Monitoring Metrics
- Firestore connection success rate
- Network request latency
- Offline operation queue size
- User-reported connectivity issues

## Rollout Plan

### Week 1: Immediate Fixes
1. Add network security configuration
2. Implement basic connectivity checks
3. Deploy updated app with diagnostics

### Week 2: Enhanced Offline Support
1. Implement Firestore offline persistence
2. Add local cache fallback for critical data
3. Create network status indicator

### Week 3: Monitoring & Analytics
1. Add Firebase Performance Monitoring
2. Implement error tracking
3. Create admin dashboard for connectivity issues

## Success Criteria
- Firestore connection success rate > 99%
- User-reported connectivity issues reduced by 90%
- App functions correctly in offline mode
- Automatic recovery when network restored

## Emergency Contact
If issues persist after implementing these fixes:
1. Check Firebase Status Dashboard
2. Review Google Cloud Platform quotas
3. Contact Firebase Support with project ID: `sanad-app-beldify`

---

**Last Updated**: December 31, 2025  
**Next Review**: January 7, 2026  
**Status**: Planning Complete - Ready for Implementation