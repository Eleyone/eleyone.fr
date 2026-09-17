---
title: "Chiliz"
translationKey: group-chiliz
# Brouillon tant que le cas 02 n'est pas publié (AD-4, D-3) : la page de groupe n'a rien à montrer.
draft: true
# AD-4 : les cas du groupe ne sont jamais rendus à leur propre URL, mais restent listés par la page de
# groupe. Le « target » est obligatoire : sans lui, la page de groupe elle-même cesserait d'être rendue.
cascade:
  - target:
      kind: page
    build:
      render: never
      list: always
---
