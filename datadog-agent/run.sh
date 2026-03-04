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

echo "DIAGNOSTIC: Checking for journal in common HAOS locations..."
for p in /var/log/journal /run/log/journal /host/run/log/journal /host/var/log/journal; do
  if [ -d "$p" ]; then
    echo "DIAGNOSTIC: Found directory $p"
    ls -F "$p"
    # Check if there are actual journal files (usually in a hex-named subdir)
    find "$p" -name "*.journal" | head -n 5
    ACTUAL_JOURNAL_PATH="$p"
  fi
done

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
    path: ${ACTUAL_JOURNAL_PATH:-/var/log/journal}
EOF

echo "DIAGNOSTIC: Using journal path: ${ACTUAL_JOURNAL_PATH:-/var/log/journal}"

# Start the agent
exec /opt/datadog-agent/bin/agent/agent run
