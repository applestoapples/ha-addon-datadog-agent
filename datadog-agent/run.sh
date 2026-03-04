#!/usr/bin/env bash
set -euo pipefail

# Read add-on options
DD_API_KEY="$(jq -r '.dd_api_key' /data/options.json)"
DD_SITE="$(jq -r '.dd_site' /data/options.json)"
DD_TAGS="$(jq -r '.dd_tags | join(",")' /data/options.json)"
DD_HOSTNAME="$(jq -r '.dd_hostname' /data/options.json)"

if [ -z "$DD_API_KEY" ]; then
  echo "ERROR: dd_api_key is required" >&2
  exit 1
fi

export DD_API_KEY
export DD_SITE
export DD_TAGS
export DD_HOSTNAME
export DD_LOGS_ENABLED=true
export DD_LOG_LEVEL=debug

# Create a minimal datadog.yaml to ensure logs are enabled and level is debug
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: debug
apm_config:
  enabled: false
process_config:
  enabled: false
EOF

# Configure journald log collection
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: /var/log/journal
    include_units:
      - hassio-supervisor.service
      - hassos-config.service
      - homeassistant.service
    exclude_units:
      - datadog-agent.service
EOF

echo "STARTUP: Checking /var/log/journal..."
ls -R /var/log/journal || echo "/var/log/journal not found or inaccessible"

echo "STARTUP: Starting agent..."
# Start the agent directly
exec /opt/datadog-agent/bin/agent/agent run
