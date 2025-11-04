# Git Branching for Beginners

## What is a Branch?

Think of branches as **parallel universes** for your code:
```
main branch (stable, production-ready)
  │
  ├── Commit A
  ├── Commit B
  ├── Commit C
  │
  └── v2-rebuild branch (experimental)
      │
      ├── Commit D (Sprint 0.5)
      ├── Commit E (Sprint 1)
      └── Commit F (Sprint 2)
```

## Why Branch?

1. **Safety:** `main` stays stable while you experiment
2. **Collaboration:** Teammates can see your work without affecting theirs
3. **Rollback:** Abandon the branch if things go wrong
4. **History:** See exactly what changed between versions

## Common Commands

### Check Current Branch
```bash
git branch
# Output:
#   main
# * v2-rebuild  ← asterisk shows current branch
```

### Create and Switch to New Branch
```bash
# Create AND switch in one command
git checkout -b new-feature

# Or do it in two steps:
git branch new-feature     # create
git checkout new-feature   # switch
```

### Switch Between Branches
```bash
git checkout main         # go to main
git checkout v2-rebuild   # go back to v2-rebuild
```

### Push Branch to GitHub
```bash
# First time pushing a new branch
git push -u origin v2-rebuild

# After that, just:
git push
```

### See All Branches (Local + Remote)
```bash
git branch -a
# Output:
#   main
# * v2-rebuild
#   remotes/origin/main
#   remotes/origin/v2-rebuild
```

## Working in Codespaces

When you open GitHub Codespaces:

1. **It starts on `main` by default**
2. Switch to your branch: `git checkout v2-rebuild`
3. Make changes, commit: `git commit -m "Changes"`
4. Push: `git push origin v2-rebuild`

## Typical Workflow

### Starting Work
```bash
# 1. Switch to your branch
git checkout v2-rebuild

# 2. Pull latest changes (if working on multiple machines)
git pull origin v2-rebuild

# 3. Do your work, edit files

# 4. See what changed
git status

# 5. Add files
git add .

# 6. Commit
git commit -m "Sprint X: Description of changes"

# 7. Push to GitHub
git push origin v2-rebuild
```

## When to Merge?

Merge `v2-rebuild` → `main` when:
- ✅ Sprint 3 complete (first 20 minutes works)
- ✅ Tested 3+ times successfully
- ✅ Confident it's better than V1.x

### How to Merge
```bash
# 1. Switch to main
git checkout main

# 2. Merge v2-rebuild into main
git merge v2-rebuild

# 3. Push updated main
git push origin main
```

## Handling Conflicts

If you work on **Codespaces** AND **local machine**:
```bash
# Always pull before starting work
git pull origin v2-rebuild

# If you forget and get conflicts:
git pull --rebase origin v2-rebuild

# Fix any conflicts in files, then:
git add .
git rebase --continue

# Push
git push origin v2-rebuild
```

## Force Push (When Appropriate)

**Only use when:**
- ✅ Rewriting history on YOUR feature branch
- ✅ Abandoning old commits for clean start
- ✅ No teammates actively working on same branch
```bash
# Safer version (won't overwrite if someone else pushed)
git push --force-with-lease origin v2-rebuild
```

## Visual: Your Repository Structure
```
GitHub (origin)
├── main
│   └── V1.x commits (invitational code)
│
└── v2-rebuild
    ├── Sprint 0.5 commits
    ├── Sprint 1 commits
    └── Sprint 2 commits

Your Local Machine
├── main (synced with GitHub)
└── v2-rebuild (synced with GitHub)

Your Codespaces
├── main (synced with GitHub)
└── v2-rebuild (synced with GitHub)
```

## Common Mistakes

### ❌ Committing to `main` Instead of Branch
```bash
# You meant to be on v2-rebuild but you're on main!
# Fix:
git checkout -b v2-rebuild  # create branch from current state
git checkout main           # go back to main
git reset --hard origin/main  # reset main to match GitHub
```

### ❌ Forgetting to Push
```bash
# Work is committed locally but not on GitHub
git status
# Shows: "Your branch is ahead of 'origin/v2-rebuild' by 2 commits"

# Fix:
git push origin v2-rebuild
```

### ❌ Working on Wrong Machine Without Pulling
```bash
# You worked on Codespaces, now on local machine
# But didn't pull changes from GitHub

# Fix:
git pull --rebase origin v2-rebuild
```

## Quick Reference

| Task | Command |
|------|---------|
| See current branch | `git branch` |
| Create new branch | `git checkout -b branch-name` |
| Switch branch | `git checkout branch-name` |
| Push branch | `git push origin branch-name` |
| Pull latest | `git pull origin branch-name` |
| See changes | `git status` |
| Commit | `git commit -m "Message"` |
| See history | `git log --oneline -10` |

## Getting Help
```bash
# Help for any command
git help push
git help merge
git help rebase

# Or online:
# https://git-scm.com/docs
```