#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${dir}/.."

# Stage 1 sync - intermediate to the ./vendir folder
set -x
vendir sync
helm dependency update helm/headlamp/
{ set +x; } 2>/dev/null

# Apply patches
for patch in sync/patches/*; do
    if [ -f "$patch" ]; then
        ./sync/patches/$(basename "$patch")/patch.sh
    fi
done

# Store diffs
rm -f ./diffs/*
for f in $(git --no-pager diff --no-exit-code --no-color --no-index vendor/headlamp helm --name-only) ; do
        [[ "$f" == "helm/headlamp/Chart.yaml" ]] && continue
        [[ "$f" == "helm/headlamp/Chart.lock" ]] && continue
        [[ "$f" == "helm/headlamp/README.md" ]] && continue
        [[ "$f" == "helm/headlamp/values.schema.json" ]] && continue
        [[ "$f" == "helm/headlamp/values.yaml" ]] && continue
        [[ "$f" =~ ^helm/headlamp/charts/.* ]] && continue

        base_file="vendor/headlamp/${f#"helm/"}"
        [[ ! -e $base_file ]] && base_file="/dev/null"

        set +e
        set -x
        git --no-pager diff --no-exit-code --no-color --no-index "$base_file" "${f}" \
                > "./diffs/${f//\//__}.patch"
        { set +x; } 2>/dev/null
        set -e
        ret=$?
        if [ $ret -ne 0 ] && [ $ret -ne 1 ] ; then
                exit $ret
        fi
done