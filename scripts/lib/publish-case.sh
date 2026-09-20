# Décision de publication d'un cas (story 3.17) : que publier, qu'ajouter, que refuser.
#
# À charger par « . scripts/lib/publish-case.sh » depuis un script qui a défini script_name.
# La décision est séparée de l'exécution, comme celle des verrous de fusion : elle ne lit que les
# manifestes du rendu de travail (AD-10) et n'écrit rien, si bien qu'elle s'éprouve sur des
# manifestes écrits à la main, sans build ni forge.
#
#   publish_case_plan <manifeste fr> <manifeste en> <translationKey>
#       affiche le plan, une ligne par action, ou refuse en nommant l'écart :
#         case=<fichier relatif à content/>      passe en draft: false
#         index=<fichier relatif à content/>     idem, _index du groupe (premier cas publié, D-3)
#         release=<clé>                          à ajouter à ci/release-pages.txt
#       codes : 0 plan affiché, 1 refus (le message dit quoi corriger), 2 anomalie (manifeste illisible)
#
# Le plan est trié : les fichiers du cas, puis ceux du groupe, puis les clés. Un appelant peut donc
# le comparer octet pour octet dans un test.
# Procédure : docs/procedures/publish-case.md

publish_case_die() { printf '%s: %s\n' "${script_name:-publish-case}" "$*" >&2; return 2; }
publish_case_refuse() { printf '%s: %s\n' "${script_name:-publish-case}" "$*" >&2; return 1; }

# Entrée d'un fichier dans un manifeste, par sa clé de traduction ; vide si absente.
publish_case_entry() { # $1 = manifeste, $2 = translationKey
  jq -c --arg key "$2" 'first(.files[] | select(.translationKey == $key)) // empty' "$1" 2> /dev/null
}

publish_case_plan() { # $1 = manifeste fr, $2 = manifeste en, $3 = translationKey
  local manifeste_fr=$1 manifeste_en=$2 cle=$3 langue manifeste entree
  local -a entrees=()

  [[ -n $cle ]] || { publish_case_die "aucune clé de traduction donnée."; return 2; }
  for manifeste in "$manifeste_fr" "$manifeste_en"; do
    [[ -r $manifeste ]] || { publish_case_die "manifeste illisible ($manifeste) : lancer scripts/build.sh work."; return 2; }
    jq -e '.files | arrays' "$manifeste" > /dev/null 2>&1 \
      || { publish_case_die "manifeste sans liste de fichiers ($manifeste)."; return 2; }
  done

  # --- le cas, dans les deux langues ---------------------------------------------------------------
  for manifeste in "$manifeste_fr" "$manifeste_en"; do
    langue=$([[ $manifeste == "$manifeste_fr" ]] && echo fr || echo en)
    entree=$(publish_case_entry "$manifeste" "$cle")
    [[ -n $entree ]] || { publish_case_refuse "aucun fichier de clé « $cle » dans le manifeste $langue : vérifier la clé, ou relancer le rendu de travail."; return 1; }
    [[ $(jq -r '.role' <<< "$entree") == case ]] \
      || { publish_case_refuse "« $cle » n'est pas un cas en $langue (rôle $(jq -r '.role' <<< "$entree")) : publish-case ne publie que des cas."; return 1; }
    [[ $(jq -r '.error // empty' <<< "$entree") == "" ]] \
      || { publish_case_refuse "le manifeste $langue signale une erreur sur « $cle » : $(jq -r '.error' <<< "$entree")"; return 1; }
    [[ $(jq -r '.draft' <<< "$entree") == true ]] \
      || { publish_case_refuse "le cas « $cle » est déjà publié en $langue : rien à faire."; return 1; }
    [[ $(jq -r '.todo' <<< "$entree") == false ]] \
      || { publish_case_refuse "il reste un marqueur [TODO dans $(jq -r '.file' <<< "$entree") : un fichier publié n'en tolère aucun (C5)."; return 1; }
    entrees+=("$entree")
  done

  # --- le poste du cas : jamais publié par ce script -----------------------------------------------
  local poste
  poste=$(jq -r '.front_matter.position // empty' <<< "${entrees[0]}")
  [[ -n $poste ]] || { publish_case_refuse "le cas « $cle » ne désigne aucun poste (clé « position », AD-18)."; return 1; }
  local entree_poste
  entree_poste=$(publish_case_entry "$manifeste_fr" "$poste")
  [[ -n $entree_poste ]] \
    || { publish_case_refuse "le poste « $poste » du cas « $cle » est introuvable dans le manifeste."; return 1; }
  [[ $(jq -r '.draft' <<< "$entree_poste") == false ]] \
    || { publish_case_refuse "le poste « $poste » est encore en brouillon ($(jq -r '.file' <<< "$entree_poste")) : publish-case ne le publie pas à la place de la story qui en a la charge (C19)."; return 1; }

  # --- le groupe, s'il y en a un -------------------------------------------------------------------
  local groupe index_publie=0
  groupe=$(jq -r '.front_matter.group // empty' <<< "${entrees[0]}")
  local -a index_entrees=()
  if [[ -n $groupe ]]; then
    for manifeste in "$manifeste_fr" "$manifeste_en"; do
      langue=$([[ $manifeste == "$manifeste_fr" ]] && echo fr || echo en)
      entree=$(jq -c --arg g "$groupe" 'first(.files[] | select(.role == "group" and .front_matter.group == $g)) // empty' "$manifeste" 2> /dev/null)
      [[ -n $entree ]] \
        || entree=$(publish_case_entry "$manifeste" "group-$groupe")
      [[ -n $entree ]] \
        || { publish_case_refuse "la page du groupe « $groupe » est introuvable dans le manifeste $langue (AD-4)."; return 1; }
      if [[ $(jq -r '.draft' <<< "$entree") == true ]]; then
        [[ $(jq -r '.todo' <<< "$entree") == false ]] \
          || { publish_case_refuse "il reste un marqueur [TODO dans $(jq -r '.file' <<< "$entree") : la page du groupe est publiée avec ce cas (D-3)."; return 1; }
        index_entrees+=("$entree")
      else
        index_publie=1
      fi
    done
    # Un _index publié dans une langue et pas dans l'autre : le rendu serait boiteux, et la parité
    # (C3) ne le voit pas, puisqu'elle compare l'existence des fichiers, pas leur brouillon.
    ((${#index_entrees[@]} == 0 || index_publie == 0)) \
      || { publish_case_refuse "la page du groupe « $groupe » est publiée dans une langue et en brouillon dans l'autre : corriger à la main avant de publier un cas."; return 1; }
  fi

  # --- le plan --------------------------------------------------------------------------------------
  local e
  for e in "${entrees[@]}"; do printf 'case=%s\n' "$(jq -r '.file' <<< "$e")"; done
  for e in "${index_entrees[@]}"; do printf 'index=%s\n' "$(jq -r '.file' <<< "$e")"; done
  printf 'release=%s\n' "$cle"
  [[ -z $groupe ]] || printf 'release=group-%s\n' "$groupe"
}
