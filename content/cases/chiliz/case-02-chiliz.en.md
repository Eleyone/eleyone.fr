---
title: "Making an application the source of truth for a financial calculation"
translationKey: "case-02"
number: "02"
slug: "chiliz-source-of-truth"
group: "chiliz"
position: "position-chiliz"
order: 1
draft: true

context:
  company: "Chiliz"
  setup: "employee"
  role: "Backend developer, owner of the NCS/CS epic in a team of four to five developers"
  period: "September 2025 – February 2026"
  stack: ["PHP", "Symfony", "Symfony UX", "Twig", "Redshift"]

summary: >-
  The finance team decided whether to buy, sell or stake tokens from an export recalculated on the side by the BI team.
  I brought that calculation into the application, proved it correct against the old system, and it became the reference.
  The hard part was not the rule but the manual exceptions buried in the history — we found every one of them.

live_material:
  - id: "diagram-ncs-cs-flow"
    type: "diagram"
    status: "planned"
    description: "Blockchain → import into our database → cumulative NCS/CS calculation → application → reconciliation with BI"
    url: ""
  - id: "callout-18-decimals"
    type: "callout"
    status: "planned"
    description: "Why a cumulative calculation at 18 decimal places forgives no exception in the history"
    url: ""
  - id: "snippet-history-replay"
    type: "snippet"
    status: "planned"
    description: "Pseudo-code of the transaction history replay (the real code belongs to the company)"
    url: ""
---

## Context

Chiliz is a blockchain company best known for fan tokens — crypto tokens tied to sports clubs — and for running its own chain. My last team there: four to five backend developers, no dedicated frontend, tasked with building a new tool for the finance branch — the team that trades the company's own tokens internally. The tool helps decide whether to buy, sell or stake. About 90 tokens, one liquidity pool per token.

The project had been started in Python, in-house, on the idea that Python is what comes up most with AI. Nobody in the company had mastered it. So we went back to what the team could actually run in production: PHP and Symfony. Same logic for the frontend: rather than a JS framework nobody knew, Symfony UX and Twig — a decision I contributed to.

## The problem

At the heart of the tool: the NCS and CS calculation — non-circulating supply and circulating supply — that is, how many of our tokens are in circulation and how many are not. Every trading decision depends on it. Until then, the calculation was done by the BI (business intelligence) team, through an export treated as the source of truth. The goal: have the application take over the calculation, prove it correct against BI, then become the reference itself.

One property weighs on everything else: the calculation is cumulative. Each value depends on every earlier transaction. For an up-to-date result, you have to replay the entire history.

{{< live-material id="diagram-ncs-cs-flow" >}}

## What I decided

The proof of concept already existed. I rewrote the implementation documentation — how we bring this into the app — then broke the epic down into stories and tasks. The team estimated it in refinement. I took most of the implementation and ownership of the subject. First version in one month.

I validated against production data paired with a colleague, because I did not have production access.

{{< live-material id="snippet-history-replay" >}}

## What pushed back

The rule we had been given was clean. The history was not. From the first tests, discrepancies with BI: the existing data was full of manual adjustments made over time, and since the calculation is cumulative, a single exception in the past shifts everything that follows.

The real work was therefore an exception hunt: find out who, what, when, why. We also realised some information was missing and lived on the blockchain. Querying the chain on every calculation cost too much time; we decided to import that data into our database and query it directly.

Last source of discrepancy: precision. Amounts have 18 decimal places, bounded. Our libraries handle them correctly; Redshift, on the BI side (AWS's data warehouse), less so — hence rounding differences that accumulate over a cumulative calculation. We defined a tolerance rather than chase a perfect equality that was not on our side.

{{< live-material id="callout-18-decimals" >}}

On the organisational side, a good part of the work was aligning on what we were delivering before building it.

## Outcome

- September: kick-off. One month later: first version. End of February: calculations stabilised and correct, after five months of exception hunting and history clean-up.
- When I left, trading decisions in the application were made on our data, no longer on the BI export.
- The BI export kept running, as consolidation: a reconciliation that continuously checks our calculations stay correct.

## What it shows

I can take a proof of concept and turn it into software that holds: implementation doc, breakdown, end-to-end ownership. I know the business rule and the real data are two different things, and that the work is almost always in the gap between them. I choose technologies on what the team can maintain, not on fashion. And when a calculation drives decisions, I do not consider it delivered until it is proven against the existing reference, with an explicit tolerance.
