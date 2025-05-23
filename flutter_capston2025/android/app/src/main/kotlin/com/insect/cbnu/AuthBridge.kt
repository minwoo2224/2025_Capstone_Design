package com.insect.cbnu

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    AuthBridge.setUp(flutterEngine.dartExecutor.binaryMessenger, object : AuthBridge {
      override fun sendUserDetails(details: PigeonUserDetails) {
        android.util.Log.d("AuthBridge", "받은 UID: ${details.uid}")
      }
    })
  }
}
