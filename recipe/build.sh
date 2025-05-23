#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

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
