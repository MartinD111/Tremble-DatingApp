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
fi

if [ -n "$FIREBASE_OPTIONS_PROD_BASE64" ]; then
  echo "Decoding FIREBASE_OPTIONS_PROD_BASE64..."
  echo "$FIREBASE_OPTIONS_PROD_BASE64" | base64 --decode > lib/src/core/firebase_options_prod.dart
else
  echo "Warning: FIREBASE_OPTIONS_PROD_BASE64 is not set."
fi

echo "Firebase options setup complete."
