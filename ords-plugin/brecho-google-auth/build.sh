#!/usr/bin/env bash
set -euo pipefail

ORDS_HOME="${ORDS_HOME:-/opt/ords}"
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORDS_PLUGIN_LIB="${ORDS_HOME}/examples/plugins/lib"
BUILD_ROOT="${PLUGIN_ROOT}/built"
CLASSES_DIR="${BUILD_ROOT}/classes"
OUTPUT_JAR="${BUILD_ROOT}/brecho-google-auth.jar"

if [[ ! -d "${ORDS_PLUGIN_LIB}" ]]; then
  echo "ORDS plugin libraries not found: ${ORDS_PLUGIN_LIB}" >&2
  exit 1
fi

rm -rf "${BUILD_ROOT}"
mkdir -p "${CLASSES_DIR}"

mapfile -t SOURCES < <(find "${PLUGIN_ROOT}/src" -type f -name '*.java' -print)
if [[ "${#SOURCES[@]}" -eq 0 ]]; then
  echo "No Java sources found under ${PLUGIN_ROOT}/src" >&2
  exit 1
fi

javac \
  -encoding UTF-8 \
  -source 17 \
  -target 17 \
  -g \
  -classpath "${ORDS_PLUGIN_LIB}/*" \
  -processorpath "${ORDS_PLUGIN_LIB}/ords-plugin-apt-25.4.0.364.1739.jar:${ORDS_PLUGIN_LIB}/ords-plugin-api-25.4.0.364.1739.jar:${ORDS_PLUGIN_LIB}/jakarta.inject-api-2.0.1.jar:${ORDS_PLUGIN_LIB}/jakarta.servlet-api-4.0.4.jar" \
  -d "${CLASSES_DIR}" \
  "${SOURCES[@]}"

jar --create --file "${OUTPUT_JAR}" -C "${CLASSES_DIR}" .

echo "Built: ${OUTPUT_JAR}"
jar --list --file "${OUTPUT_JAR}"
