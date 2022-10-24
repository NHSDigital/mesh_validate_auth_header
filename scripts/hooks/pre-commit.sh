#!/usr/bin/env bash

set -euo pipefail
PWD="$(pwd)"

ps -ocommand= -p "${PPID}"

if ! scripts/check-secrets.sh; then
  echo "scripts/check-secrets.sh failed"
  exit 1
fi

echo ""
echo "check formatting ..."
echo ""

if ! flutter analyze; then
  echo ""
  echo "flutter analyze failed"
  echo ""
  exit 1
fi

echo ""
