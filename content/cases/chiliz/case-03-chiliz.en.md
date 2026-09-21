---
title: "Batching blockchain transactions without all-or-nothing"
translationKey: "case-03"
number: "03"
slug: "chiliz-transaction-batching"
group: "chiliz"
position: "position-chiliz"
order: 2
draft: true

context:
  company: "Chiliz"
  setup: "employee"
  role: "Design of the chaining architecture and specification of the transaction batch"
  period: "[TODO: période]"
  stack: ["[TODO: stack]"]

summary: >-
  Traders were repeating the same operation pool by pool. I designed a single entry that executes transactions in sequence, each confirmed before the next, without one failure cancelling the others.
  Reached the test environment, never went to production: priorities changed.

live_material:
  - id: "diagram-chaining-flow"
    type: "diagram"
    status: "planned"
    description: "UI → outbox → sending worker → chain → event listener → transaction status update → next in batch or batch closed"
    url: ""
  - id: "callout-atomic-vs-chained"
    type: "callout"
    status: "planned"
    description: "Atomic batch versus chaining: what happens when one sub-transaction fails"
    url: ""
  - id: "snippet-chaining-loop"
    type: "snippet"
    status: "planned"
    description: "Pseudo-code of the chaining loop (no real code, company property)"
    url: ""
---

## Context

Same application as the previous case, but the other half of the product: beyond calculations, the tool let the finance team execute all its on-chain operations on the token pools themselves — transfers between wallets, deposits into a pool, withdrawals, swaps. Those operations were built first; the decision-support tools came on top.

[TODO: stack]

## The problem

A trader works on several pools at once. One operation at a time meant going to a pool, making the deposit, coming back, going to the next one, and so on — four times, ten times. The need was simple: "I want to deposit this amount into these four pools, in one entry, and have it go."

## The easy way, and why I didn't take it

On the chain, one transaction = one signature. There is a "batch" transaction type that groups several sub-transactions under a single signature — but it is atomic: the slightest execution error in one sub-transaction (insufficient funds on one pool, for instance) fails the whole batch. For a trader, losing the three deposits that were fine because the fourth lacked funds is worse than signing four times.

{{< live-material id="callout-atomic-vs-chained" >}}

## What I decided

Chaining: send the first transaction of the batch, wait for the chain to confirm it, then send the next. One signature per transaction, but a single entry on the user's side, and above all partial success is possible — a failing transaction does not prevent the others from executing.

The architecture around it:

- Everything goes asynchronous from the UI, following the outbox pattern.
- A **Batch** entity with its own status, grouping **Transaction** entities each with their own status — two levels of tracking so we always know where things stand.
- A worker that sends the transactions.
- In parallel, a listener that reads events from the chain and triggers code according to what it returns.
- The listener updates the transaction status; if confirmed, we take the next one in the batch; otherwise we stop and update the batch with its real state.

{{< live-material id="diagram-chaining-flow" >}}

{{< live-material id="snippet-chaining-loop" >}}

## What pushed back

The single signature. The finance team also wanted to sign only once. The only way was the chain's atomic batch, with the all-or-nothing we had just ruled out. With no satisfactory solution and with priorities changing, the subject was deprioritised. Chaining covered most of the value: the single entry and the resilience.

## Outcome

- Multi-pool entry in one go, executed transaction by transaction with partial success possible; two-level status tracking, batch and transaction.
- **Largely implemented and reached the test environment; never went to production.** The team's priorities changed and capacity was lacking to finish. The subject remained partially implemented, ready to be picked up.

## What it shows

I start from the user's need (one entry, not one signature) and identify what actually carries value in it. Faced with a platform constraint, I compare options on their failure modes — atomic and brittle versus chained and resilient — and pick the one whose failure costs least. I design for observability: two levels of status, a listener on the source of truth. And I can say a subject did not make it to the end — and why — without dressing it up as "delivered".
