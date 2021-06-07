#!/bin/bash

set -euo pipefail

echo "Start copying dSYMs at `date`"

# Typicaly dSYMs would only be copied when profiling (and are required by Instruments).
# In this case, we aren't sure what confiuration is used for profiling,
# so just copy them over if they exist.

readonly dsym_input="bazel-bin/$BAZEL_BIN_SUBDIR/${FULL_PRODUCT_NAME}.dSYM"
readonly dsym_output="$TARGET_BUILD_DIR"

rsync \
  --recursive --chmod=u+w --delete -i \
  "$dsym_input" "$dsym_output"

