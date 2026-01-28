#!/bin/bash

# ============================================
# Debug Log Detector
# ============================================
# Detects forbidden log statements in staged files
#
# Usage: ./scripts/detect-logs.sh
# ============================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Forbidden patterns
FORBIDDEN_PATTERNS=(
    "Log\.d\("
    "Log\.v\("
    "Log\.i\("
    "println\("
    "print\("
    "System\.out\."
    "System\.err\."
)

# Allowed patterns (these will be excluded from errors)
# ALLOWED_PATTERNS=(
#     "Timber\."
#     "Log\.w\("
#     "Log\.e\("
# )

echo "🔍 Checking for debug log statements..."
echo ""

# Get staged Kotlin files
FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E "\.kt$" || true)

if [[ -z "$FILES" ]]; then
    echo -e "${GREEN}✅ No Kotlin files staged${NC}"
    exit 0
fi

FOUND=0
ISSUES=""

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    while IFS= read -r file; do
        if [[ -n "$file" && -f "$file" ]]; then
            # Skip test files
            if [[ "$file" == *"/test/"* || "$file" == *"/androidTest/"* ]]; then
                continue
            fi

            MATCHES=$(grep -n "$pattern" "$file" 2>/dev/null || true)
            if [[ -n "$MATCHES" ]]; then
                FOUND=1
                echo -e "${RED}❌ Found in: $file${NC}"
                echo "$MATCHES" | while read match; do
                    LINE_NUM=$(echo "$match" | cut -d: -f1)
                    LINE_CONTENT=$(echo "$match" | cut -d: -f2-)
                    echo -e "   ${YELLOW}Line $LINE_NUM:${NC} $LINE_CONTENT"
                done
                echo ""
            fi
        fi
    done <<< "$FILES"
done

if [[ $FOUND -eq 1 ]]; then
    echo ""
    echo -e "${RED}❌ Commit blocked: Remove debug logs before committing${NC}"
    echo ""
    echo -e "${YELLOW}💡 Suggestions:${NC}"
    echo "   - Use Timber instead: Timber.d(\"message\")"
    echo "   - Timber is stripped in release builds"
    echo ""
    echo "   To bypass (emergency only):"
    echo "   git commit --no-verify"
    exit 1
fi

echo -e "${GREEN}✅ No forbidden log statements found${NC}"
exit 0
