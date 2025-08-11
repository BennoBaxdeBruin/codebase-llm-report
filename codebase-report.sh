#!/bin/bash

# Codebase Reporter - Generates markdown reports of your codebase
# Usage: ./codebase-report.sh [directory] [output-file] [options]

# Parse arguments
TARGET_DIR="."
OUTPUT_FILE="codebase-report.md"
CREATE_MARKDOWN=false
FOLDER_STRUCTURE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --markdown)
            CREATE_MARKDOWN=true
            shift
            ;;
        --folder_structure_only)
            FOLDER_STRUCTURE_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [directory] [options]"
            echo "Options:"
            echo "  --markdown              Also create markdown file"
            echo "  --folder_structure_only Only generate directory structure"
            echo "  --help, -h              Show this help"
            echo ""
            echo "Default: copies only to clipboard"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
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

# Files to ignore
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
    "data"
    "output"
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

# Extensions to include
INCLUDE_EXTENSIONS=(
    "ts" "tsx" "js" "jsx"
    "json" "yml" "yaml"
    "css" "scss" "html"
    "vue" "py" "go" "rs"
    "java" "c" "cpp" "h"
    "php" "rb" "sh" "bash"
    "sql" "xml" "toml"
)

# Specific files to always include
INCLUDE_FILES=(
    "requirements.txt"
    "pyproject.toml"
    "package.json"
    "Dockerfile"
    "docker-compose.yml"
    "docker-compose.yaml"
    "Makefile"
)

# Function to check if a file should be ignored
should_ignore() {
    local file="$1"
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if an extension should be included
should_include_extension() {
    local file="$1"
    local ext="${file##*.}"
    local basename=$(basename "$file")
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    # Check specific files first
    for allowed_file in "${INCLUDE_FILES[@]}"; do
        if [[ "$basename" == "$allowed_file" ]]; then
            return 0
        fi
    done
    
    # Check extensions
    for allowed_ext in "${INCLUDE_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$allowed_ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Generate clean tree function using ASCII only
generate_clean_tree() {
    local dir="$1"
    local prefix="$2"
    local is_last="$3"
    
    local items=()
    
    # Collect all items
    for item in "$dir"/*; do
        if [[ -e "$item" ]]; then
            local basename=$(basename "$item")
            if ! should_ignore "$basename"; then
                items+=("$item")
            fi
        fi
    done
    
    # Sort items (directories first)
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

# Determine output destination
if [[ "$CREATE_MARKDOWN" == true ]]; then
    if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
        echo "📁 Generating folder structure to: $OUTPUT_FILE + clipboard"
    else
        echo "📝 Generating to: $OUTPUT_FILE + clipboard"
    fi
else
    OUTPUT_FILE=$(mktemp)
    if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
        echo "📁 Copying folder structure to clipboard only..."
    else
        echo "📋 Copying to clipboard only..."
    fi
fi

# Start the report
if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
    echo "# Directory Structure" > "$OUTPUT_FILE"
else
    echo "# Codebase Documentation" > "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"
echo "Generated on: $(date -Iseconds)" >> "$OUTPUT_FILE"
echo "Directory: $(realpath "$TARGET_DIR")" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Generate directory structure
if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
    echo "## Structure" >> "$OUTPUT_FILE"
else
    echo "## Directory Structure" >> "$OUTPUT_FILE"
fi
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"

# Use tree if available, otherwise use our function
if command -v tree &> /dev/null; then
    # Use tree with ASCII characters and filter patterns
    tree "$TARGET_DIR" -a -I "$(IFS='|'; echo "${IGNORE_PATTERNS[*]}")" --charset=ascii >> "$OUTPUT_FILE"
else
    # Use our own tree function
    echo "$(basename "$TARGET_DIR")/" >> "$OUTPUT_FILE"
    generate_clean_tree "$TARGET_DIR" "" false
fi

echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Generate file contents only if not folder structure only
if [[ "$FOLDER_STRUCTURE_ONLY" == false ]]; then
    echo "## File Contents" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Counter for files
    file_count=0
    total_files=$(find "$TARGET_DIR" -type f | wc -l)

    echo "📊 Processing files..."

    # Find all relevant files
    find "$TARGET_DIR" -type f | while read -r file; do
        # Skip if file should be ignored
        if should_ignore "$file"; then
            continue
        fi
        
        # Skip if extension should not be included
        if ! should_include_extension "$file"; then
            continue
        fi
        
        # Skip binary files
        if file "$file" | grep -q "binary"; then
            continue
        fi
        
        # Relative path
        rel_path="${file#$TARGET_DIR/}"
        if [[ "$rel_path" == "$file" ]]; then
            rel_path="$(basename "$file")"
        fi
        
        # Increment counter and show progress
        ((file_count++))
        echo "  [$file_count] Processing: $rel_path"
        
        echo "### $rel_path" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Detect programming language for syntax highlighting
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
        
        # Add file info
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
        
        echo "\`\`\`$lang" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done

    echo ""
    echo "📈 Summary:"
    echo "  • Total files processed: $file_count"
fi

# Summary output
if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
    echo ""
    echo "📁 Summary:"
    echo "  • Mode: folder structure only"
else
    if [[ "$FOLDER_STRUCTURE_ONLY" == false ]]; then
        echo ""
        echo "📈 Summary:"
        echo "  • Total files processed: $file_count"
    fi
fi

if [[ "$CREATE_MARKDOWN" == true ]]; then
    echo "  • Output file: $OUTPUT_FILE"
    echo "  • File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
        echo "✅ Folder structure report generated: $OUTPUT_FILE"
    else
        echo "✅ Report generated: $OUTPUT_FILE"
    fi
else
    echo "  • Mode: clipboard only"
    echo ""
    if [[ "$FOLDER_STRUCTURE_ONLY" == true ]]; then
        echo "✅ Folder structure report ready for clipboard"
    else
        echo "✅ Report ready for clipboard"
    fi
fi

# Copy to clipboard
if command -v pbcopy &> /dev/null; then
    # macOS
    cat "$OUTPUT_FILE" | pbcopy
    echo "📋 Report copied to clipboard (macOS)"
elif command -v xclip &> /dev/null; then
    # Linux with xclip
    cat "$OUTPUT_FILE" | xclip -selection clipboard
    echo "📋 Report copied to clipboard (Linux - xclip)"
elif command -v xsel &> /dev/null; then
    # Linux with xsel
    cat "$OUTPUT_FILE" | xsel --clipboard --input
    echo "📋 Report copied to clipboard (Linux - xsel)"
elif command -v clip.exe &> /dev/null; then
    # Windows (WSL)
    cat "$OUTPUT_FILE" | clip.exe
    echo "📋 Report copied to clipboard (Windows/WSL)"
else
    echo "⚠️  Clipboard tool not found. Install pbcopy (macOS), xclip/xsel (Linux), or use WSL (Windows)"
    if [[ "$CREATE_MARKDOWN" == true ]]; then
        echo "You can manually copy the file: $OUTPUT_FILE"
    fi
fi

# Clean up temporary file if no markdown was created
if [[ "$CREATE_MARKDOWN" == false ]]; then
    rm -f "$OUTPUT_FILE"
fi