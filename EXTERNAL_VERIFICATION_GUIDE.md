# External Verification Guide: Sailing Quest Detection

## Purpose
This guide helps you verify the Sailing quest theory and test the fix externally using the OSRS hiscores API.

## Theory Summary
The Sailing skill requires a quest to unlock:
- **F2P players WITHOUT quest**: Sailing line missing from API (24 skills total)
- **F2P players WITH quest**: Sailing line present at level 1 (25 skills total)
- **P2P players**: Sailing line present with trained level

## External Checks You Can Run

### 1. Check a Known F2P Player WITHOUT Sailing Quest

**Test Player Criteria:**
- Confirmed F2P account
- Has NOT done the Sailing quest
- Should have 24 skill lines in hiscores

**API Call:**
```bash
curl "https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player=PLAYERNAME"
```

**Expected Result:**
```
12345,838,15000000    # Line 0: Overall
...                    # Lines 1-23: Skills (ending with Construction)
-1,0                   # Line 24: Grid Points (FIRST ACTIVITY)
-1,100                 # Line 25: League Points
```

**Count the lines:**
```bash
curl "https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player=PLAYERNAME" | head -30 | cat -n
```

If line 24 has **2 values** (rank,score), Sailing is missing.

---

### 2. Check a Known F2P Player WITH Sailing Quest

**Test Player Criteria:**
- Confirmed F2P account
- HAS done the Sailing quest
- Should have 25 skill lines in hiscores

**API Call:**
```bash
curl "https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player=PLAYERNAME"
```

**Expected Result:**
```
12345,838,15000000    # Line 0: Overall
...                    # Lines 1-23: Skills (ending with Construction)
-1,1,0                 # Line 24: Sailing (SKILL with 3 values!)
-1,0                   # Line 25: Grid Points (first activity)
-1,100                 # Line 26: League Points
```

If line 24 has **3 values** (rank,level,xp), Sailing is present.

---

### 3. Detection Script

Save this as `check_sailing.sh`:

```bash
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <playername>"
    exit 1
fi

PLAYER="$1"
URL="https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player=$PLAYER"

echo "Checking player: $PLAYER"
echo "================================"

# Fetch hiscores
RESPONSE=$(curl -s "$URL")

if [ -z "$RESPONSE" ]; then
    echo "❌ Could not fetch hiscores (player may not exist)"
    exit 1
fi

# Get line 24 (0-indexed as line 25)
LINE_24=$(echo "$RESPONSE" | sed -n '25p')

if [ -z "$LINE_24" ]; then
    echo "❌ Less than 25 lines in response"
    exit 1
fi

# Count comma-separated values
VALUE_COUNT=$(echo "$LINE_24" | awk -F',' '{print NF}')

echo "Line 24 content: $LINE_24"
echo "Number of values: $VALUE_COUNT"
echo ""

if [ "$VALUE_COUNT" -eq 3 ]; then
    echo "✅ SAILING PRESENT (3 values = skill format)"
    echo "   Player has done the Sailing quest"
    echo "   Total level should be: F2P sum + 9"
elif [ "$VALUE_COUNT" -eq 2 ]; then
    echo "✅ SAILING ABSENT (2 values = activity format)"
    echo "   Player has NOT done the Sailing quest"
    echo "   Total level should be: F2P sum + 8"
else
    echo "⚠️  UNEXPECTED FORMAT ($VALUE_COUNT values)"
fi

# Show overall level
OVERALL=$(echo "$RESPONSE" | sed -n '1p' | cut -d',' -f2)
echo ""
echo "Overall level: $OVERALL"
```

**Usage:**
```bash
chmod +x check_sailing.sh
./check_sailing.sh "PlayerName"
```

---

### 4. Python Script (More Detailed)

Save as `verify_sailing.py`:

```python
#!/usr/bin/env python3
import requests
import sys

def check_sailing(player_name):
    url = f"https://secure.runescape.com/m=hiscore_oldschool/index_lite.ws?player={player_name}"
    
    print(f"Checking player: {player_name}")
    print("=" * 50)
    
    try:
        response = requests.get(url)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"❌ Error fetching hiscores: {e}")
        return
    
    lines = response.text.strip().split('\n')
    
    print(f"Total lines: {len(lines)}")
    
    if len(lines) < 25:
        print("❌ Less than 25 lines (unexpected)")
        return
    
    # Check line 24 (0-indexed)
    line_24 = lines[24]
    values = line_24.split(',')
    
    print(f"\nLine 24: {line_24}")
    print(f"Value count: {len(values)}")
    
    if len(values) == 3:
        print("\n✅ SAILING PRESENT")
        print("   Format: rank,level,xp (skill)")
        print("   Player has done the Sailing quest")
        print("   Expected P2P skills: 9")
        sailing_level = values[1]
        print(f"   Sailing level: {sailing_level}")
    elif len(values) == 2:
        print("\n✅ SAILING ABSENT")
        print("   Format: rank,score (activity)")
        print("   Player has NOT done Sailing quest")
        print("   Expected P2P skills: 8")
    else:
        print(f"\n⚠️  UNEXPECTED FORMAT ({len(values)} values)")
    
    # Show overall level
    overall_parts = lines[0].split(',')
    overall_level = overall_parts[1]
    print(f"\nOverall level: {overall_level}")
    
    # Show lines 23-26 for context
    print("\nContext (lines 23-26):")
    for i in range(23, min(27, len(lines))):
        label = ["Construction", "Sailing/Activity", "Activity", "Activity"][i-23]
        print(f"  Line {i}: {lines[i]:20} # {label}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 verify_sailing.py <playername>")
        sys.exit(1)
    
    check_sailing(sys.argv[1])
```

**Usage:**
```bash
python3 verify_sailing.py "PlayerName"
```

---

## Test Cases to Verify

### Recommended Test Players

1. **Known F2P without Sailing quest** (if you can identify one)
   - Expected: 24 skills, overall = 837 or less
   - Line 24 should be Grid Points (2 values)

2. **Known F2P with Sailing quest** (if you can identify one)
   - Expected: 25 skills, overall = 838 or less (but > 837)
   - Line 24 should be Sailing with level 1 (3 values)

3. **P2P player with trained Sailing**
   - Expected: 25 skills, Sailing level > 1
   - Should be correctly detected as P2P

---

## What to Look For

### ✅ Good Signs
- F2P players with 24 skills are NOT rejected
- F2P players with 25 skills (Sailing=1) are NOT rejected
- P2P players with Sailing > 1 ARE rejected
- Activities parse correctly regardless of Sailing presence

### ❌ Bad Signs
- F2P players with 24 skills still rejected
- Activity parsing is broken (wrong boss KC, clue counts)
- Verification logic fails for legitimate F2P players

---

## Sharing Results

Please share:
1. Player name (if public)
2. Line 24 content
3. Overall level
4. Whether they were accepted/rejected
5. Expected outcome vs actual outcome

This will help verify the fix works correctly for all scenarios.

---

## Technical Details

### Detection Logic
```ruby
# In hiscores.rb parser
sailing_present = false
if lines.length > 24
  line_24_values = lines[24].split(',').map(&:strip)
  sailing_present = line_24_values.length >= 3  # 3 = skill, 2 = activity
end
```

### Verification Logic
```ruby
# In player.rb verification
members_count = parsed_count  # 8 or 9 depending on Sailing
expected_overall = f2p_sum + members_sum
if overall > expected_overall
  # Mark as P2P
end
```

The key is that verification uses the **actual parsed count**, not a hard-coded expectation.
