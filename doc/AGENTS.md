# Repository Guidelines

## Project Structure & Module Organization
- `.github/workflows/` contains automation entry points. `watch_vivalidi.yml` schedules the daily crawl/notification job, while `test_notify.yml` is a manual smoke test for Discord messaging.
- `scripts/watch_vivaldi.sh` encapsulates the monitoring logic (fetch, diff, cache pruning). Additional site watchers should live here following the same pattern.
- `README.md` explains operational context and onboarding steps; `rule.md` captures house style expectations (indentation, naming, formatter defaults).

## Build, Test, and Development Commands

```bash
# Run the watcher locally (requires curl and env vars if notifying)
bash scripts/watch_vivaldi.sh

# Trigger the scheduled workflow manually from your machine
gh workflow run watch_vivalidi.yml

# Fire the Discord notification-only workflow for smoke testing
gh workflow run test_notify.yml
```

## Coding Style & Naming Conventions
- **Indentation**: 2 spaces (per `rule.md` and existing YAML/Bash files). Tabs should not appear in committed files.
- **File naming**: Scripts follow `watch_<target>.sh`; workflows mirror that with `watch_<target>.yml`. Docs remain lowercase with hyphens.
- **Function/variable naming**: Bash variables are uppercase snake case (e.g., `STATE_DIR`), while YAML keys stay lowercase with dashes.
- **Linting**: No automated linter is wired up, but `shellcheck scripts/watch_vivaldi.sh` is recommended pre-commit. Keep YAML validated via `act` or `yamllint` if available.

## Testing Guidelines
- **Framework**: No dedicated test harness; reliability is ensured via GitHub Actions workflows.
- **Test files**: `test_notify.yml` is the only explicit verification job and lives under `.github/workflows/`.
- **Running tests**: `gh workflow run test_notify.yml` (or use the Actions tab’s *Run workflow* button).
- **Coverage**: Not enforced; focus on deterministic shell logic and clear debug output.

## Commit & Pull Request Guidelines
- **Commit format**: Prefer concise imperative statements as seen in history (`"Update README(Japanese)", "Delete cache that is 10 days old"`). Explain *what* changed and, if non-obvious, *why* in the body.
- **PR process**: Ensure workflows pass, link related issues, and describe manual verifications (cache restored, notification sent, etc.). Solicit review before merging because automation interacts with external services.
- **Branch naming**: Not prescribed; a practical pattern is `feature/<site>` or `fix/<issue-id>` so reviewers immediately grasp scope.

---

# Repository Tour

## 🎯 What This Repository Does

`site-watcher` automates website change detection and pushes alerts to Discord using GitHub Actions plus Bash scripts.

**Key responsibilities:**
- Periodically fetch the Vivaldi blog landing page and capture canonical article URLs.
- Compare the latest crawl against cached results to detect new posts.
- Notify a Discord user/channel and rotate saved caches to keep history lean.

---

## 🏗️ Architecture Overview

### System Context
```
[Vivaldi Blog] → [GitHub Actions job + Bash script] → [Discord Webhook]
                           ↓
                    [GitHub Actions Cache]
```

### Key Components
- **GitHub Actions workflows** – Define schedules, cache lifecycles, and notification hooks. `watch_vivalidi.yml` orchestrates the entire run.
- **Watcher shell script** – `scripts/watch_vivaldi.sh` handles crawling, diffing, and emitting the `changed` output consumed by downstream steps.
- **Cache management** – `actions/cache@v4` plus `gh cache delete` persist the URL list between runs and clean anything older than 10 days, preventing stale detections.

### Data Flow
1. Cron or manual dispatch triggers `watch_vivalidi.yml`.
2. Workflow restores yesterday’s cache into `prev/urls.txt` and executes the watcher script.
3. The script downloads HTML, extracts article URLs, compares against cached state, and sets `changed=true/false` in `GITHUB_OUTPUT`.
4. On `true`, the workflow posts to Discord using secrets; regardless of outcome, the new URL set becomes today’s cache and obsolete caches are removed via the GitHub CLI.

---

## 📁 Project Structure [Partial Directory Tree]

```
.
├── .github/
│   └── workflows/
│       ├── watch_vivalidi.yml   # Scheduled monitoring & notification pipeline
│       └── test_notify.yml      # Manual Discord notification smoke test
├── scripts/
│   └── watch_vivaldi.sh         # Crawl, diff, cache rotation logic
├── README.md                    # Japanese overview and setup instructions
└── rule.md                      # Coding standards adopted across projects
```

