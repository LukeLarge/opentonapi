#!/usr/bin/env bash
set -euo pipefail
if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/repo (mirror or working clone)"
  exit 2
fi
repo_dir="$1"
out_dir="${2:-./scan-output}"
mkdir -p "$out_dir"
cd "$repo_dir"
echo "Running quick scans for $repo_dir" > "$out_dir/scan-report.txt"
echo "=== Suspicious CI downloads ===" >> "$out_dir/scan-report.txt"
(grep -RIn --exclude-dir=.git -e "curl -fsSL" -e "wget -qO" -e "sh -" || true) >> "$out_dir/scan-report.txt"
echo "=== Dynamic exec/eval usage ===" >> "$out_dir/scan-report.txt"
(grep -RIn --exclude-dir=.git -e "eval(" -e "exec(" -e "popen(" -e "system(" || true) >> "$out_dir/scan-report.txt"
echo "=== Base64/obfuscation patterns ===" >> "$out_dir/scan-report.txt"
(grep -RIn --exclude-dir=.git -E "base64_decode|fromCharCode|atob|btoa|\\x[0-9a-fA-F]{2,}" || true) >> "$out_dir/scan-report.txt"
echo "=== Recent commits (30d) ===" >> "$out_dir/scan-report.txt"
git --no-pager log --since="30 days ago" --pretty=format:"%h %ad %an %s" --date=iso | head -n 200 >> "$out_dir/scan-report.txt" || true
echo "Scan saved to $out_dir/scan-report.txt"
