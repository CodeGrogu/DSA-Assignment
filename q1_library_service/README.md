Ballerina Library CLI (improved)

Requirements:
- Ballerina installed (tested with Ballerina 2201+)
- A running REST service reachable by base URL

Run:
1) Clone the repository and switch to the branch `feature/cli-client`.
2) Build/run the CLI:
   bal run q1_library_service/library_client.bal http://localhost:8080
   (or run without args and the program will ask for base URL)

Global assets view (requirement):
- Option 2 in the menu is the ministry-wide assets view and calls GET /assets by default.
- The CLI prints every asset's key fields: tag, name, institution, status.
- If the store is empty the CLI prints "No assets found (empty store)." instead of an error.

Filtering resources:
- Option 'f' in the menu lets staff filter assets by institution or site/campus.
  - Choose 1) Institution and provide an institution name; the CLI will call GET /assets?institution=<value>
  - Choose 2) Site/Campus and provide a site/campus name; the CLI will call GET /assets?site=<value>
- If there are no matches the CLI prints a clear "No assets found for <filter>=<value>." message.

Usage highlights:
- Menu entries 1..5 access the five required views.
- Option 6/7 POST loaning/booking JSON bodies you enter.
- Option 8 lets you edit endpoint paths at runtime (useful if your service uses different routes).
- 'w' runs the full guided walkthrough: list assets -> you pick an asset -> loan it -> show overdue -> adjust schedule.

Acceptance criteria coverage:
- CLI runs from the command line and connects to the running REST service (pass base URL).
- The Global assets view lists every asset with key fields (tag, name, institution, status).
- Filtering by institution or site calls the API with the appropriate query parameter and renders only matching assets.
- An empty store or no-filter matches yield sensible messages instead of errors.

Testing notes:
- I implemented and tested this client manually against a seeded local service returning /assets as a JSON array. If you want, I can add a small seeded test server or a test script.

What I committed:
- q1_library_service/library_client.bal - the CLI program (updated to implement assets filtering)
- q1_library_service/endpoints.json - example mapping file (global -> /assets)
- q1_library_service/README.md - run/walkthrough instructions and notes

Next steps I can do for you:
- Add automated test script that seeds a test store and runs the assets view to validate the output.
- If your API uses a different path or query parameter names for filtering, tell me the exact path/param and I will update the defaults and add automated checks.
