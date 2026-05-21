#!/usr/bin/env bash
#
# register-app.sh — Register or update the Async VDOT extension in the doxy.me app store
#
# Usage:
#   ./scripts/register-app.sh [qa|prod] [create|update <id>|list|publish <id>]
#
# Requirements:
#   - DOXY_ADMIN_USER and DOXY_ADMIN_PASS environment variables (basic auth)
#   - curl, jq
#
# API Base URLs:
#   QA:   https://extensions-api.qa.doxy.me
#   Prod: https://extensions-api.doxy.me (⚠️  production — be careful)
#
# Extension model fields:
#   name, title, description, shortDescription, optionalDescription,
#   price, status (published|unpublished|beta), icon, source,
#   sourceCode, video, isFake

set -euo pipefail

ENV="${1:-qa}"
ACTION="${2:-create}"
EXT_ID="${3:-}"

case "$ENV" in
  qa)   BASE_URL="https://extensions-api.qa.doxy.me" ;;
  prod) BASE_URL="https://extensions-api.doxy.me" ;;
  *)    echo "Unknown env: $ENV (use qa or prod)"; exit 1 ;;
esac

if [[ -z "${DOXY_ADMIN_USER:-}" ]] || [[ -z "${DOXY_ADMIN_PASS:-}" ]]; then
  echo "Error: Set DOXY_ADMIN_USER and DOXY_ADMIN_PASS environment variables"
  exit 1
fi

AUTH="$DOXY_ADMIN_USER:$DOXY_ADMIN_PASS"
API="$BASE_URL/api/extensions/admin/extensions"
MANIFEST_FILE="$(dirname "$0")/../app-store-manifest.json"

echo "🎥 Async VDOT — doxy.me Extension | App Store Registration"
echo "   Environment: $ENV ($BASE_URL)"
echo "   Action:      $ACTION"
echo ""

build_payload() {
  # Build the API payload from the manifest (excluding metadata, which is local-only)
  jq '{
    name: .name,
    title: .title,
    description: .description,
    shortDescription: .shortDescription,
    optionalDescription: .optionalDescription,
    price: .price,
    status: .status,
    icon: .icon,
    source: .source,
    video: .video,
    sourceCode: .sourceCode,
    isFake: .isFake
  }' "$MANIFEST_FILE"
}

case "$ACTION" in
  list)
    echo "📋 Listing all extensions..."
    curl -s -u "$AUTH" "$API" | jq '.'
    ;;

  create)
    echo "✨ Creating new extension..."
    PAYLOAD=$(build_payload)
    echo "   Payload: $PAYLOAD"
    echo ""
    RESULT=$(curl -s -u "$AUTH" \
      -X POST "$API" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")
    echo "   Result: $RESULT"
    echo ""
    NEW_ID=$(echo "$RESULT" | jq -r '.id // empty')
    if [[ -n "$NEW_ID" ]]; then
      echo "✅ Extension created with ID: $NEW_ID"
      echo "   To publish: $0 $ENV publish $NEW_ID"
    else
      echo "❌ Creation failed. Check credentials and try again."
    fi
    ;;

  update)
    if [[ -z "$EXT_ID" ]]; then
      echo "Error: provide extension ID for update: $0 $ENV update <id>"
      exit 1
    fi
    echo "📝 Updating extension ID: $EXT_ID..."
    PAYLOAD=$(build_payload)
    PAYLOAD_WITH_ID=$(echo "$PAYLOAD" | jq ". + {id: $EXT_ID}")
    RESULT=$(curl -s -u "$AUTH" \
      -X PUT "$API" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD_WITH_ID")
    echo "   Result: $RESULT"
    echo ""
    echo "✅ Extension $EXT_ID updated."
    ;;

  publish)
    if [[ -z "$EXT_ID" ]]; then
      echo "Error: provide extension ID to publish: $0 $ENV publish <id>"
      exit 1
    fi
    echo "🚀 Publishing extension ID: $EXT_ID..."
    RESULT=$(curl -s -u "$AUTH" \
      -X PATCH "$API/publish/$EXT_ID" \
      -H "Content-Type: application/json")
    echo "   Result: $RESULT"
    echo ""
    echo "✅ Extension $EXT_ID published."
    ;;

  unpublish)
    if [[ -z "$EXT_ID" ]]; then
      echo "Error: provide extension ID to unpublish: $0 $ENV unpublish <id>"
      exit 1
    fi
    echo "⏸️  Unpublishing extension ID: $EXT_ID..."
    RESULT=$(curl -s -u "$AUTH" \
      -X PATCH "$API/unpublish/$EXT_ID" \
      -H "Content-Type: application/json")
    echo "   Result: $RESULT"
    ;;

  get)
    if [[ -z "$EXT_ID" ]]; then
      echo "Error: provide extension ID: $0 $ENV get <id>"
      exit 1
    fi
    echo "🔍 Getting extension ID: $EXT_ID..."
    curl -s -u "$AUTH" "$API/$EXT_ID" | jq '.'
    ;;

  *)
    echo "Unknown action: $ACTION"
    echo "Actions: list | create | update <id> | publish <id> | unpublish <id> | get <id>"
    exit 1
    ;;
esac
