#!/bin/bash
# ============================================================================
# update-dashboard.sh - Copy visualizations and push to GitHub Pages
# ============================================================================

# === CONFIGURATION ===
SOURCE_DIR="../dialbench/training/dial-rl/viz/visualizations"
REPO_DIR="."
PATTERN="reward_viz_*.html"
# === END CONFIGURATION ===

set -e
shopt -s nullglob

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")"

echo "=== Dashboard Update ==="
echo "Source: $SOURCE_DIR"
echo "Repo:   $REPO_DIR"
echo ""

# Validate directories
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$REPO_DIR/.git" ]; then
    echo "Error: Repo directory is not a git repository: $REPO_DIR"
    exit 1
fi

# Create visualizations directory if needed
mkdir -p "$REPO_DIR/visualizations"

# Copy files
echo "Copying visualization files..."
files=("$SOURCE_DIR"/$PATTERN)

if [ ${#files[@]} -eq 0 ]; then
    echo "No files matching $PATTERN found in $SOURCE_DIR"
    exit 1
fi

count=0
for f in "${files[@]}"; do
    cp "$f" "$REPO_DIR/visualizations/"
    echo "  $(basename "$f")"
    count=$((count + 1))
done
echo -e "${GREEN}Copied $count files${NC}"

# Generate manifest.json
echo ""
echo "Generating manifest.json..."
manifest="$REPO_DIR/manifest.json"

echo "{" > "$manifest"
echo "  \"updated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$manifest"
echo "  \"files\": [" >> "$manifest"

first=true
for f in "$REPO_DIR/visualizations"/$PATTERN; do
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$manifest"
    fi
    echo -n "    \"$(basename "$f")\"" >> "$manifest"
done

echo "" >> "$manifest"
echo "  ]" >> "$manifest"
echo "}" >> "$manifest"

echo "Manifest contains $(grep -c '\.html' "$manifest") files"

# Git operations
echo ""
echo "Pushing to GitHub..."
git add visualizations/ manifest.json

if git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
    exit 0
fi

git commit -m "Update dashboard: $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo ""
echo -e "${GREEN}✓ Dashboard updated successfully!${NC}"