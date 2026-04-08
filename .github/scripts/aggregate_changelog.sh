#!/bin/bash
# aggregate_changelog.sh <output_file>
#
# Queries GitHub API for merged PRs since last release and aggregates
# bilingual changelog entries from PR comments.
#
# Output format: JSON array of {"zh-TW": "...", "en-US": "..."}

set -euo pipefail

OUTPUT_FILE="${1:-changelog_aggregated.json}"

# Find last release tag
LAST_TAG=$(gh release list --exclude-pre-releases --limit 1 --json tagName --jq '.[0].tagName // ""')

if [ -n "$LAST_TAG" ]; then
  LAST_DATE=$(gh release view "$LAST_TAG" --json publishedAt --jq '.publishedAt')
  echo "Aggregating changelog since: $LAST_TAG ($LAST_DATE)"
else
  LAST_DATE="1970-01-01T00:00:00Z"
  echo "No previous release found, aggregating all entries"
fi

# Get merged PRs to master since last release (newest first)
PRS=$(gh pr list \
  --base master \
  --state merged \
  --limit 100 \
  --json number,mergedAt \
  --jq "[.[] | select(.mergedAt > \"$LAST_DATE\") | .number]")

PR_COUNT=$(echo "$PRS" | jq length)
echo "Found $PR_COUNT merged PR(s)"

ENTRIES="[]"

for PR_NUM in $(echo "$PRS" | jq -r '.[]'); do
  # Find the last changelog-entry comment on this PR
  COMMENT=$(gh api "repos/$GITHUB_REPOSITORY/issues/${PR_NUM}/comments" \
    --jq '[.[] | select(.body | startswith("<!-- changelog-entry")) | .body] | last // ""')

  if [ -z "$COMMENT" ] || [ "$COMMENT" = "null" ]; then
    echo "PR #$PR_NUM: no changelog comment, skipping"
    continue
  fi

  # Extract JSON from between the comment markers (expects single-line JSON)
  ENTRY=$(echo "$COMMENT" | awk '/<!-- changelog-entry/{found=1;next}/-->/{found=0}found' | head -1 | xargs)

  if echo "$ENTRY" | jq -e '.["zh-TW"] and .["en-US"]' > /dev/null 2>&1; then
    ENTRIES=$(echo "$ENTRIES" | jq ". + [$ENTRY]")
    echo "PR #$PR_NUM: added — $(echo "$ENTRY" | jq -r '.["en-US"]')"
  else
    echo "PR #$PR_NUM: malformed changelog JSON, skipping"
  fi
done

echo "$ENTRIES" > "$OUTPUT_FILE"
echo "Aggregated $(echo "$ENTRIES" | jq length) entries → $OUTPUT_FILE"
