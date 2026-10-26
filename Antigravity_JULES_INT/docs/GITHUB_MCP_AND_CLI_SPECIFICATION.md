# GitHub MCP & CLI Integration Specification

**Document Version:** 1.0  
**Target:** Antigravity Autonomous Tools & Executors  
**Location:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\docs\GITHUB_MCP_AND_CLI_SPECIFICATION.md`  

---

## 1. Overview
Antigravity connects to GitHub via two complementary channels:
1. **GitHub CLI (`gh.exe`):** High-speed native binary with full token credentials (`gh auth status` verified as `apvizual-max`). Ideal for scripting, branch pruning, and batch merging.
2. **GitHub MCP Server (`github`):** Lazily-loaded Model Context Protocol tools allowing direct conversational introspection of issues, PRs, comments, and file trees.

---

## 2. GitHub CLI Automation Commands

### 2.1 Inspecting Pull Requests
```powershell
# List open PRs for a repository
gh pr list --repo apvizual-max/<repo> --state open --json number,title,headRefName,createdAt

# View PR details and review comments
gh pr view <number> --repo apvizual-max/<repo>

# Inspect code diff of a PR
gh pr diff <number> --repo apvizual-max/<repo>
```

### 2.2 Squash-Merging & Branch Pruning (Single-Branch Invariant)
```powershell
# Squash and merge PR, then automatically delete the remote feature branch
gh pr merge <number> --repo apvizual-max/<repo> --squash --delete-branch --subject "Merge PR #<number>: <title>" --body "Automated merge by Antigravity CD Engine."
```

### 2.3 Deleting Stale Remote Branches
```powershell
# Delete a remote branch directly via git or GitHub API
gh api --method DELETE "repos/apvizual-max/<repo>/git/refs/heads/<branch-name>"
```

---

## 3. GitHub MCP Server Tools Reference

Antigravity natively accesses these tools via `call_mcp_tool`:

| MCP Tool Name | Primary Parameters | Purpose |
|---|---|---|
| `list_pull_requests` | `owner`, `repo`, `state` | List open PRs from Jules. |
| `get_pull_request` | `owner`, `repo`, `pull_number` | Retrieve PR metadata and mergeability. |
| `get_pull_request_files` | `owner`, `repo`, `pull_number` | Inspect list of modified files in the PR. |
| `create_pull_request_review`| `owner`, `repo`, `pull_number`, `event`, `body` | Approve or request changes on a Jules PR. |
| `merge_pull_request` | `owner`, `repo`, `pull_number`, `merge_method` | Programmatically squash-merge into `main`. |
| `add_issue_comment` | `owner`, `repo`, `issue_number`, `body` | Address `@jules` with instructions or feedback. |
| `list_issues` | `owner`, `repo`, `state` | Track backlog items and bugs for Jules to tackle. |

---

## 4. Error Handling & Guardrails
- **Merge Conflicts:** If `gh pr view` reports `mergeable: CONFLICTING`, never force merge. Flag for automated rebase or create a remediation prompt.
- **Protected Branches:** If `main` has protection rules requiring approvals, use `gh pr review <number> --approve` prior to merging.
