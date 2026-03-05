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

bashio::log.info "Starting Datadog Agent (v0.9.5) with replicated syslog parsing..."

# Create datadog.yaml
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

# Find actual journal path
JOURNAL_PATH="/var/log/journal"
if [ -d "/run/log/journal" ]; then
    JOURNAL_PATH="/run/log/journal"
fi

# Configure journald log collection with advanced processing rules
# to replicate ha-addon-syslog behavior.
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: $JOURNAL_PATH
    source: haos
    log_processing_rules:
      # 1. Strip ANSI colors (replicated from journal2syslog.py)
      - type: mask_sequences
        name: strip_colors
        replace_placeholder: ""
        pattern: "(\x1b\[[0-9;]*[mK])"
      
      # 2. Extract Log Level from HA message format
      # Replicates: PATTERN_LOGLEVEL_HA = re.compile(r"^\S+ \S+ (?P<level>INFO|WARNING|DEBUG|ERROR|CRITICAL) ")
      - type: multi_line
        name: ha_log_level
        pattern: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
EOF

# Ensure permissions
mkdir -p /data/logs-agent
chmod -R 777 /data/logs-agent
chmod -R 755 /etc/datadog-agent

# Start the agent
exec /opt/datadog-agent/bin/agent/agent run
