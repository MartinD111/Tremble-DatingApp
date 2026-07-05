#!/bin/bash
set -e
mkdir -p android/app
if [ ! -f android/app/google-services.json ]; then
  echo "Generating dummy google-services.json so gradle build passes..."
  cat << 'EOF' > android/app/google-services.json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "dummy-id",
    "storage_bucket": "dummy.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:123456789",
        "android_client_info": {
          "package_name": "com.pulse"
        }
      },
      "api_key": [
        {
          "current_key": "dummy_api_key"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
EOF
fi
