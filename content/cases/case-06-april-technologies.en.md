---
title: "Stepping outside my scope to understand the whole system"
translationKey: "case-06"
number: "06"
slug: "april-beyond-scope"
position: "position-april-technologies-2017"
order: 6
draft: true

context:
  company: "April Technologies"
  setup: "agency"
  role: "Contract Symfony frontend developer, then end-to-end features across front and back"
  period: "2017"
  stack: ["Symfony 1.3", "Java", "SOAP"]

summary: >-
  Hired for the screen, I went to understand the machine behind it: reading the Java to debug precisely, then delivering features end to end.
  I do not stop at my job description when the quality of the result is at stake.

live_material:
  - id: "diagram-official-scope-vs-explored"
    type: "diagram"
    status: "planned"
    description: "Browser → Symfony frontend → SOAP → Java backend → data; the \"my official scope\" zone and the \"where I went to look\" zone"
    url: ""
  - id: "callout-languages-and-levels"
    type: "callout"
    status: "planned"
    description: "Languages practised across assignments, with the level I claim for each (expert / working / read and understood)"
    url: ""
---

## Context

[TODO: ligne de contexte EN — ce qu'est April Technologies, à écrire avec l'auteur ; éviter la confusion avec le mois d'avril]

Second time on this project: I had already worked on it in 2013–2014, on an assignment for CGI. This time, hired to build the frontend of an application in Symfony 1.3. The backend was in Java and exposed SOAP APIs to us. My scope: the UI that displays the data returned by the services. In practice, layout work.

{{< live-material id="diagram-official-scope-vs-explored" >}}

## The problem

No production problem; a comprehension problem. Confined to displaying whatever a service sent me, I did not know where the data came from, how it was built, or why it arrived in that shape. Hard to build a good frontend without understanding the backend — and, honestly, hard to stay interested.

## What I decided

It happened in two stages. First for debugging: when I had an error on the frontend, I went to read the Java to find out whether it came from me or from the service, and to be able to tell a Java developer "this doesn't work, for this reason" instead of sending back a vague ticket. I was not starting from zero: I had done Java years earlier, for cryptography that PHP could not do at the time.

Then because I was moving faster than what had been planned for me. I proposed taking features end to end: the frontend, and the backend that goes with it — creating the field in the Java entity, hence in the database, adding the backend validations, within the insurance business context.

## Outcome

- Features delivered from A to Z by one person instead of a front/back round trip, and precise bug reports to the Java developers rather than "it doesn't work".
- For me: a complete view of the chain, from database to browser, and confirmation that I am not confined to one language. I am not a Java expert, and I do not claim to be; I can work in it, and above all I can read and understand a system written in a language that is not mine.

{{< live-material id="callout-languages-and-levels" >}}

## What it shows

I do not stay in the box I was given when understanding the rest makes my work better. I go and look at the backend when I do the frontend. I switch languages when the problem calls for it — Java for cryptography, Java to understand an API — and tomorrow another language on an assignment migrating away from PHP. The language is a tool; what matters is understanding the whole system.
