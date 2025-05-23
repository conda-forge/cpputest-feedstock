#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

cmake -S test -B build -G "Unix Makefiles" -DCMAKE_FIND_ROOT_PATH=$CONDA_PREFIX
cmake --build build --target all
cd build
ctest -V .
