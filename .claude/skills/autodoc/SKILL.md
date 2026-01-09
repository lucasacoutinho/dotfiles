---
name: autodoc
description: Auto-generate documentation from recent git changes. Detects project type (Laravel, Python, Rust, etc.) and doc system (Scribe, Docusaurus, OpenAPI, etc.), then generates appropriate docs. Use when user says "autodoc", "document changes", or "generate docs".
---

# autodoc

Generate documentation from recent git changes by detecting your project type and documentation system.

## Workflow

### Step 1: Detect Changes

```bash
# Get changed files (default: last commit)
git diff --name-only HEAD~1

# Or for staged changes
git diff --name-only --cached
```

### Step 2: Detect Project Type

Check for these marker files:

| File | Project Type |
|------|--------------|
| `composer.json` | PHP/Laravel |
| `package.json` | Node.js |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `setup.py` | Python |
| `go.mod` | Go |
| `Gemfile` | Ruby |

### Step 3: Detect Documentation System

| Signal | Doc System | Location |
|--------|------------|----------|
| `composer.json` has `knuckleswtf/scribe` | Scribe | `.scribe/`, `storage/app/scribe/` |
| `composer.json` has `dedoc/scramble` | Scramble | Auto-generated OpenAPI |
| `docusaurus.config.js` exists (check parent/sibling dirs) | Docusaurus | External `docs/` |
| `mkdocs.yml` exists | MkDocs | `docs/` |
| `Cargo.toml` exists | rustdoc | Inline `///` comments |
| `pyproject.toml` + `sphinx` in deps | Sphinx | `docs/` |
| `openapi.yaml` or `swagger.json` exists | OpenAPI | Same file |
| `.scribe/` directory exists | Scribe | `.scribe/endpoints/` |

### Step 4: Confirm with User

**ALWAYS confirm before generating.** Present:

```
I detected:
- Project: Laravel
- Doc system: Scribe
- Doc location: `.scribe/endpoints/`
- Changed files: UserController.php, OrderService.php

Generate documentation for these changes? [Y/n]
```

### Step 5: Generate Documentation

Based on doc system:

**Scribe (Laravel):**
- Generate response examples in `storage/app/scribe/`
- Add `@group`, `@bodyParam`, `@response` annotations

**Docusaurus:**
- Create/update MDX files in docs folder
- Include code examples and API references

**OpenAPI/Swagger:**
- Add/update endpoint definitions in YAML
- Include request/response schemas

**rustdoc:**
- Add `///` doc comments above functions/structs
- Include examples in doc comments

**Sphinx/MkDocs:**
- Update relevant `.md` or `.rst` files
- Follow existing documentation patterns

## Options

User can specify:
- `autodoc HEAD~3` - Document last 3 commits
- `autodoc --staged` - Document staged changes only
- `autodoc path/to/file.php` - Document specific file
