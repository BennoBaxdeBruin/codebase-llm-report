#!/bin/bash

# Codebase Reporter - Genereert een markdown rapport van je codebase
# Gebruik: ./codebase-report.sh [directory] [output-file] [--no-markdown]

# Parse argumenten
TARGET_DIR="."
OUTPUT_FILE="codebase-report.md"
CREATE_MARKDOWN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --markdown)
            CREATE_MARKDOWN=true
            shift
            ;;
        --help|-h)
            echo "Gebruik: $0 [directory] [options]"
            echo "Opties:"
            echo "  --markdown       Maak ook een markdown bestand"
            echo "  --help, -h       Toon deze help"
            echo ""
            echo "Standaard: kopieert alleen naar clipboard"
            exit 0
            ;;
        -*)
            echo "Onbekende optie: $1"
            exit 1
            ;;
        *)
            if [[ "$TARGET_DIR" == "." ]]; then
                TARGET_DIR="$1"
            elif [[ "$OUTPUT_FILE" == "codebase-report.md" ]]; then
                OUTPUT_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Bestanden die we willen negeren (gebaseerd op je TypeScript config)
IGNORE_PATTERNS=(
    "node_modules"
    "dist"
    "build"
    ".git"
    ".vscode"
    "coverage"
    "*.min.js"
    "*.bundle.js"
    "*.map"
    ".next"
    ".nuxt"
    "out"
    "*.log"
    ".env*"
    ".DS_Store"
    "Thumbs.db"
    "package-lock.json"
    "poetry.lock"
    "yarn.lock"
    "pnpm-lock.yaml"
    ".gitignore"
    ".eslintrc*"
    ".prettierrc*"
    "vite.config.*"
    "vitest.config.*"
    "jest.config.*"
    "tailwind.config.*"
    "postcss.config.*"
    "webpack.config.*"
    "rollup.config.*"
    "babel.config.*"
    ".babelrc*"
    "LICENSE*"
    "README*"
    "CHANGELOG*"
    "CONTRIBUTING*"
    "codebase_to_md.ts"
    "codebase-to-md.config.json"
    "codebase-report.sh"
    "__pycache__"
    "*.pyc"
    "*.pyo"
    "*.pyd"
    ".pytest_cache"
    ".coverage"
    "htmlcov"
)

# Extensies die we willen includeren + specifieke bestanden
INCLUDE_EXTENSIONS=(
    "ts" "tsx" "js" "jsx"
    "json" "yml" "yaml"
    "css" "scss" "html"
    "vue" "py" "go" "rs"
    "java" "c" "cpp" "h"
    "php" "rb" "sh" "bash"
    "sql" "xml" "toml"
)

# Specifieke bestanden die we altijd willen includeren
INCLUDE_FILES=(
    "requirements.txt"
    "pyproject.toml"
    "package.json"
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.yaml"
    "Makefile"
)

