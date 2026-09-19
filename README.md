# iBall status

The free backstop for uptime on the public iBall surfaces. This repository contains one workflow
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

## How often this actually runs

The workflow asks for a check every ten minutes. GitHub does not honour that. Scheduled
workflows are best-effort and are throttled hard on repositories with little activity,
and measured over 18-20 Sep 2026 this one actually fired **every two to five hours**:

    21:00  18:39  16:21  12:59  08:56  04:30  00:02   (19 Sep, UTC)

So the worst case here is not ten minutes of unnoticed downtime. It is closer to five
hours — which is the same order as the nine-hour scheduler outage on 15 Sep that nobody
was told about. This repository is worth keeping because it costs nothing and needs no
account, but it must not be the only thing watching.

## The alarm that actually pages: HetrixTools

Minute-by-minute checks run on [HetrixTools](https://hetrixtools.com), free tier: 15
monitors, one-minute frequency, several countries, alerts to email and phone. The three
monitors are created by [`setup-hetrix.sh`](setup-hetrix.sh), which holds no secret — the
API key is read from the environment:

    HETRIX_TOKEN=xxxx ./setup-hetrix.sh

It sets a 15-second timeout on the web hosts, because a cold start on `iball.app` has
been measured at 14.4 seconds and a shorter timeout would invent an outage that never
happened. The API monitor additionally requires the string `"status":"ok"` in the body,
so a cached or proxied 200 with a dead database still reads as down.

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
