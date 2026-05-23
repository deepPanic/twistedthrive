#!/usr/bin/env bash
set -u

# Pre-push security scanner for Twisted Thrive.
# Blocks obvious secrets before they reach GitHub.

echo "🔒 Running security scan before push..."

# Prefer staged files when committing; for pre-push, scan files changed in the most
# recent commit if nothing is staged.
DIFF_FILES=$(git diff --cached --name-only 2>/dev/null || true)
if [ -z "$DIFF_FILES" ]; then
  DIFF_FILES=$(git diff --name-only HEAD~1 2>/dev/null || true)
fi

if [ -z "$DIFF_FILES" ]; then
  echo "✅ Nothing to scan."
  exit 0
fi

ISSUES=0

while IFS= read -r file; do
  [ -z "$file" ] && continue
  [[ "$file" == ".gitignore" ]] && continue
  [[ "$file" == "LICENSE"* ]] && continue
  [[ "$file" == "SECURITY.md" ]] && continue
  [[ "$file" == "scripts/pre-push-security-scan.sh" ]] && continue

  CONTENT=$(git show ":$file" 2>/dev/null || cat "$file" 2>/dev/null || true)
  [ -z "$CONTENT" ] && continue

  # GitHub tokens
  if echo "$CONTENT" | grep -q 'ghp_' || echo "$CONTENT" | grep -q 'gho_' || echo "$CONTENT" | grep -q 'github_pat_'; then
    echo "🚨 $file: GITHUB TOKEN LEAKED"
    ISSUES=$((ISSUES + 1))
  fi

  # Private keys
  if echo "$CONTENT" | grep -q 'PRIVATE KEY'; then
    echo "🚨 $file: Private key found"
    ISSUES=$((ISSUES + 1))
  fi

  # .env files, except .env.example
  if [[ "$file" == *.env ]] && [[ "$file" != ".env.example" ]]; then
    echo "🚨 $file: .env file committed"
    ISSUES=$((ISSUES + 1))
  fi

  # Credential files
  if [[ "$file" == *".git-credentials" ]] || [[ "$file" == *".netrc" ]]; then
    echo "🚨 $file: Credential file committed"
    ISSUES=$((ISSUES + 1))
  fi

  # API key / secret patterns
  if echo "$CONTENT" | grep -qi 'api_key\|api-key\|api_secret\|access_token\|client_secret' 2>/dev/null; then
    if echo "$CONTENT" | grep -qiE '(api_key|api-key|access_token|client_secret).*[:=].*[A-Za-z0-9]{20,}'; then
      echo "⚠️  $file: Possible API key or secret"
      ISSUES=$((ISSUES + 1))
    fi
  fi

  # Private IPs: warn only, do not block.
  if echo "$CONTENT" | grep -qE '(192\.168|10\.0\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[01]\.)'; then
    echo "⚠️  $file: Contains private IP addresses (review before pushing)"
  fi
done <<< "$DIFF_FILES"

if [ "$ISSUES" -gt 0 ]; then
  echo ""
  echo "❌ $ISSUES critical security issue(s) found. Push BLOCKED."
  echo "   Fix the issues above, or bypass only if you are certain: git push --no-verify"
  exit 1
fi

echo "✅ Security scan passed."
exit 0
