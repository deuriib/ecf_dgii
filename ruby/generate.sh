#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SPEC_PATH="${SPEC_PATH:-../ios/openapi-v1-processed.json}"
OPENAPI_GEN_VERSION="7.14.0"
NPX_PKG="@openapitools/openapi-generator-cli@2.32.0"

GENERATED_DIR="lib/ecf_dgii/generated"
TEMP_GEN_DIR="ecf_dgii_generated"

echo "Removing old generated code..."
rm -rf "$GENERATED_DIR"
rm -rf "$TEMP_GEN_DIR"

echo "Generating Ruby SDK from $SPEC_PATH..."
JAVA_OPTS="-Xmx4g" OPENAPI_GENERATOR_VERSION=$OPENAPI_GEN_VERSION \
  npx -y $NPX_PKG generate \
    -c openapi-generator-config.yaml \
    -i "$SPEC_PATH" \
    -o "$TEMP_GEN_DIR"

echo "Moving generated library code..."
mkdir -p "lib/ecf_dgii"
mv "$TEMP_GEN_DIR/lib/ecf_dgii_generated" "$GENERATED_DIR"

echo "Adjusting internal requires..."
# Reemplazar requires en todos los archivos generados
find "$GENERATED_DIR" -type f -name "*.rb" -exec sed -i "s|require 'ecf_dgii_generated/|require 'ecf_dgii/generated/|g" {} +

echo "Cleaning up temporal directory..."
rm -rf "$TEMP_GEN_DIR"

echo "Done. Generated code is in $GENERATED_DIR/"
