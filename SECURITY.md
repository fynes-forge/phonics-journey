# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x.x   | ✅ Yes     |

## Privacy Architecture

Phonics Journey is designed with privacy as a core architectural constraint,
not an afterthought — particularly because it is used by young children.

- **No internet permission** — not declared in `AndroidManifest.xml`
- **No network calls** — no HTTP client libraries in the codebase
- **Network security config** blocks all outbound connections at the OS level
- **No personal data transmitted** — ever
- **All storage is local** — Hive (on-device NoSQL), no cloud sync
- **No third-party SDKs** that could exfiltrate data (no Firebase, no analytics, no ads)

## Reporting a Vulnerability

If you discover a security or privacy vulnerability — including anything that
could expose children's data or allow unintended network access — please report
it **privately** rather than opening a public issue.

### How to report

1. Go to the **[Security Advisories](https://github.com/fynesforge/phonics_journey/security/advisories/new)** page
2. Click **"Report a vulnerability"**
3. Fill in the details

Alternatively, email: **security@fynesforge.dev**

### What to include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if known)

### Response timeline

| Action | Timeline |
|--------|----------|
| Acknowledge receipt | Within 48 hours |
| Initial assessment | Within 5 business days |
| Fix + release | Within 30 days for critical issues |

### Scope

Issues in scope:
- Any unintended network access or data exfiltration
- Privacy leaks in local storage
- Vulnerabilities in dependencies that affect this app
- Parental gate bypass (PIN or long-press gate)
- Any issue that could expose information about child users

Out of scope:
- Vulnerabilities in Flutter itself (report to the Flutter team)
- Physical device access attacks
- Issues in third-party services we don't use

## Dependency Security

Dependabot is enabled and monitors both pub.dev packages and GitHub Actions
for known vulnerabilities. Security patches are prioritised above all other work.
