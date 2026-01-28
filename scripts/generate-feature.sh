#!/bin/bash

# ============================================
# Feature Module Generator
# ============================================
# Usage: ./scripts/generate-feature.sh <FeatureName> [options]
#
# Options:
#   --pattern mvi|mvvm    Architecture pattern (default: mvi)
#   --package <package>   Base package name
#   --output <dir>        Output directory (default: feature/)
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PATTERN="mvi"
BASE_PACKAGE="com.example"
OUTPUT_DIR="feature"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# Parse arguments
FEATURE_NAME=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --package)
            BASE_PACKAGE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 <FeatureName> [options]"
            echo ""
            echo "Options:"
            echo "  --pattern mvi|mvvm    Architecture pattern (default: mvi)"
            echo "  --package <package>   Base package name"
            echo "  --output <dir>        Output directory (default: feature/)"
            exit 0
            ;;
        *)
            if [[ -z "$FEATURE_NAME" ]]; then
                FEATURE_NAME="$1"
            fi
            shift
            ;;
    esac
done

# Validate feature name
if [[ -z "$FEATURE_NAME" ]]; then
    echo -e "${RED}Error: Feature name is required${NC}"
    echo "Usage: $0 <FeatureName>"
    exit 1
fi

# Convert names
FEATURE_LOWER=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]')
FEATURE_UPPER=$(echo "$FEATURE_NAME" | tr '[:lower:]' '[:upper:]')
FEATURE_CAMEL=$(echo "$FEATURE_NAME" | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//')

FULL_PACKAGE="$BASE_PACKAGE.feature.$FEATURE_LOWER"
PACKAGE_PATH=$(echo "$FULL_PACKAGE" | tr '.' '/')

echo -e "${BLUE}🚀 Generating $FEATURE_NAME feature module...${NC}"
echo -e "   Pattern: $PATTERN"
echo -e "   Package: $FULL_PACKAGE"
echo ""

# Create directory structure
FEATURE_DIR="$OUTPUT_DIR/$FEATURE_LOWER"
MAIN_DIR="$FEATURE_DIR/src/main/kotlin/$PACKAGE_PATH"
TEST_DIR="$FEATURE_DIR/src/test/kotlin/$PACKAGE_PATH"
ANDROID_TEST_DIR="$FEATURE_DIR/src/androidTest/kotlin/$PACKAGE_PATH"

mkdir -p "$MAIN_DIR/ui"
mkdir -p "$MAIN_DIR/navigation"
mkdir -p "$TEST_DIR"
mkdir -p "$ANDROID_TEST_DIR"

echo -e "${YELLOW}📁 Created directory structure${NC}"

# Function to process template
process_template() {
    local template=$1
    local output=$2

    if [[ -f "$template" ]]; then
        sed -e "s/{{FEATURE_NAME}}/$FEATURE_NAME/g" \
            -e "s/{{FEATURE_LOWER}}/$FEATURE_LOWER/g" \
            -e "s/{{FEATURE_UPPER}}/$FEATURE_UPPER/g" \
            -e "s/{{FEATURE_NAME_CAMEL}}/$FEATURE_CAMEL/g" \
            -e "s/{{PACKAGE}}/$FULL_PACKAGE/g" \
            -e "s/{{FULL_PACKAGE}}/$FULL_PACKAGE/g" \
            -e "s/{{DATA_TYPE}}/Any/g" \
            "$template" > "$output"
        echo -e "${GREEN}✅ $(basename "$output")${NC}"
    else
        echo -e "${RED}❌ Template not found: $template${NC}"
    fi
}

# Generate files based on pattern
if [[ "$PATTERN" == "mvi" ]]; then
    process_template "$TEMPLATE_DIR/mvi/Contract.kt.template" "$MAIN_DIR/${FEATURE_NAME}Contract.kt"
    process_template "$TEMPLATE_DIR/mvi/ViewModel.kt.template" "$MAIN_DIR/${FEATURE_NAME}ViewModel.kt"
    process_template "$TEMPLATE_DIR/mvi/Route.kt.template" "$MAIN_DIR/ui/${FEATURE_NAME}Route.kt"
    process_template "$TEMPLATE_DIR/mvi/Screen.kt.template" "$MAIN_DIR/ui/${FEATURE_NAME}Screen.kt"
    process_template "$TEMPLATE_DIR/mvi/Navigation.kt.template" "$MAIN_DIR/navigation/${FEATURE_NAME}Navigation.kt"
    process_template "$TEMPLATE_DIR/mvi/ViewModelTest.kt.template" "$TEST_DIR/${FEATURE_NAME}ViewModelTest.kt"
    process_template "$TEMPLATE_DIR/mvi/build.gradle.kts.template" "$FEATURE_DIR/build.gradle.kts"
fi

echo ""
echo -e "${GREEN}🎉 Feature module generated successfully!${NC}"
echo ""
echo -e "${BLUE}📁 Generated files:${NC}"
find "$FEATURE_DIR" -type f -name "*.kt" -o -name "*.kts" | sort | while read file; do
    echo "   $file"
done

echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "   1. Add module to settings.gradle.kts:"
echo "      include(\":feature:$FEATURE_LOWER\")"
echo ""
echo "   2. Implement UseCase dependencies in ViewModel"
echo ""
echo "   3. Add navigation route in your NavHost:"
echo "      ${FEATURE_CAMEL}Screen(onNavigateBack = { navController.popBackStack() })"
