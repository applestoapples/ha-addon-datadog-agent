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

echo "STARTUP: Diagnostic check (v0.7.6)..."
echo "STARTUP: Current user: $(id)"
echo "STARTUP: Checking /var/log/journal..."
ls -ld /var/log/journal || echo "/var/log/journal not found"
ls -F /var/log/journal || echo "cannot list /var/log/journal"

# Create a minimal datadog.yaml
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: debug
EOF

# Configure journald log collection
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
EOF

echo "STARTUP: Starting Datadog Agent..."
sleep 5 # ensure logs are flushed
exec /opt/datadog-agent/bin/agent/agent run
