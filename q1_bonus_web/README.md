# Q1 Bonus Web Interface

Browser based UI for the Library & Resource Management System REST API.
Built with plain HTML,CSS,JS tools, no framework.

## How to run

1. Start the Q1 REST service:
cd q1_library_service
bal run
Wait for: `Library & Resource Management System REST Service started on port 9090`

### 2. Serve this web folder over HTTP

Browsers block `fetch()` from `file://` pages, so the page must be served from a real HTTP server:
cd q1_bonus_web
python -m http.server 8080

### 3. Open in a browser

Visit: http://localhost:8080

Click **Check Health** to verify the page can reach the API.

## Why two ports?

- **9090** — Q1 REST API (Ballerina)
- **8080** — this web page (Python static server)

Different ports = different origins. The Q1 service is configured with CORS headers (`@http:ServiceConfig { cors: ... }`) so browsers allow the cross-origin request.
