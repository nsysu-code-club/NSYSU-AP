#!/bin/sh

zip -r dev_configs.zip \
    lib/firebase_options.dart \
    lib/config/sdk_constants.dart \
    android/app/google-services.json \
    ios/Runner/GoogleService-Info.plist \
    ios/firebase_app_id_file.json \
    macos/Runner/GoogleService-Info.plist \
    macos/firebase_app_id_file.json