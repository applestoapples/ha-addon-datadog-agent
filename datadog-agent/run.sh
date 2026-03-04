#!/usr/bin/env bash
set -euo pipefail

# Redirect everything to the container's stdout (PID 1)
exec > /proc/1/fd/1 2>&1

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

echo "STARTUP: Generating configs (v0.6.9)..."

# Find journal path
for p in /var/log/journal /run/log/journal /host/var/log/journal; do
  echo "STARTUP: Checking ${p}..."
  if [ -d "$p" ]; then
    echo "STARTUP: Found ${p}, listing contents:"
    ls -F "$p" || echo "STARTUP: Failed to list ${p}"
    JOURNAL_PATH="$p"
    break
  fi
done

if [ -z "${JOURNAL_PATH:-}" ]; then
  echo "STARTUP: WARNING: No journal path found!"
  JOURNAL_PATH="/var/log/journal"
fi

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
    path: ${JOURNAL_PATH}
EOF

echo "STARTUP: Starting agent with path ${JOURNAL_PATH}..."
# Start the agent directly
exec /opt/datadog-agent/bin/agent/agent run
