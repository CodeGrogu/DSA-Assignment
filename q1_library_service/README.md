Ballerina Library CLI (improved)

Requirements:
- Ballerina installed (tested with Ballerina 2201+)
- A running REST service reachable by base URL

Run:
1) Clone the repository and switch to the branch `feature/cli-client`.
2) Build/run the CLI:
   bal run q1_library_service/library_client.bal http://localhost:8080
   (or run without args and the program will ask for base URL)

Usage highlights:
- Menu entries 1..5 access the five required views.
- Option 6/7 POST loaning/booking JSON bodies you enter.
- Option 8 lets you edit endpoint paths at runtime (useful if your service uses different routes).
- 'w' runs the full guided walkthrough: list assets -> you pick an asset -> loan it -> show overdue -> adjust schedule.

Acceptance criteria coverage:
- CLI runs from the command line and connects to the running REST service (pass base URL).
- All 5 required views reachable via menu; endpoints are configurable at runtime.
- API errors (4xx/5xx) are shown as "API Error: HTTP <code>" plus response body, not stack traces.
- Full walkthrough option exercises the end-to-end flow.

If your service uses different endpoint paths:
- Use option 8 in the menu to set the correct paths (must start with /).
- Or tell me the exact REST paths (or share your OpenAPI), and I will update the default mapping and add typed request/response models and a demo script.

What I committed:
- q1_library_service/library_client.bal - the CLI program
- q1_library_service/endpoints.json - example mapping file
- q1_library_service/README.md - run/walkthrough instructions

Next steps I can do for you:
- Add automatic endpoints.json loading so the CLI reads config from disk on startup.
- Add JSON pretty-printing for nicer output.
- Wire the exact API paths and request/response types if you provide an OpenAPI spec.
- Open a PR against main with these changes and include automated test instructions.
