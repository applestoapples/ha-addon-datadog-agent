#!/usr/bin/env bashio
# shellcheck shell=bash
set -euo pipefail

# Read add-on options
DD_API_KEY=$(bashio::config 'dd_api_key')
DD_SITE=$(bashio::config 'dd_site')
DD_HOSTNAME=$(bashio::config 'dd_hostname')

export DD_API_KEY
export DD_SITE
export DD_HOSTNAME
export DD_LOGS_ENABLED=true
export DD_LOG_LEVEL=info

bashio::log.info "Starting Datadog Agent (v0.9.3)..."

# Create datadog.yaml
# We add run_path to /data so offsets persist across restarts
cat > /etc/datadog-agent/datadog.yaml <<EOF
api_key: ${DD_API_KEY}
site: ${DD_SITE}
hostname: ${DD_HOSTNAME}
logs_enabled: true
log_level: info
logs_config:
  container_collect_all: true
  run_path: /data/logs-agent
EOF

# Configure journald log collection
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: /var/log/journal
    source: haos
EOF

# Ensure permissions
mkdir -p /data/logs-agent
chmod -R 777 /data/logs-agent
chmod -R 755 /etc/datadog-agent

# Start the agent
exec /opt/datadog-agent/bin/agent/agent run
