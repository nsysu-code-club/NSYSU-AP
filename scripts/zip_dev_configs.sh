#!/bin/sh

zip -r dev_configs.zip \
    lib/firebase_options.dart \
    lib/config/sdk_constants.dart \
    android/app/google-services.json \
    ios/firebase_app_id_file.json \
    macos/firebase_app_id_file.json