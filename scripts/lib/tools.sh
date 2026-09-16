# Bibliothèque commune des outils épinglés (AD-1) : lecture de tools.env et vérification de version.
#
# À charger par « . scripts/lib/tools.sh » depuis un script qui a défini script_name.
#
#   load_tools_env <fichier tools.env>   lit les variables épinglées ; code 2 si le fichier ou une
#                                        variable manque, sans jamais continuer avec une valeur vide
#   tool_version <outil> <binaire>       affiche la version annoncée par le binaire (hugo ou d2)
#   require_tool_version <outil> <binaire> <version attendue>
#                                        échoue en nommant l'outil, la version attendue et la trouvée
#
# Convention de code de sortie du projet : 0 conforme, 1 refus, 2 anomalie (fichier absent, illisible).
# Procédures : docs/procedures/tools.md, docs/procedures/shell-scripts.md

readonly tools_env_expected=(HUGO_VERSION HUGO_ARCHIVE HUGO_URL HUGO_SHA256 D2_VERSION D2_ARCHIVE D2_URL D2_SHA256 CHECK_IMAGE CHECK_BOOTSTRAP_PACKAGES CHECK_BASE_PACKAGES CHECK_PACKAGES)

tools_die() { printf '%s: %s\n' "${script_name:-script}" "$*" >&2; exit 2; }

# Lecture ligne à ligne, jamais par « source » : tools.env est un fichier de données, pas du code.
load_tools_env() {
  local file=$1 line key value name
  [[ -f $file ]] || tools_die "tools.env introuvable ($file) : les versions épinglées sont obligatoires."
  [[ -r $file ]] || tools_die "tools.env illisible ($file)."
  for name in "${tools_env_expected[@]}"; do unset "$name" 2>/dev/null || true; done
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    [[ $line == [A-Z]*=* ]] || continue
    key=${line%%=*}
    value=${line#*=}
    # espaces de fin retirés, comme load_gitea_env le fait pour .env : « SHA=abc… » suivi d'une espace
    # invisible donnerait une empreinte qui ne correspond jamais, et un message accusant l'archive.
    value=${value%"${value##*[![:space:]]}"}
    for name in "${tools_env_expected[@]}"; do
      [[ $key == "$name" ]] || continue
      printf -v "$name" '%s' "$value"
      break
    done
  done < "$file"
  for name in "${tools_env_expected[@]}"; do
    [[ -n ${!name:-} ]] || tools_die "$name absente ou vide dans $file."
  done
}

# hugo affiche « hugo vX.Y.Z-<commit> linux/amd64 … » ; d2 affiche « vX.Y.Z ». On garde le premier
# groupe x.y.z rencontré, sans citer de version : elles ne se déclarent que dans tools.env.
tool_version() {
  local tool=$1 bin=$2 out rc=0
  out=$("$bin" version 2>/dev/null) || rc=$?
  if ((rc != 0)) || [[ -z $out ]]; then
    rc=0
    out=$("$bin" --version 2>/dev/null) || rc=$?
    ((rc == 0)) || { printf '%s: %s ne répond pas à « version » ni à « --version ».\n' "${script_name:-script}" "$tool" >&2; return 2; }
  fi
  out=$(printf '%s' "$out" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1) || true
  [[ -n $out ]] || { printf '%s: version de %s illisible.\n' "${script_name:-script}" "$tool" >&2; return 2; }
  printf '%s\n' "$out"
}

require_tool_version() {
  local tool=$1 bin=$2 expected=$3 found rc=0
  command -v "$bin" >/dev/null 2>&1 || [[ -x $bin ]] || {
    printf '%s: %s introuvable (%s). Lancer scripts/ci/install-tools.sh --local.\n' "${script_name:-script}" "$tool" "$bin" >&2
    return 1
  }
  found=$(tool_version "$tool" "$bin") || rc=$?
  ((rc == 0)) || return "$rc"
  if [[ $found != "$expected" ]]; then
    printf '%s: %s en version %s, alors que tools.env épingle %s.\n' "${script_name:-script}" "$tool" "$found" "$expected" >&2
    return 1
  fi
}
