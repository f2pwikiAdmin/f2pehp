#!/bin/bash
# Quick Sailing Detection Test
# Run this to verify if Sailing quest is members-only

echo "======================================"
echo "Sailing Quest Verification Test"
echo "======================================"
echo ""
echo "We need to test 2-3 players to confirm:"
echo ""
echo "TEST 1: Known F2P player"
echo "  Expected: 24 skill lines (NO Sailing)"
echo "  Line 24 should be Grid Points (2 values)"
echo ""
echo "TEST 2: Known P2P player (any level)"
echo "  Expected: 25 skill lines (Sailing present)"
echo "  Line 24 should be Sailing (3 values)"
echo ""
echo "TEST 3: P2P player who hasn't trained Sailing"
echo "  Expected: 25 skill lines, Sailing at level 1"
echo "  This would confirm quest unlocks it"
echo ""
echo "======================================"
echo ""

if [ -z "$1" ]; then
    echo "Usage: $0 <playername>"
    echo ""
    echo "Example players to test:"
    echo "  ./test_sailing.sh YourF2PAccount"
    echo "  ./test_sailing.sh YourP2PAccount"
    exit 1
fi

PLAYER="$1"
URL="https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player=$PLAYER"

echo "Testing player: $PLAYER"
echo "Fetching from API..."
echo ""

# Fetch hiscores
RESPONSE=$(curl -s "$URL")

if [ -z "$RESPONSE" ]; then
    echo "❌ ERROR: Could not fetch hiscores"
    echo "   - Player may not exist"
    echo "   - API may be down"
    echo "   - Check player name spelling"
    exit 1
fi

# Count total lines
TOTAL_LINES=$(echo "$RESPONSE" | wc -l)
echo "Total lines in response: $TOTAL_LINES"
echo ""

# Get line 24 (0-indexed, so line 25 in output)
LINE_24=$(echo "$RESPONSE" | sed -n '25p')

if [ -z "$LINE_24" ]; then
    echo "❌ Less than 25 lines (unexpected)"
    exit 1
fi

# Count values in line 24
VALUE_COUNT=$(echo "$LINE_24" | awk -F',' '{print NF}')

echo "Line 24 content: $LINE_24"
echo "Number of values: $VALUE_COUNT"
echo ""

# Show overall level
OVERALL=$(echo "$RESPONSE" | sed -n '1p' | cut -d',' -f2)
echo "Overall level: $OVERALL"
echo ""

echo "======================================"
echo "ANALYSIS:"
echo "======================================"

if [ "$VALUE_COUNT" -eq 3 ]; then
    SAILING_LEVEL=$(echo "$LINE_24" | cut -d',' -f2)
    echo "✅ SAILING IS PRESENT"
    echo "   Format: rank,level,xp (SKILL)"
    echo "   Sailing level: $SAILING_LEVEL"
    echo ""
    echo "   → This player has MEMBERSHIP (P2P)"
    echo "   → Sailing quest requires membership OR it's trained"
elif [ "$VALUE_COUNT" -eq 2 ]; then
    echo "✅ SAILING IS ABSENT"
    echo "   Format: rank,score (ACTIVITY)"
    echo "   Line 24 is: Grid Points (first activity)"
    echo ""
    echo "   → This player is F2P"
    echo "   → F2P players cannot access Sailing"
else
    echo "⚠️  UNEXPECTED FORMAT"
fi

echo ""
echo "======================================"
echo "Next steps:"
echo "======================================"
echo "Test multiple players and report back:"
echo "  1. A confirmed F2P player"
echo "  2. A confirmed P2P player"
echo "  3. A P2P player who hasn't trained Sailing (if possible)"
echo ""
echo "Report: Player name, overall level, line 24 content"
