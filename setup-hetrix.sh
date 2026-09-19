#!/usr/bin/env bash
# Creates the iBall uptime monitors on HetrixTools.
#
# Why this exists alongside the GitHub Actions checker in this repo: GitHub does not
# honour the 10-minute cron. Measured over 19-20 Sep 2026 the scheduled workflow
# actually fired every 2 to 5 hours. That is fine as a free backstop and useless as an
# outage alarm. HetrixTools checks every minute from several countries and sends the
# alert to a phone.
#
# No secret lives in this file. The token comes from the environment:
#   HETRIX_TOKEN=xxxx ./setup-hetrix.sh
# Optional: HETRIX_CONTACT_LIST=<id> to attach an existing contact list.

set -euo pipefail

: "${HETRIX_TOKEN:?set HETRIX_TOKEN to your HetrixTools API key}"
CONTACT_LIST="${HETRIX_CONTACT_LIST:-}"
API="https://api.hetrixtools.com/v2/${HETRIX_TOKEN}/uptime/add/"

# Four checkpoints, weighted towards the routes African traffic actually takes to
# these hosts. A monitor that only watches from one continent reports the network
# between itself and the site, not the site.
LOCATIONS='{"nyc":true,"sfo":false,"dal":false,"ams":true,"lon":true,"fra":true,"sgp":false,"syd":false,"sao":false,"tok":false,"mba":false,"waw":false}'

add_monitor() {
  local name="$1" target="$2" method="$3" keyword="$4" timeout="$5" ssl_days="$6"

  local payload
  payload=$(TARGET="$target" NAME="$name" METHOD="$method" KEYWORD="$keyword" \
            TIMEOUT="$timeout" SSL="$ssl_days" CONTACT="$CONTACT_LIST" LOC="$LOCATIONS" \
    python3 -c '
import json, os
print(json.dumps({
    "Type": "1",                       # website monitor
    "Name": os.environ["NAME"],
    "Target": os.environ["TARGET"],
    "Timeout": int(os.environ["TIMEOUT"]),
    "Frequency": 1,                    # every minute; the free plan allows it
    "FailsBeforeAlert": 3,             # never page on a single blip
    "ContactList": os.environ["CONTACT"],
    "Method": os.environ["METHOD"],
    "Keyword": os.environ["KEYWORD"],
    "HTTPCodes": "200",
    "MaxRedirects": "5",
    "SSLExpiryReminder": os.environ["SSL"],
    "DomainExpiryReminder": "0",
    "NSChangeAlert": "0",
    "Locations": json.loads(os.environ["LOC"]),
}))')

  echo "creating: $name  ->  $target"
  curl -sS -X POST -H 'Content-Type: application/json' -d "$payload" "$API"
  echo
}

# The web app, on both hosts people actually type. HEAD is enough: we only need to know
# the edge answers. Timeout 15 because a cold start on iball.app has been measured at
# 14.4s, and a 10s timeout would invent an outage that never happened.
add_monitor "iBall web - apex"   "https://iball.app"     "HEAD" "" 15 15
add_monitor "iBall web - www"   "https://www.iball.app" "HEAD" "" 15 15

# The backend, via readiness rather than liveness: liveness only proves the process is
# running, which Railway already restarts on. Readiness proves it can reach Postgres and
# that migrations are applied — the outage a player actually feels. GET, not HEAD,
# because the keyword has to be read out of the body.
add_monitor "iBall API readiness" \
  "https://api.iball.app/api/v1/health/readiness" "GET" '"status":"ok"' 10 15

echo
echo "Done. Check https://hetrixtools.com/dashboard/uptime/"
