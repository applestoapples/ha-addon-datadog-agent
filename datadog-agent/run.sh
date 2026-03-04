#!/usr/bin/env bash
set -euo pipefail

# Read add-on options
DD_API_KEY="$(jq -r '.dd_api_key' /data/options.json)"
DD_SITE="$(jq -r '.dd_site' /data/options.json)"
DD_HOSTNAME="$(jq -r '.dd_hostname' /data/options.json)"

if [ -z "$DD_API_KEY" ]; then
  echo "ERROR: dd_api_key is required"
  exit 1
fi

export DD_API_KEY
export DD_SITE
export DD_HOSTNAME
export DD_LOGS_ENABLED=true
export DD_LOG_LEVEL=debug

echo "STARTUP: Generating minimal datadog.yaml..."
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: debug
EOF

echo "STARTUP: Configuring journald integration (no path, auto-detect)..."
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
EOF

echo "STARTUP: Starting Datadog Agent v0.7.5..."
exec /opt/datadog-agent/bin/agent/agent run
