#!/bin/bash
# verify_health.sh - Health check script for the application
# FLAW: Redundant health check calls (inefficient, wastes resources)

APP_URL="$1"
if [ -z "$APP_URL" ]; then
  echo "Usage: $0 <app_url>"
  exit 1
fi

# First call
STATUS1=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")

# FLAW: Redundant call to the same endpoint
STATUS2=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")

if [ "$STATUS1" == "200" ] && [ "$STATUS2" == "200" ]; then
  echo "Health check PASSED"
  exit 0
else
  echo "Health check FAILED: status1=$STATUS1, status2=$STATUS2"
  echo "$APP_URL/health"
  exit 2
fi
