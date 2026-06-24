#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Set CPPUTEST_HOME via env_vars.d JSON (handled by conda at activation time).
mkdir -p "${PREFIX}/etc/conda/env_vars.d"
printf '{"CPPUTEST_HOME": "%s"}\n' "${PREFIX}" > "${PREFIX}/etc/conda/env_vars.d/${PKG_NAME}.json"

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == 1 ]]; then
    BOOTSTRAP_CMAKE_ARGS=${CMAKE_ARGS//${PREFIX}/${BUILD_PREFIX}}
    BOOTSTRAP_CMAKE_ARGS=${BOOTSTRAP_CMAKE_ARGS//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}

    CROSS_LDFLAGS=${LDFLAGS}
    CROSS_CC="${CC}"
    CROSS_CXX="${CXX}"
    CROSS_LD="${LD}"

    LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}
    CC=${CC_FOR_BUILD}
    CXX=${CXX_FOR_BUILD}
    unset LD

    cmake -S . -B build_host \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -Wno-dev \
        -DBUILD_TESTING=OFF \
        ${BOOTSTRAP_CMAKE_ARGS}
    cmake --build build_host -j${CPU_COUNT}
    cmake --install build_host

    LDFLAGS="${CROSS_LDFLAGS}"
    CC=${CROSS_CC}
    CXX=${CROSS_CXX}
    LD=${CROSS_LD}

    sed -i -e "s,\$<TARGET_FILE:\${EXECUTABLE}>,$SRC_DIR/build_host/tests/CppUTest/CppUTestTests,g" cmake/modules/CppUTestBuildTimeDiscoverTests.cmake
fi

cmake -S . -B build \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -Wno-dev \
    -DBUILD_SHARED_LIBS=ON \
    ${CMAKE_ARGS}

cmake --build build -j${CPU_COUNT}
cmake --install build