### Key Files to Know

| File | Purpose | When You'd Touch It |
|------|---------|---------------------|
| `.github/workflows/watch_vivalidi.yml` | Main workflow configuring cron, cache restore/save, and notifications | Adjust schedule, secrets usage, or additional steps |
| `.github/workflows/test_notify.yml` | Minimal workflow to send a Discord ping | Validate webhook configuration without crawling |
| `scripts/watch_vivaldi.sh` | Fetches latest blog entries, compares with `prev/urls.txt`, and emits change status | Modify parsing rules or adapt the watcher for a new site |
| `README.md` | Contributor-facing documentation (Japanese) | Update onboarding steps or add new site instructions |
| `rule.md` | Team-wide formatting and naming ground rules | Align repo-specific conventions with organization standards |

---

## 🔧 Technology Stack

### Core Technologies
- **Language:** Bash – lightweight scripting for HTML parsing and file diffs.
- **Automation Framework:** GitHub Actions (YAML workflows) – provides cron scheduling, caching, and secret management.
- **Data Store:** GitHub Actions Cache – persists plaintext URL snapshots, avoiding an external database.
- **Notification Channel:** Discord Webhook – real-time alerting for detected updates.

### Key Libraries / Actions
- **`actions/checkout@v4`** – fetches repository code for each workflow run.
- **`actions/cache@v4`** – stores `prev/` folder contents between runs.
- **`gh cache delete`** – command-line pruning of aged cache artifacts to enforce the 10-day retention policy.

### Development Tools
- **`curl`** – HTTP client for both crawling the blog and posting to Discord.
- **`sed`/`grep`** – lightweight parsing toolkit to isolate canonical article links.
- **`gh` CLI** – optional locally, required in workflow step for cache deletion.

---

## 🌐 External Dependencies

### Required Services
- **Vivaldi Blog (`https://vivaldi.com/ja/blog/latest/`)** – monitored source; schema or markup changes may necessitate script updates.
- **Discord Webhook** – configured via `DISCORD_WEBHOOK_URL` and `DISCORD_USER_ID` secrets for targeted mentions.

### Optional Integrations
- **GitHub CLI** – used inside workflows for cache management; ensure runners have it preinstalled (default on `ubuntu-latest`).

---

### Environment Variables

```bash
# Workflow secrets (required)
DISCORD_WEBHOOK_URL=...   # Target webhook URL
DISCORD_USER_ID=...       # User ID for mention formatting

# Script overrides (optional)
BLOG_URL=https://vivaldi.com/ja/blog/latest/
STATE_DIR=prev
```

---

## 🔄 Common Workflows

### Scheduled Monitoring & Alerting
1. Cron fires `watch_vivalidi.yml` nightly at 23:00 UTC.
2. Workflow restores previous cache, runs the watcher, and posts alerts when `changed=true`.
3. Cache is saved under today’s key and stale keys (older than 10 days) are deleted.

**Code path:** `.github/workflows/watch_vivalidi.yml` → `scripts/watch_vivaldi.sh` → Discord webhook.

### Notification Smoke Test
1. Developer triggers `test_notify.yml` via Actions UI or `gh workflow run`.
2. Workflow posts a simple test message to confirm webhook + mentions work.

**Code path:** `.github/workflows/test_notify.yml` → Discord webhook.

---

## 📈 Performance & Scale
- **Caching:** Only the distinct URL list is cached, minimizing storage and keeping diffs fast.
- **Parsing Efficiency:** The `sed` boundary reduces HTML processed, and `sort -u` avoids duplicate URLs before comparison.

### Monitoring
- Rely on GitHub Actions run history to observe success/failure and review `echo`-based debug traces embedded in the shell script.

---

## 🚨 Things to Be Careful About

### 🔒 Security Considerations
- Secrets (`DISCORD_*`) must reside in repository or organization Actions secrets; never hardcode them.
- The workflow posts raw URLs—sanitize future additions if handling untrusted data.
- GitHub CLI cache deletion requires `actions: write` permission, already set in the workflow. Avoid downgrading unless you replace the cleanup logic.

*Update to last commit: a80add03a37b6cfdf4f6eb145715c01ab3301e28*
