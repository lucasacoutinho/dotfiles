# AI Dev Tools Design

**Date:** 2026-01-08
**Status:** Implemented

## Overview

Expand devcontainer-features with CLI utilities that AI tools can leverage as building blocks, plus two skills for documentation and API workflow automation.

## CLI Tool Features

Individual devcontainer features for each tool:

| Feature | Tool | Purpose | AI Use Case |
|---------|------|---------|-------------|
| fzf | fzf | Fuzzy finder | Interactive file/symbol selection |
| ripgrep | rg | Fast regex search | Code search in large codebases |
| fd | fd | Fast file finder | Find files by pattern |
| jq | jq | JSON processor | Parse API responses, configs |
| yq | yq | YAML processor | Parse k8s, docker-compose, CI configs |
| qsv | qsv | CSV toolkit | Data processing pipelines |
| bat | bat | Syntax-highlighted cat | Readable file output |
| eza | eza | Modern ls | Better directory listings |
| tokei | tokei | Code statistics | Project analysis |
| tree-sitter | tree-sitter CLI | AST parsing | Semantic code analysis |
| ctags | universal-ctags | Symbol indexing | Jump to definitions |

### Feature Structure

```
src/<tool>/
├── devcontainer-feature.json
├── install.sh
└── README.md
```

Each install.sh handles multiple package managers (apt, apk, pacman).

## Skills

### autodoc

**Purpose:** Detect project type and documentation system, then generate docs from recent git changes.

**Detection Matrix:**

| Signal | Doc System | Doc Location |
|--------|------------|--------------|
| `composer.json` + `knuckleswtf/scribe` | Scribe | `storage/app/scribe/`, `.scribe/` |
| `composer.json` + `dedoc/scramble` | Scramble | Auto-generated, `api.json` |
| `docusaurus.config.js` in parent/sibling | Docusaurus | External `docs/` folder |
| `mkdocs.yml` | MkDocs | `docs/` |
| `Cargo.toml` | rustdoc | Inline `///` comments |
| `pyproject.toml` + sphinx | Sphinx | `docs/` |
| `openapi.yaml` or `swagger.json` | OpenAPI | Same file |

**Workflow:**
1. User triggers with "autodoc" or "document recent changes"
2. Skill runs `git diff --name-only` to find changed files
3. Detects project type from marker files
4. Finds doc system and location
5. **Confirms with user** before generating
6. Generates appropriate documentation format

**Output by doc system:**
- Scribe: Response examples, annotations
- Docusaurus: MDX files with code examples
- OpenAPI: YAML endpoint definitions
- rustdoc: Inline `///` comments

### curl-generate

**Purpose:** Generate curl commands from conversation context.

**Context Detection:**
- HTTP method (GET, POST, PUT, DELETE, PATCH)
- Endpoint path
- Request body fields
- Query parameters
- Auth type (from project or conversation)

**Base URL Detection:**
1. Read `.env` for `APP_URL`
2. Check `docker-compose.yml` for ports
3. Fall back to `http://localhost:8000`

**Output Format:**
```bash
# Happy path
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"name": "John", "email": "john@example.com"}'

# Without auth
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John", "email": "john@example.com"}'

# Error case (missing required field)
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John"}'  # missing email
```

**Trigger Phrases:**
- "generate curl"
- "curl for this"
- "give me the curl command"

**Output:** Print to conversation only (no file saving)

## Implementation Order

1. CLI features (quick wins, parallel)
2. autodoc skill
3. curl-generate skill
