---
title: "From seconds to milliseconds without touching the database"
translationKey: "case-05"
number: "05"
slug: "orange-visit-reports-performance"
position: "position-orange"
order: 5
draft: false

context:
  company: "Orange"
  setup: "agency"
  role: "Zend Framework expert, de facto technical decision-maker in the absence of a tech lead"
  period: "July 2014 – January 2016"
  stack: ["PHP", "Zend Framework", "Oracle", "Xdebug"]

summary: >-
  Field sales reps were waiting several seconds on every lookup, over 3G. Without touching the database or the rest of the system, page loads went from seconds to milliseconds.
  By attacking only what actually cost time, measurements in hand.

live_material:
  - id: "callout-magic-methods-vs-direct-access"
    type: "callout"
    status: "planned"
    description: "Magic methods versus direct access: why __get is expensive over thousands of objects, with a reproducible micro-benchmark in modern PHP"
    url: ""
  - id: "diagram-crv-scope"
    type: "diagram"
    status: "planned"
    description: "CRV application (read-only) → shared Oracle database ← the IT system's write application; what was in my scope and what was not"
    url: ""
  - id: "snippet-illustrative"
    type: "snippet"
    status: "planned"
    description: "Illustrative excerpt, no code from the time"
    url: ""
---

## Context

Orange is France's main telecom operator. The CRV application — visit reports — was used by field sales reps selling telecom equipment to small businesses and professionals. No tech lead at the time: that was, in practice, the role I held in the team.

Two structuring constraints: the database was Oracle, managed elsewhere in the IT system, untouchable; and our application was read-only — writes went through another application in Orange's IT system, over which we had no control.

{{< live-material id="diagram-crv-scope" >}}

## The problem

Pages loading in seconds, for sales reps in the field, over 3G and early 4G. Every visit-report lookup cost time in front of the customer.

## The easy way, and why I didn't take it

Redesign the data architecture: impossible, the database was not ours. Rewrite the application: no budget, and the risk of breaking everything for an uncertain gain. We had to gain execution time with the structure unchanged.

## What I decided

Measure first. Profiling with Xdebug and a trace viewer to see where the time really went, method by method. The verdict: a disproportionate share went into magic methods — attributes were private, with no getters, and every access went through `__get`, on objects handled in bulk.

Then decide. I set up a small calibration process: a fixed scenario, replayed several times, with timings taken before and after each hypothesis tested. The clean alternative — explicit getters — remained slightly slower than direct access. The shape of the objects could not change. So I made the attributes public and removed the indirection. It is not the prettiest, and I said so plainly: it is the cheapest, safest and most reversible lever, for the biggest measured gain. The team followed; I made the call.

{{< live-material id="callout-magic-methods-vs-direct-access" >}}

Limits of the measurement, acknowledged: a development environment, not production; no access to production logs; and the profiling itself weighed heavily on every request. What I could rely on were the relative orders of magnitude between hypotheses, not the users' absolute timings.

In practice, I went back over nearly every file, and reformatted some templates along the way — without touching the objects' contracts or the database.

{{< live-material id="snippet-illustrative" >}}

## Outcome

- Pages that loaded in seconds now loaded in milliseconds, on the read side.
- The rest — writes through the other application in the IT system — remained dependent on a system we did not control, and that was stated clearly to users.

## What it shows

I measure before optimising, and I only touch what the measurement points to. I can make an ugly choice when it is measured, reversible, and the clean alternatives are out of budget or out of scope — and I call it a trade-off, not a best practice. I clearly separate what I can improve from what does not depend on me. And when there is no tech lead, I make the decision.
