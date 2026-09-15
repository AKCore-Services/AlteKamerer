#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '\n=== Required toolchain ===\n'

command -v flutter >/dev/null || {
    echo "Flutter is not installed in the CI environment." >&2
    exit 1
}

command -v java >/dev/null || {
    echo "Java is not installed in the CI environment." >&2
    exit 1
}

: "${ANDROID_SDK_ROOT:?ANDROID_SDK_ROOT is not set}"

test -f "${ANDROID_SDK_ROOT}/platforms/android-37.0/android.jar" || {
    echo "Android platform 37.0 is missing." >&2
    exit 1
}

test -x "${ANDROID_SDK_ROOT}/build-tools/36.0.0/aapt" || {
    echo "Android Build Tools 36.0.0 are missing." >&2
    exit 1
}

test -x \
    "${ANDROID_SDK_ROOT}/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" || {
    echo "Android NDK 28.2.13676358 is missing." >&2
    exit 1
}

flutter --version
java -version

printf '\n=== Dependencies ===\n'

cd "${REPO_ROOT}"
flutter pub get

printf '\n=== Analysis ===\n'

flutter analyze

printf '\n=== Tests ===\n'

flutter test --reporter compact

printf '\n=== AlteKamerer validation passed ===\n'
