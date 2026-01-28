#!/bin/bash

# ============================================
# Compose Stability Analyzer
# ============================================
# Analyzes Compose Compiler reports to find stability issues
#
# Usage: ./scripts/analyze-compose-stability.sh [module]
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

MODULE=${1:-"app"}
REPORT_DIR="$MODULE/build/compose-reports"

echo -e "${BLUE}🔍 Compose Stability Analyzer${NC}"
echo "================================"
echo ""

# Check if reports exist
if [[ ! -d "$REPORT_DIR" ]]; then
    echo -e "${YELLOW}⚠️  Reports not found. Generating...${NC}"
    echo ""
    ./gradlew :$MODULE:assembleRelease \
        -PcomposeCompilerReports=true \
        -PcomposeCompilerMetrics=true \
        --quiet
fi

# Find report files
CLASSES_FILE=$(find "$REPORT_DIR" -name "*-classes.txt" 2>/dev/null | head -1)
COMPOSABLES_FILE=$(find "$REPORT_DIR" -name "*-composables.txt" 2>/dev/null | head -1)
METRICS_FILE=$(find "$REPORT_DIR" -name "*-module.json" 2>/dev/null | head -1)

if [[ -z "$CLASSES_FILE" ]]; then
    echo -e "${RED}❌ No report files found in $REPORT_DIR${NC}"
    echo "   Run: ./gradlew assembleRelease -PcomposeCompilerReports=true"
    exit 1
fi

echo -e "${CYAN}📊 Analysis Results${NC}"
echo "==================="
echo ""

# Analyze unstable classes
echo -e "${YELLOW}🔴 Unstable Classes:${NC}"
if [[ -f "$CLASSES_FILE" ]]; then
    UNSTABLE_COUNT=$(grep -c "^unstable class" "$CLASSES_FILE" 2>/dev/null || echo "0")
    STABLE_COUNT=$(grep -c "^stable class" "$CLASSES_FILE" 2>/dev/null || echo "0")
    TOTAL=$((UNSTABLE_COUNT + STABLE_COUNT))

    if [[ $UNSTABLE_COUNT -gt 0 ]]; then
        grep "^unstable class" "$CLASSES_FILE" | while read line; do
            CLASS_NAME=$(echo "$line" | sed 's/unstable class //' | cut -d' ' -f1)
            echo -e "   ${RED}❌ $CLASS_NAME${NC}"

            # Show unstable properties
            grep -A 20 "^unstable class $CLASS_NAME" "$CLASSES_FILE" | \
                grep "unstable val\|unstable var" | head -5 | while read prop; do
                echo -e "      └─ $prop"
            done
        done
    else
        echo -e "   ${GREEN}✅ No unstable classes found!${NC}"
    fi

    echo ""
    echo -e "   Total: $STABLE_COUNT stable, $UNSTABLE_COUNT unstable"
    STABILITY_RATE=$((STABLE_COUNT * 100 / TOTAL))
    if [[ $STABILITY_RATE -ge 90 ]]; then
        echo -e "   Stability Rate: ${GREEN}$STABILITY_RATE%${NC}"
    elif [[ $STABILITY_RATE -ge 70 ]]; then
        echo -e "   Stability Rate: ${YELLOW}$STABILITY_RATE%${NC}"
    else
        echo -e "   Stability Rate: ${RED}$STABILITY_RATE%${NC}"
    fi
fi

echo ""

# Analyze non-skippable composables
echo -e "${YELLOW}🟡 Non-Skippable Composables:${NC}"
if [[ -f "$COMPOSABLES_FILE" ]]; then
    NOT_SKIPPABLE=$(grep "restartable but not skippable" "$COMPOSABLES_FILE" 2>/dev/null || true)

    if [[ -n "$NOT_SKIPPABLE" ]]; then
        echo "$NOT_SKIPPABLE" | head -10 | while read line; do
            FUNC_NAME=$(echo "$line" | grep -o "fun [A-Za-z]*" | head -1)
            echo -e "   ${YELLOW}⚠️  $FUNC_NAME${NC} - not skippable"
        done

        NOT_SKIPPABLE_COUNT=$(echo "$NOT_SKIPPABLE" | wc -l | tr -d ' ')
        TOTAL_COMPOSABLES=$(grep -c "^restartable" "$COMPOSABLES_FILE" 2>/dev/null || echo "0")
        SKIPPABLE_COUNT=$((TOTAL_COMPOSABLES - NOT_SKIPPABLE_COUNT))

        echo ""
        echo -e "   Total: $SKIPPABLE_COUNT skippable, $NOT_SKIPPABLE_COUNT not skippable"
    else
        echo -e "   ${GREEN}✅ All composables are skippable!${NC}"
    fi
fi

echo ""

# Summary and recommendations
echo -e "${CYAN}📋 Recommendations:${NC}"
echo "==================="

if [[ $UNSTABLE_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}1. Fix Unstable Classes:${NC}"
    echo "   - Use @Immutable annotation for UI state classes"
    echo "   - Replace List<T> with ImmutableList<T>"
    echo "   - Replace Map<K,V> with ImmutableMap<K,V>"
    echo ""
    echo "   Example fix:"
    echo "   ${CYAN}@Immutable"
    echo "   data class UiState("
    echo "       val items: ImmutableList<Item>  // was List<Item>"
    echo "   )${NC}"
fi

if [[ -n "$NOT_SKIPPABLE" ]]; then
    echo ""
    echo -e "${YELLOW}2. Fix Non-Skippable Composables:${NC}"
    echo "   - Ensure all parameters are stable"
    echo "   - Use remember { } for lambda callbacks"
    echo "   - Hoist state to parent composables"
    echo ""
    echo "   Example fix:"
    echo "   ${CYAN}@Composable"
    echo "   fun Parent() {"
    echo "       val onClick = remember { { doSomething() } }"
    echo "       Child(onClick = onClick)  // now stable"
    echo "   }${NC}"
fi

echo ""
echo -e "${GREEN}✅ Analysis complete!${NC}"
