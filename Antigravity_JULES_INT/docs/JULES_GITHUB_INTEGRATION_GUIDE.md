# Jules & GitHub Integration: Operational Guide

**Document Version:** 1.0  
**Target:** Developers, Antigravity Agents, and Automated CI  
**Location:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\docs\JULES_GITHUB_INTEGRATION_GUIDE.md`  

---

## 1. Addressing Jules via `@jules` on GitHub

When the Jules GitHub App is installed on `apvizual-max` repositories, Jules listens for mentions of `@jules` across GitHub Issues and Pull Requests.

### 1.1 Trigger Syntax on GitHub
To invoke Jules in a new or existing GitHub Issue or PR:
```markdown
@jules please address the following task:
- Problem: <clear, specific description of the issue or feature>
- Files to focus on: <path/to/file.ext>
- Requirements:
  1. Maintain backward compatibility.
  2. Add unit tests covering edge cases.
  3. Ensure no new dependencies are added unless required.
```

### 1.2 Feedback & Iteration on an Open PR
If Jules has already created a Pull Request, you can reply directly in the PR comments to request refinements:
```markdown
@jules thanks for the changes. Please update the PR to fix the edge case where the parameter is null or empty.
```

---

## 2. Specialized Jules Personas

To achieve focused, high-quality results from Jules, dispatch tasks with persona directives:

### 🎨 Persona 1: "Palette" (UX / UI / Accessibility)
- **Focus:** User interface polish, accessibility standards (WCAG, ARIA labels, contrast, keyboard navigation), component layout, and frontend responsiveness.
- **Example Prompt Template:**
  ```markdown
  You are "Palette" 🎨 - a UX-focused agent who adds small, delightful polish and ensures full accessibility.
  Task: Inspect the UI components in <directory> and ensure all interactive controls have appropriate aria-label attributes and clear visual states.
  ```

### 🛡️ Persona 2: "Sentinel" (Security & Vulnerability Hardening)
- **Focus:** Preventing SSRF, path traversal, shell/command injection, SQL injection, input sanitization, and secrets leakage.
- **Example Prompt Template:**
  ```markdown
  You are "Sentinel" 🛡️ - a security-focused agent who protects our systems from vulnerabilities.
  Task: Audit <file> for unsafe subprocess calls and input parsing. Apply strict sanitization and ensure paths are validated against allowed root directories.
  ```

### ⚡ Persona 3: "Bolt" (Performance Optimization)
- **Focus:** Optimizing bottlenecks, reducing redundant disk I/O, regex precompilation, parallelizing independent operations, and memory footprint reduction.
- **Example Prompt Template:**
  ```markdown
  You are "Bolt" ⚡ - a performance-obsessed agent who makes our code lightning-fast.
  Task: Profile and optimize the batch processing loop in <file>. Replace sequential file reads with parallel streaming.
  ```

### 🧹 Persona 4: "Code Health & Testing" (QA / Refactoring)
- **Focus:** Increasing unit test coverage, adding edge case assertions, eliminating dead code, and standardizing error handling.
- **Example Prompt Template:**
  ```markdown
  # 🧪 Testing & Code Health Task
  You are a testing-focused agent. Create comprehensive unit tests for <module> covering success, failure, and edge case scenarios.
  ```

---

## 3. Jules CLI Operating Cheatsheet

On Windows PowerShell:
```powershell
# 1. Create a task for a specific repository
& "$env:APPDATA\npm\jules.cmd" new --repo apvizual-max/<repo> "Task instructions..."

# 2. Parallel exploration (creates multiple candidate approaches)
& "$env:APPDATA\npm\jules.cmd" new --repo apvizual-max/<repo> --parallel 3 "Task instructions..."

# 3. List all repositories registered with Jules
& "$env:APPDATA\npm\jules.cmd" remote list --repo

# 4. List all active and completed sessions
& "$env:APPDATA\npm\jules.cmd" remote list --session

# 5. Pull and inspect the patch from a session locally
& "$env:APPDATA\npm\jules.cmd" remote pull --session <SESSION_ID>

# 6. Apply patch directly to local working copy
& "$env:APPDATA\npm\jules.cmd" remote pull --session <SESSION_ID> --apply

# 7. Teleport into a session (clones repo + checks out branch)
& "$env:APPDATA\npm\jules.cmd" teleport <SESSION_ID>
```

---

## 4. Best Practices & Boundaries
1. **Scope Limit:** Do not give Jules huge architectural rewrites in a single prompt. Keep tasks bounded to 1–3 files.
2. **Deterministic Context:** Always specify the exact file names and desired outcomes.
3. **No Secrets:** Never paste tokens, passwords, or internal URLs in prompts.
4. **Always Verify:** Never auto-merge without running the Antigravity validation pipeline.
