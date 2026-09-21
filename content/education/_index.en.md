---
translationKey: education
# Formation, certification et langues (AD-18, FR-36) : ni page de section ni page d'entrée. Les
# entrées ne servent qu'à l'accueil, qui les lit ; la cascade les garde listées sans les rendre, et
# son « target » laisse la section hors d'atteinte. Même montage que content/career/.
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
