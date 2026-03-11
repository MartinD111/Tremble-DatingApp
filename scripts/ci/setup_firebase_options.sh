#!/bin/bash

# This script reconstructs firebase_options_*.dart files from environment variables.
# Used in CI/CD to avoid committing sensitive API keys to the repository.

set -e

mkdir -p lib/src/core

if [ -n "$FIREBASE_OPTIONS_DEV_BASE64" ]; then
  echo "Decoding FIREBASE_OPTIONS_DEV_BASE64..."
  echo "$FIREBASE_OPTIONS_DEV_BASE64" | base64 --decode > lib/src/core/firebase_options_dev.dart
else
  echo "Warning: FIREBASE_OPTIONS_DEV_BASE64 is not set."
  echo "Generating dummy DevFirebaseOptions stub so flutter analyze passes..."
  cat << 'EOF' > lib/src/core/firebase_options_dev.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
class DevFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'dummy_api_key_dev',
    appId: '1:12345:android:abc',
    messagingSenderId: '12345',
    projectId: 'tremble-dev',
  );
}
EOF
fi

if [ -n "$FIREBASE_OPTIONS_PROD_BASE64" ]; then
  echo "Decoding FIREBASE_OPTIONS_PROD_BASE64..."
  echo "$FIREBASE_OPTIONS_PROD_BASE64" | base64 --decode > lib/src/core/firebase_options_prod.dart
else
  echo "Warning: FIREBASE_OPTIONS_PROD_BASE64 is not set."
  echo "Generating dummy ProdFirebaseOptions stub so flutter analyze passes..."
  cat << 'EOF' > lib/src/core/firebase_options_prod.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
class ProdFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'dummy_api_key_prod',
    appId: '1:12345:android:abc',
    messagingSenderId: '12345',
    projectId: 'tremble-prod',
  );
}
EOF
fi

echo "Firebase options setup complete."
