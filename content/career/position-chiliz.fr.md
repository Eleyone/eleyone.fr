---
translationKey: position-chiliz
company: "Chiliz"
role: "Développeur backend senior"
sector: "Blockchain · fan tokens"
period: "Juillet 2022 – avril 2026"
location: "Full remote"
setup: "employee"
stack: ["PHP", "Symfony", "Symfony UX", "Twig", "PostgreSQL", "RabbitMQ", "AWS SQS/SNS", "Redis", "Docker", "GitHub Actions", "Node.js", "TypeScript", "viem.js", "ethers.js", "Ethereum", "Chiliz Chain", "Solana", "DFNS", "Fireblocks", "Redshift"]
track: "main"
order: 1
draft: false
---

J'ai conçu et implémenté des flux financiers on-chain pour l'écosystème Socios.com et ses fan tokens, dans une architecture de microservices orientés domaines — surtout le service wallet, aussi les services NFT et user —, au sein de trois squads de huit personnes. Une part du travail a consisté à redessiner des frontières : redécoupage de services pour resserrer le périmètre du wallet, migration des tokens émis par Chiliz d'un fork Ethereum vers la Chiliz Chain, passage des wallets custodial à non-custodial avec DFNS. À partir de mai 2024, avec l'équipe, j'ai reconstruit en Symfony l'application interne du pôle finance, démarrée en Python en janvier 2024 puis abandonnée : d'abord les opérations on-chain que traders et market makers exécutent eux-mêmes sur plusieurs DEX — dépôts, retraits, swaps —, puis les outils d'aide à la décision, dont le calcul NCS/CS sur environ 90 pools, pris en charge par l'application et prouvé contre la BI jusqu'à en devenir la référence. J'y ai aussi conçu un traitement par lots des opérations on-chain, par chaînage, arrivé en environnement de test mais jamais mis en production. À côté, un indexer interne en Node.js et TypeScript collectait les transactions pour vérification et réconciliation, et les premiers travaux multi-chaînes ont ouvert l'application à Solana.
