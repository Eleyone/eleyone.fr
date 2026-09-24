---
title: "From iframe to product: a profitability calculator in production"
translationKey: "case-01"
number: "01"
slug: "profitability-calculator"
position: "position-ton-pote-le-geek"
order: 1
draft: false

context:
  company: "Institut Lionne"
  setup: "ton-pote-le-geek"
  role: "Design, development and hosting of the application, from V1 to ongoing maintenance"
  period: "since May 2025"
  stack: ["Symfony", "PostgreSQL", "Docker Compose", "Systeme.io", "Claude Code"]

summary: >-
  A business coach for hairdressers was redoing the same cost-price calculation by hand with every client.
  I built a tool her clients use on their own: about 400 accounts created, 300 active.
  Her coaching time now goes to coaching.

live_material:
  - id: "video-calculation-flow"
    type: "video"
    status: "planned"
    description: "A hairdresser enters her costs and a service, gets her floor price and her PDF (60 to 90 seconds)"
    url: ""
  - id: "diagram-account-creation"
    type: "diagram"
    status: "planned"
    description: "Course purchase in Systeme.io → tag → webhook → account creation → credentials sent"
    url: ""
  - id: "snippet-cost-price-test"
    type: "snippet"
    status: "planned"
    description: "Excerpt of a unit test on the cost-price calculation, showing the over/under-estimation asymmetry"
    url: ""
---

## Context

My client is a business coach for hairdressers in France and runs Institut Lionne: a former hairdresser, former salon owner, then franchise owner. She sells a training programme in which every client has to work out the minimum price of her services so as not to lose money. She came to me through the person who was managing her social media at the time.

I took this on under Ton Pote le Geek, my own automation business for very small and small companies.

## The problem

The calculation is always the same — product cost per service, monthly overheads, hours actually worked, target salary — but she was redoing it by hand, in one-to-one sessions, with every client. Hours of coaching spent on divisions she had already done fifty times. No off-the-shelf tool to buy or rent did this at the time, as far as either of us knew.

## The easy way, and why I didn't take it

A spreadsheet handed to each client. Rejected: it solves nothing, she still has to hold their hand to fill it in. A no-code tool: none could do the form and the calculation properly, and at the estimated price I would have lost more time bending one than writing a small application.

## What I decided

**V1 — the minimum that makes clients autonomous.** A small Symfony application, no database, embedded as an iframe inside the Systeme.io course (Systeme.io is an all-in-one platform for selling online courses). A form, a calculation, a PDF out. No database on purpose: no GDPR exposure, nothing to host or maintain, and the assumption that clients did their calculation, took their PDF and did not come back.

**The assumption was wrong.** Feedback came fast: they do come back, and having to re-enter everything was a real obstacle. Three months after going live, switch to a full application: Symfony and PostgreSQL, containerised with Docker Compose, hosted on a VPS. Automatic account creation: course purchase in Systeme.io, tag, webhook to the application, account created, credentials sent by email.

{{< live-material id="diagram-account-creation" >}}

This V2 was built in three months part-time, outside my working hours, adopting Claude Code for the first time. It would have taken me six months full-time.

## What pushed back

Not the webhook, not authentication, not the iframe — all of that is documentation and implementation. What hurt: bugs reported on the critical path, on the calculations themselves, which should never have made it past unit tests. For a decision-support tool, error is not symmetrical: an over-estimated price earns a little more, an under-estimated price loses a hairdresser money. That cannot be allowed.

{{< live-material id="snippet-cost-price-test" >}}

Response: a code quality and security audit, a CI pipeline that holds, structured development processes, and rebuilding the Docker stack myself instead of consuming it. It should have come earlier; it is part of the job.

## Outcome

- In production for a little over a year; the database version arrived three months in.
- Four production iterations since: calculation fixes, improvements, and UX work.
- About 400 accounts created, 300 of them active, using the tool on their own. The original walkthrough video became outdated across versions; it was replaced by a first-login tutorial and contextual help inside the tool.
- For my client: the coaching hours that went into calculations now go into management and mindset — clients arrive with their numbers in hand.
- Model: one fixed fee for the initial build, a second for V2, then a monthly maintenance fee; hosting on a VPS I administer, billed separately.
- The tool is being turned into a product sold under my own name, with the client's agreement: time invested in the product also benefits her instance.

{{< live-material id="video-calculation-flow" >}}

## What it shows

I start with the minimum scope and let real need dictate what comes next. I make technical decisions on cost and risk, not preference. When an assumption turns out wrong, I correct it fast. And I think in business risk: what matters is not test coverage, it is knowing which error costs the user money.
