#!/usr/bin/env bash
set -euo pipefail

# Read add-on options
DD_API_KEY="$(jq -r '.dd_api_key' /data/options.json)"
DD_SITE="$(jq -r '.dd_site' /data/options.json)"
DD_TAGS="$(jq -r '.dd_tags | join(",")' /data/options.json)"

if [ -z "$DD_API_KEY" ]; then
  echo "ERROR: dd_api_key is required" >&2
  exit 1
fi

export DD_API_KEY
export DD_SITE
export DD_TAGS
export DD_LOGS_ENABLED=true

# Disable unnecessary components
export DD_APM_ENABLED=false
export DD_PROCESS_AGENT_ENABLED=false

# Configure journald log collection
mkdir -p /etc/datadog-agent/conf.d/journald.d
cat > /etc/datadog-agent/conf.d/journald.d/conf.yaml <<EOF
logs:
  - type: journald
    path: /var/log/journal
    include_units:
      - hassio-supervisor.service
      - hassos-config.service
    exclude_units:
      - datadog-agent.service
EOF

# Start the agent
exec /bin/entrypoint.sh
