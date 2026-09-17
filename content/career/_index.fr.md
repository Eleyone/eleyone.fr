---
translationKey: career
# Parcours (AD-18) : ni page de section ni page de poste. Les postes ne servent qu'à l'accueil, qui les
# lit ; la cascade les garde listés sans les rendre, et son « target » laisse la section hors d'atteinte.
build:
  render: never
  list: never
cascade:
  - target:
      kind: page
    build:
      render: never
      list: always
---
