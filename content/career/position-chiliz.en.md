---
translationKey: position-chiliz
company: "Chiliz"
role: "Senior Backend Developer"
sector: "Blockchain · fan tokens"
period: "July 2022 – April 2026"
location: "Fully remote"
setup: "employee"
stack: ["PHP", "Symfony", "Symfony UX", "Twig", "PostgreSQL", "RabbitMQ", "AWS SQS/SNS", "Redis", "Docker", "GitHub Actions", "Node.js", "TypeScript", "viem.js", "ethers.js", "Ethereum", "Chiliz Chain", "Solana", "DFNS", "Fireblocks", "Redshift"]
track: "main"
order: 1
draft: false
---

Chiliz is the blockchain company behind Socios.com and its fan tokens — crypto tokens tied to sports clubs — and runs its own chain. I designed and implemented on-chain financial flows for that ecosystem, within a domain-driven microservices architecture — mainly the wallet service, plus the NFT and user services — across three squads of eight people. Part of the work was redrawing boundaries: service decompositions to narrow the wallet's scope, migrating Chiliz-issued tokens from an Ethereum fork to Chiliz Chain, moving wallets from custodial to non-custodial with the DFNS provider. From May 2024, with the team, I rebuilt in Symfony the finance team's internal application, started in Python in January 2024 and then abandoned: first the on-chain operations that traders and market makers run themselves across several DEXs (decentralised exchanges) — deposits, withdrawals, swaps —, then the decision-support tools, including the NCS/CS calculation over about 90 pools, which the application took over and proved against the BI (business intelligence) export until it became the reference. I also designed a batch processing of on-chain operations, by chaining, which reached the test environment but was never put into production. Alongside, an internal Node.js and TypeScript indexer collected transactions for verification and reconciliation, and early multi-chain work opened the application to Solana.
