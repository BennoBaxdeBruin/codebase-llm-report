# Codebase Reporter

A CLI tool that generates markdown reports of your codebase and copies them to your clipboard.

## Installation

### Download and Setup

```bash
# Clone the repository
git clone https://github.com/BennoBaxdeBruin/codebase-llm-report.git
cd codebase-llm-report

# Make executable
chmod +x codebase-report.sh
```

### Add to PATH

Choose one of the following methods to make the command available system-wide:

#### Method 1: Symlink (Recommended)
```bash
# macOS/Linux
sudo ln -s $(pwd)/codebase-report.sh /usr/local/bin/codebase-report

# Test it works
codebase-report --help
```

#### Method 2: Copy to PATH directory
```bash
# macOS/Linux
sudo cp codebase-report.sh /usr/local/bin/codebase-report

# Windows (Git Bash/WSL)
cp codebase-report.sh /usr/bin/codebase-report
```

#### Method 3: Personal bin directory
```bash
# Create personal bin directory
mkdir -p ~/bin

# Copy script
cp codebase-report.sh ~/bin/codebase-report
chmod +x ~/bin/codebase-report

# Add to PATH (add this line to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/bin:$PATH"

# Reload shell
source ~/.bashrc  # or source ~/.zshrc
```

#### Method 4: Windows specific
```bash
# For Windows PowerShell/Command Prompt
# Copy to a directory in your PATH, e.g.:
copy codebase-report.sh C:\Windows\System32\codebase-report.bat

# Or create a batch wrapper:
echo @bash "%~dp0codebase-report.sh" %* > C:\Windows\System32\codebase-report.bat
```

### Verify Installation

```bash
# Should work from any directory
cd ~
codebase-report --help
```

## Usage

```bash
# Generate report and copy to clipboard
codebase-report

# Also save to markdown file
codebase-report --markdown

# Analyze specific directory
codebase-report /path/to/project

# Custom output filename
codebase-report . my-report.md --markdown
```

## Options

- `--markdown` - Create markdown file in addition to clipboard
- `--help` - Show help message

## Requirements

### Clipboard Support
- **macOS**: `pbcopy` (included by default)
- **Linux**: Install `xclip` or `xsel`
  ```bash
  # Ubuntu/Debian
  sudo apt install xclip
  # or
  sudo apt install xsel
  
  # Fedora/RHEL
  sudo dnf install xclip
  # or
  sudo dnf install xsel
  ```
- **Windows**: Works with Git Bash or WSL

### Optional: Tree Command
For better directory structure visualization:
```bash
# macOS
brew install tree

# Ubuntu/Debian
sudo apt install tree

# Fedora/RHEL
sudo dnf install tree
```

## What Gets Processed

The tool automatically:
- Includes common source code files (.js, .py, .java, etc.)
- Excludes build artifacts, dependencies, and cache files
- Shows file sizes and modification dates
- Generates a clean directory structure

## Configuration

Edit the script to customize:
- `INCLUDE_EXTENSIONS` - File types to include
- `IGNORE_PATTERNS` - Files/directories to exclude
- `INCLUDE_FILES` - Specific files to always include

## Output Format

Generated reports include:
1. Project metadata (date, directory, file count)
2. Directory structure tree
3. Complete file contents with syntax highlighting

## Troubleshooting

### "Command not found"
- Check if the script is in your PATH: `which codebase-report`
- Verify the script is executable: `ls -la $(which codebase-report)`

### "Permission denied"
```bash
chmod +x /path/to/codebase-report.sh
```

### Clipboard not working
- Install required clipboard tools (see Requirements section)
- On Linux, you may need to install X11 forwarding for SSH sessions

## License

MIT License - see LICENSE file for details.