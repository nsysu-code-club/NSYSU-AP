#!/bin/bash
set -euo pipefail

TARGET="$1" # android, ios, or github

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Prefer the changelog aggregated from merged PRs when Actions provides it.
if [ -n "${AGGREGATED_CHANGELOG:-}" ] && [ -f "$AGGREGATED_CHANGELOG" ]; then
  ENTRY_COUNT=$(jq length "$AGGREGATED_CHANGELOG")

  if [ "$ENTRY_COUNT" -eq 0 ]; then
    echo "No aggregated changelog entries found; using checked-in changelog."
  else
    case "$TARGET" in
      android)
        for locale in "en-US" "zh-TW"; do
          mkdir -p "metadata/android/${locale}/changelogs/"
          jq -r ".[] | \"* \" + .[\"${locale}\"]" "$AGGREGATED_CHANGELOG" \
            > "metadata/android/${locale}/changelogs/default.txt"
        done
        ;;
      ios)
        for locale in "en-US" "zh-TW"; do
          jq -r ".[] | \"* \" + .[\"${locale}\"]" "$AGGREGATED_CHANGELOG" \
            > "${locale}.txt"
        done
        ;;
      github)
        {
          echo "## v${RELEASE_VERSION:-unknown}"
          echo ""
          echo "**What's New**"
          jq -r '.[] | "- " + .["en-US"]' "$AGGREGATED_CHANGELOG"
          echo ""
          echo "---"
          echo ""
          echo "**更新內容**"
          jq -r '.[] | "- " + .["zh-TW"]' "$AGGREGATED_CHANGELOG"
        } > RELEASE_NOTES_GENERATED.md
        ;;
      *)
        echo "ERROR: Unknown target '${TARGET}'. Use: android, ios, or github"
        exit 1
        ;;
    esac

    echo "Generated ${TARGET} changelog from $ENTRY_COUNT aggregated entries"
    exit 0
  fi
fi

# Fall back to the checked-in changelog, matched by public app version.
CHANGELOG_FILE="$SCRIPT_DIR/../../changelog.json"
APP_VERSION=$(grep '^version: ' "$SCRIPT_DIR/../../pubspec.yaml" | sed 's/version: //' | cut -d'+' -f1)
CHANGELOG_ENTRY=""
if [ -f "$CHANGELOG_FILE" ]; then
  CHANGELOG_ENTRY=$(jq -c --arg version "$APP_VERSION" \
    'to_entries | map(select(.value.version == $version)) | first | .value // empty' \
    "$CHANGELOG_FILE")
fi

if [ -z "$CHANGELOG_ENTRY" ]; then
  echo "WARNING: App version ${APP_VERSION} is missing from ${CHANGELOG_FILE}; using default release notes."
  CHANGELOG_ENTRY=$(jq -nc --arg version "$APP_VERSION" '{
    version: $version,
    "en-US": ["Bug fixes and improvements."],
    "zh-TW": ["問題修正與效能改善。"]
  }')
fi

case "$TARGET" in
  android)
    for locale in "en-US" "zh-TW"; do
      mkdir -p "metadata/android/${locale}/changelogs/"
      printf '%s' "$CHANGELOG_ENTRY" | \
        jq -r ".\"${locale}\" | map(\"* \" + .) | join(\"\n\")" \
        > "metadata/android/${locale}/changelogs/default.txt"
    done
    echo "Generated Android changelog for app version ${APP_VERSION}"
    ;;
  ios)
    for locale in "en-US" "zh-TW"; do
      printf '%s' "$CHANGELOG_ENTRY" | \
        jq -r ".\"${locale}\" | map(\"* \" + .) | join(\"\n\")" \
        > "${locale}.txt"
    done
    echo "Generated iOS changelog for app version ${APP_VERSION}"
    ;;
  github)
    VERSION="$APP_VERSION"
    {
      echo "## v${VERSION}"
      echo ""
      printf '%s' "$CHANGELOG_ENTRY" | \
        jq -r '."en-US" | map("- " + .) | join("\n")'
      echo ""
      echo "---"
      echo ""
      printf '%s' "$CHANGELOG_ENTRY" | \
        jq -r '."zh-TW" | map("- " + .) | join("\n")'
    } > RELEASE_NOTES_GENERATED.md
    echo "Generated GitHub release notes for app version ${APP_VERSION}"
    ;;
  *)
    echo "ERROR: Unknown target '${TARGET}'. Use: android, ios, or github"
    exit 1
    ;;
esac
