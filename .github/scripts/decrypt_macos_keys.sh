#!/bin/sh

# --batch to prevent interactive command
# --yes to assume "yes" for questions
gpg --quiet --batch --yes --decrypt --passphrase="$KEYS_SECRET_PASSPHRASE" \
--output macos/Runner/macos_keys.zip macos/Runner/macos_keys.zip.gpg && cd macos/Runner && jar xvf macos_keys.zip && cd -