# Functie om te checken of een bestand genegeerd moet worden
should_ignore() {
    local file="$1"
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Functie om te checken of een extensie geïncludeerd moet worden
should_include_extension() {
    local file="$1"
    local ext="${file##*.}"
    local basename=$(basename "$file")
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    # Check specifieke bestanden eerst
    for allowed_file in "${INCLUDE_FILES[@]}"; do
        if [[ "$basename" == "$allowed_file" ]]; then
            return 0
        fi
    done
    
    # Check extensies
    for allowed_ext in "${INCLUDE_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$allowed_ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Bepaal output bestemming
if [[ "$CREATE_MARKDOWN" == true ]]; then
    echo "📝 Genereren naar: $OUTPUT_FILE + clipboard"
else
    OUTPUT_FILE=$(mktemp)
    echo "📋 Alleen kopiëren naar clipboard..."
fi

# Start het rapport
echo "# Codebase Documentation" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "Generated on: $(date -Iseconds)" >> "$OUTPUT_FILE"
echo "Directory: $(realpath "$TARGET_DIR")" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Genereer mappenstructuur
echo "## 📁 Directory Structure" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"

# Gebruik tree als het beschikbaar is, anders een alternatief
if command -v tree &> /dev/null; then
    tree "$TARGET_DIR" -I "$(IFS='|'; echo "${IGNORE_PATTERNS[*]}")" >> "$OUTPUT_FILE"
else
# Betere tree functie die alleen ASCII gebruikt
generate_clean_tree() {
    local dir="$1"
    local prefix="$2"
    local is_last="$3"
    
    local items=()
    
    # Verzamel alle items
    for item in "$dir"/*; do
        if [[ -e "$item" ]]; then
            local basename=$(basename "$item")
            if ! should_ignore "$basename"; then
                items+=("$item")
            fi
        fi
    done
    
    # Sorteer items (directories eerst)
    local sorted_items=()
    for item in "${items[@]}"; do
        if [[ -d "$item" ]]; then
            sorted_items+=("$item")
        fi
    done
    for item in "${items[@]}"; do
        if [[ -f "$item" ]]; then
            sorted_items+=("$item")
        fi
    done
    
    # Print items
    local total=${#sorted_items[@]}
    for i in "${!sorted_items[@]}"; do
        local item="${sorted_items[$i]}"
        local basename=$(basename "$item")
        local is_item_last=$((i == total - 1))
        
        if [[ $is_item_last == 1 ]]; then
            echo "${prefix}└── $basename" >> "$OUTPUT_FILE"
            local new_prefix="${prefix}    "
        else
            echo "${prefix}├── $basename" >> "$OUTPUT_FILE"
            local new_prefix="${prefix}│   "
        fi
        
        if [[ -d "$item" ]]; then
            generate_clean_tree "$item" "$new_prefix" "$is_item_last"
        fi
    done
}
fi

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Genereer bestandsinhoud
echo "## 📄 File Contents" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Teller voor files
file_count=0
total_files=$(find "$TARGET_DIR" -type f | wc -l)

echo "📊 Processing files..."

# Vind alle relevante bestanden
find "$TARGET_DIR" -type f | while read -r file; do
    # Skip als het bestand genegeerd moet worden
    if should_ignore "$file"; then
        continue
    fi
    
    # Skip als de extensie niet geïncludeerd moet worden
    if ! should_include_extension "$file"; then
        continue
    fi
    
    # Skip binaire bestanden
    if file "$file" | grep -q "binary"; then
        continue
    fi
    
    # Relatief pad
    rel_path="${file#$TARGET_DIR/}"
    if [[ "$rel_path" == "$file" ]]; then
        rel_path="$(basename "$file")"
    fi
    
    # Verhoog teller en toon voortgang
    ((file_count++))
    echo "  [$file_count] Processing: $rel_path"
    
    echo "### $rel_path" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # File info toevoegen (zoals in je TypeScript versie)
    file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "unknown")
    if [[ "$file_size" != "unknown" ]]; then
        if [[ "$file_size" -lt 1024 ]]; then
            size_display="${file_size} B"
        elif [[ "$file_size" -lt 1048576 ]]; then
            size_display="$((file_size / 1024)) KB"
        else
            size_display="$((file_size / 1048576)) MB"
        fi
    else
        size_display="unknown"
    fi
    
    mod_date=$(stat -f%Sm -t%Y-%m-%d "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    
    echo "**Size:** $size_display | **Language:** $lang | **Modified:** $mod_date" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Detecteer programmeertaal voor syntax highlighting
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        js|jsx) lang="javascript" ;;
        ts|tsx) lang="typescript" ;;
        py) lang="python" ;;
        java) lang="java" ;;
        cpp|c|h) lang="cpp" ;;
        html) lang="html" ;;
        css|scss|sass) lang="css" ;;
        php) lang="php" ;;
        rb) lang="ruby" ;;
        go) lang="go" ;;
        rs) lang="rust" ;;
        swift) lang="swift" ;;
        vue) lang="vue" ;;
        dart) lang="dart" ;;
        sql) lang="sql" ;;
        sh|bash) lang="bash" ;;
        json) lang="json" ;;
        yaml|yml) lang="yaml" ;;
        md) lang="markdown" ;;
        *) lang="text" ;;
    esac
    
    echo "\`\`\`$lang" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo ""
echo "📈 Summary:"
echo "  • Total files processed: $file_count"
if [[ "$NO_MARKDOWN" == false ]]; then
    echo "  • Output file: $OUTPUT_FILE"
    echo "  • File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "✅ Rapport gegenereerd: $OUTPUT_FILE"
else
    echo "  • Mode: alleen clipboard"
    echo ""
    echo "✅ Rapport klaar voor clipboard"
fi

# Kopieer naar clipboard
if command -v pbcopy &> /dev/null; then
    # macOS
    cat "$OUTPUT_FILE" | pbcopy
    echo "📋 Rapport gekopieerd naar clipboard (macOS)"
elif command -v xclip &> /dev/null; then
    # Linux met xclip
    cat "$OUTPUT_FILE" | xclip -selection clipboard
    echo "📋 Rapport gekopieerd naar clipboard (Linux - xclip)"
elif command -v xsel &> /dev/null; then
    # Linux met xsel
    cat "$OUTPUT_FILE" | xsel --clipboard --input
    echo "📋 Rapport gekopieerd naar clipboard (Linux - xsel)"
elif command -v clip.exe &> /dev/null; then
    # Windows (WSL)
    cat "$OUTPUT_FILE" | clip.exe
    echo "📋 Rapport gekopieerd naar clipboard (Windows/WSL)"
else
    echo "⚠️  Clipboard tool niet gevonden. Installeer pbcopy (macOS), xclip/xsel (Linux), of gebruik WSL (Windows)"
    if [[ "$NO_MARKDOWN" == false ]]; then
        echo "Je kunt het bestand handmatig kopiëren: $OUTPUT_FILE"
    fi
fi

# Ruim tijdelijk bestand op als --no-markdown gebruikt werd
if [[ "$NO_MARKDOWN" == true ]]; then
    rm -f "$OUTPUT_FILE"
fi