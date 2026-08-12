# iBall status

Uptime monitoring for the public iBall surfaces. This repository contains one workflow
and nothing else — no source, no secrets, no configuration that is not already public.

It is deliberately **public**. GitHub Actions minutes are unlimited on public
repositories and metered on private ones, and a ten-minute check is about 4,300 runs a
month — roughly twice the whole organisation's Free-plan allowance if it ran anywhere
else. Keeping the checker here, alone and in the open, is what makes continuous
monitoring cost nothing. The only thing it knows is which URLs to visit, and those are
the URLs anyone can type into a browser.

## What it watches

| Surface | Why this one |
|---|---|
| `iball.app` | the web app |
| `www.iball.app` | the same app on the host most people actually type |
| `api.iball.app/api/v1/health/readiness` | the backend **and** its database — readiness fails if Postgres is unreachable, which is the outage a player feels |

`app.iball.app` is not watched: it has no DNS record and is documented as dead. Watching
a host you know is absent produces a permanently red board, and a board that is always
red is a board nobody reads.

## What happens when something breaks

A surface is only called down after three failed checks five seconds apart, so a single
blip does not raise an alarm. Then this repo opens an issue labelled `outage` — one per
outage, updated rather than duplicated — and closes it automatically when everything
answers again.

To get that on your phone: install the **GitHub mobile app** and enable notifications for
this repository. That is the whole alerting path, and it costs nothing.

## Why it isn't part of the Sentinel

The [iBall Sentinel](https://github.com/iball-app/iball-ops) runs in a cloud sandbox whose
egress goes through a policy proxy that returns 403 for `iball.app` and `api.iball.app`.
Its health checks are therefore permanently `UNKNOWN` — it reports that honestly instead
of guessing, which is correct and completely useless for knowing whether the site is up.
This workflow is the eyes it does not have. Everything else — CI, secrets, dependencies,
spend — stays with the Sentinel.
