# Security Policy

## Pre-Push Scanning

All pushes to this repository are scanned by a pre-push hook that checks for:

- **GitHub tokens** (`ghp_`, `gho_`, `github_pat_`) 
- **Private keys** (`PRIVATE KEY` blocks)
- **Environment files** (`.env`, not `.env.example`)
- **Credential files** (`.git-credentials`, `.netrc`)
- **API keys/secrets** (hardcoded `api_key`, `access_token`, etc.)
- **Private IP addresses** (warning)

### Bypass

In emergencies, use `git push --no-verify` to bypass. Do not make a habit of this.

### Decap CMS

Content editors using Decap CMS should never upload files containing secrets,
API keys, or credentials. The CMS collections filter out `.env` and `.key` file types.

All content is public. Nothing sensitive should ever be committed.
