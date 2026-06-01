#!/usr/bin/env bash
set -euo pipefail

TARGET="external/QuantumComputingMachineLearning"
REPO="https://github.com/CompPhysics/QuantumComputingMachineLearning.git"
BRANCH="gh-pages"

mkdir -p external

if [ ! -d "$TARGET/.git" ]; then
    git clone --depth 1 --branch "$BRANCH" --filter=blob:none --sparse "$REPO" "$TARGET"
    git -C "$TARGET" sparse-checkout set \
        README.md \
        LLM_Usage_Declaration_Guidelines.md \
        doc/pub/week1 \
        doc/pub/week2 \
        doc/pub/week3 \
        doc/pub/week4 \
        doc/pub/week5 \
        doc/pub/week6 \
        doc/pub/week7 \
        doc/pub/week8 \
        doc/pub/week9
else
    git -C "$TARGET" pull --ff-only
fi

echo "Course sources available locally in $TARGET"
echo "This directory is ignored by Git and should not be committed."
