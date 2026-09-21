---
title: "Taking over a drifting project without steamrolling its owner"
translationKey: "case-04"
number: "04"
slug: "chiliz-pool-creation-takeover"
group: "chiliz"
position: "position-chiliz"
order: 3
draft: true

context:
  company: "Chiliz"
  setup: "employee"
  role: "Taking over ownership and reworking the pool-creation process"
  period: "December 2025 – March 2026"
  stack: ["Fireblocks"]

summary: >-
  A late pool-creation process, carried by a developer who could no longer cope. I took it over with his agreement, fixed a flaw that could have cost us control of a pool, and shipped it.
  Used since for every token issuance.

live_material:
  - id: "diagram-pool-creation-process"
    type: "diagram"
    status: "planned"
    description: "Allowances → creation + first deposit (one transaction) → allowance on the pool → indexing, with the Fireblocks admin approval points"
    url: ""
  - id: "callout-ownership-window"
    type: "callout"
    status: "planned"
    description: "The ownership window in two calls, and why a single transaction closes it"
    url: ""
  - id: "diagram-event-table"
    type: "diagram"
    status: "planned"
    description: "Pseudo-schema of the event table with statuses (no real data)"
    url: ""
---

## Context

Same application. The subject: pool creation. When the company issues a new token, a matching liquidity pool has to be created — token against crypto, or token against token — and seeded with a first deposit. That first deposit sets the conversion ratio, hence the starting price at which trading begins. Goal: a single entry point in the application, a single confirmation, and a process as automated as possible.

A saturated team: everyone owning a subject with a close deadline. This one had been designed and carried by a junior developer I was mentoring.

## The problem

Two problems, one inside the other.

**The subject was drifting.** The developer asked a lot of questions, no longer knew where he was going, produced things that broke in testing and could not debug them. Management noticed. One month late, strong pressure to deliver.

**The initial design was wrong.** V1 made two blockchain calls: create the pool, then deposit. Between the two, a window: anyone holding tokens could deposit before us and take ownership of the pool. And the real process was much longer than two calls: wallet allowances on each token, creation, allowance on the pool, indexing — with none of those steps leaving a trace. We knew neither what had happened, nor when, nor why.

{{< live-material id="callout-ownership-window" >}}

## What I decided

**The takeover.** I first helped as backup, on debugging. Then, under pressure and because I was losing time on both sides — my own subjects and his questions — I went to the scrum master and the tech lead to propose taking over ownership. The developer himself asked for it: too much pressure, he would not make it. I took it over because I was already mentoring him and had a clear idea of what needed doing.

He stayed in every review. We talked offline: I walked him through each choice, why, and under which conditions. Part of what I implemented was the feedback I had already given him — add logging, represent each event in a table with a status.

**The rework.** Switch to a method that creates the pool and makes the first deposit in a single transaction: the window closes, and we save a signature. All allowances integrated as automated prerequisites of the process. And I reapplied to pool creation the tracking mechanism I was building in parallel for allowances: an event table per step, each with its status, to know at any moment where the process stands.

{{< live-material id="diagram-pool-creation-process" >}}

{{< live-material id="diagram-event-table" >}}

## What pushed back

The company's wallets were managed by Fireblocks, an institutional custody platform. Some actions and some wallets required approval from an admin account — the user only signed part of it, the rest went through the admin. On top of that, Fireblocks whitelisting, also subject to admin signature. Every step of the process had to accommodate these two layers of approval.

## Outcome

- Started in December, shipped to production in March: three months late in total, testing included. One of the last subjects I handled at Chiliz.
- Used since for every new token issuance: the pool is created through this process.
- A single entry point, a single confirmation on the user's side; every step traced with its status.
- Pool ownership window closed.

## What it shows

I spot when a subject is drifting and act before it sinks — through management, not around it. I take the load without taking the place: the developer asked to step out, he stayed in the reviews, he had every decision explained. I challenge a design that "works" when its failure mode is unacceptable. And I design for tracking: if you cannot tell where a process stands, you can neither debug it nor trust it.
