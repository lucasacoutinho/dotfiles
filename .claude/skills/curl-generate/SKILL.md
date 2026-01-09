---
name: curl-generate
description: Generate curl commands from conversation context. Reads the current discussion about an API endpoint and outputs curl with variations (happy path, auth variations, error cases). Use when user says "generate curl", "curl for this", or "give me the curl command".
---

# curl-generate

Generate curl commands based on the current conversation about an API endpoint.

## Context Extraction

Read the conversation to identify:

1. **HTTP Method**: GET, POST, PUT, PATCH, DELETE
2. **Endpoint Path**: `/api/users`, `/api/orders/{id}`, etc.
3. **Request Body Fields**: name, email, etc. with types
4. **Query Parameters**: `?page=1&limit=10`
5. **Auth Type**: Bearer token, API key, Basic auth, or none
6. **Headers**: Content-Type, Accept, custom headers

## Base URL Detection

Check in order:

1. `.env` file for `APP_URL` or `API_URL`
2. `docker-compose.yml` for exposed ports
3. `vite.config.js` or `webpack.config.js` for dev server
4. Default to `http://localhost:8000`

## Output Format

Print to conversation (no file saving). Always include:

### Happy Path

```bash
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "role": "admin"
  }'
```

### Without Auth (if endpoint supports it)

```bash
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "role": "admin"
  }'
```

### Error Case (missing required field)

```bash
# Missing required 'email' field
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "John Doe"
  }'
```

## Auth Variations

Based on project detection:

| Auth Type | Header |
|-----------|--------|
| Bearer | `-H "Authorization: Bearer <token>"` |
| API Key (header) | `-H "X-API-Key: <key>"` |
| API Key (query) | `?api_key=<key>` |
| Basic | `-u username:password` |

## Special Cases

**File Upload:**
```bash
curl -X POST http://localhost:8000/api/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@/path/to/file.pdf" \
  -F "description=My document"
```

**Query Parameters:**
```bash
curl -X GET "http://localhost:8000/api/users?page=1&limit=10&sort=created_at" \
  -H "Authorization: Bearer <token>"
```

**Path Parameters:**
```bash
# Replace {id} with actual value
curl -X GET http://localhost:8000/api/users/123 \
  -H "Authorization: Bearer <token>"
```

## Trigger Phrases

- "generate curl"
- "curl for this"
- "give me the curl command"
- "curl request"
- "show me the curl"
