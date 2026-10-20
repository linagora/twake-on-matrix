#!/usr/bin/env bash
# Measures what is left of the Riverpod migration.
#
# Usage:
#   scripts/migration_status.sh                 print the metrics of the working tree
#   scripts/migration_status.sh --check <ref>   fail if a legacy metric grew since <ref>
#   scripts/migration_status.sh --write         refresh the table in MIGRATION_STATUS.md
#
# Only tracked files are measured: `git add` new files before a check.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATUS_FILE="MIGRATION_STATUS.md"
EXCLUDES=(':!*.g.dart' ':!*.freezed.dart' ':!*.mocks.dart')
# Riverpod providers that wrap a GetIt registration on purpose.
BRIDGES=(':!*.provider.dart' ':!*_providers.dart')

# Legacy metrics: a pull request may not increase them.
LEGACY=(matrix_of get_it_lookups get_it_registrations stream_either dartz_imports app_state_files)
# Progress metrics: shown, never checked.
PROGRESS=(get_it_bridges riverpod_providers notifiers consumer_widgets stateful_widgets matrix_imports_in_ui)

label() {
  case "$1" in
    matrix_of) echo '`Matrix.of` / `Matrix.read` calls' ;;
    get_it_lookups) echo '`getIt` lookups outside providers' ;;
    get_it_registrations) echo '`getIt.register*` calls' ;;
    stream_either) echo '`Stream<Either<…>>`' ;;
    dartz_imports) echo 'Files importing `dartz`' ;;
    app_state_files) echo 'Files in `lib/domain/app_state/`' ;;
    get_it_bridges) echo '`getIt` lookups inside providers (bridges)' ;;
    riverpod_providers) echo '`@riverpod` providers' ;;
    notifiers) echo 'Notifier classes' ;;
    consumer_widgets) echo 'Consumer widgets' ;;
    stateful_widgets) echo '`StatefulWidget`s' ;;
    matrix_imports_in_ui) echo 'UI files importing `package:matrix`' ;;
  esac
}

# Counts the lines matching a pattern, at a ref or in the working tree.
count_lines() {
  local ref="$1" pattern="$2"
  shift 2
  grep_or_none -h "$ref" "$pattern" "$@" | wc -l | tr -d ' '
}

count_files() {
  local ref="$1" pattern="$2"
  shift 2
  grep_or_none -l "$ref" "$pattern" "$@" | wc -l | tr -d ' '
}

# `git grep` exits 1 when nothing matches: that is a count of zero, not an
# error. Any other status still fails the script.
grep_or_none() {
  local mode="$1" ref="$2" pattern="$3" status=0
  shift 3
  if [ -n "$ref" ]; then
    git grep "$mode" -E "$pattern" "$ref" -- "$@" || status=$?
  else
    git grep "$mode" -E "$pattern" -- "$@" || status=$?
  fi
  [ "$status" -le 1 ]
}

count_tree() {
  local ref="$1" dir="$2"
  if [ -n "$ref" ]; then
    git ls-tree -r --name-only "$ref" -- "$dir" | wc -l | tr -d ' '
  else
    git ls-files -- "$dir" | wc -l | tr -d ' '
  fi
}

metric() {
  local ref="$1" name="$2"
  local get_it='getIt\.get|getIt<|getIt\(\)'
  case "$name" in
    matrix_of) count_lines "$ref" 'Matrix\.(of|read)\(' lib "${EXCLUDES[@]}" ;;
    get_it_lookups) count_lines "$ref" "$get_it" lib ':!lib/di/' "${EXCLUDES[@]}" "${BRIDGES[@]}" ;;
    get_it_registrations) count_lines "$ref" '\.register(Factory|Singleton|LazySingleton)' lib "${EXCLUDES[@]}" ;;
    stream_either) count_lines "$ref" 'Stream<Either<' lib "${EXCLUDES[@]}" ;;
    dartz_imports) count_files "$ref" "package:dartz/" lib "${EXCLUDES[@]}" ;;
    app_state_files) count_tree "$ref" lib/domain/app_state ;;
    get_it_bridges) count_lines "$ref" "$get_it" '*.provider.dart' '*_providers.dart' "${EXCLUDES[@]}" ;;
    riverpod_providers) count_lines "$ref" '^@(riverpod|Riverpod\()' lib "${EXCLUDES[@]}" ;;
    notifiers) count_lines "$ref" 'extends _\$[A-Za-z0-9]+' lib "${EXCLUDES[@]}" ;;
    consumer_widgets) count_lines "$ref" 'extends (ConsumerWidget|ConsumerStatefulWidget)([^A-Za-z0-9_]|$)' lib "${EXCLUDES[@]}" ;;
    stateful_widgets) count_lines "$ref" 'extends StatefulWidget([^A-Za-z0-9_]|$)' lib "${EXCLUDES[@]}" ;;
    matrix_imports_in_ui) count_files "$ref" "^import 'package:matrix/" lib/pages lib/widgets lib/presentation "${EXCLUDES[@]}" ;;
  esac
}

table() {
  echo '| Metric | Count |'
  echo '|---|---:|'
  for name in "${LEGACY[@]}"; do
    echo "| $(label "$name") | $(metric "" "$name") |"
  done
  echo
  echo '| Progress | Count |'
  echo '|---|---:|'
  for name in "${PROGRESS[@]}"; do
    echo "| $(label "$name") | $(metric "" "$name") |"
  done
}

check() {
  local base="$1" failed=0 before after
  echo "| Metric | Base | This branch | |"
  echo '|---|---:|---:|---|'
  for name in "${LEGACY[@]}"; do
    before=$(metric "$base" "$name")
    after=$(metric "" "$name")
    if [ "$after" -gt "$before" ]; then
      echo "| $(label "$name") | $before | $after | ❌ grew |"
      failed=1
    elif [ "$after" -lt "$before" ]; then
      echo "| $(label "$name") | $before | $after | ✅ shrank |"
    else
      echo "| $(label "$name") | $before | $after | |"
    fi
  done
  for name in "${PROGRESS[@]}"; do
    echo "| $(label "$name") | $(metric "$base" "$name") | $(metric "" "$name") | info |"
  done
  if [ "$failed" -eq 1 ]; then
    echo
    echo 'A legacy metric grew. New code goes through Riverpod: see docs/migration/.'
  fi
  return "$failed"
}

write() {
  local begin='<!-- metrics:begin -->' end='<!-- metrics:end -->' tmp
  tmp=$(mktemp)
  {
    echo "$begin"
    echo "_Measured on $(git log -1 --format=%cs) at \`$(git rev-parse --short HEAD)\` by \`scripts/migration_status.sh --write\`._"
    echo
    table
    echo "$end"
  } >"$tmp"
  awk -v begin="$begin" -v end="$end" -v table="$tmp" '
    $0 == begin { while ((getline line < table) > 0) print line; skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$STATUS_FILE" >"$STATUS_FILE.new"
  mv "$STATUS_FILE.new" "$STATUS_FILE"
  rm -f "$tmp"
}

case "${1:-}" in
  --check) check "${2:?usage: --check <ref>}" ;;
  --write) write ;;
  "") table ;;
  *) echo "usage: $0 [--check <ref> | --write]" >&2; exit 2 ;;
esac
