package com.sanad.sanad_app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth for
// biometric (fingerprint / Face) unlock of the private journal.
class MainActivity : FlutterFragmentActivity()
