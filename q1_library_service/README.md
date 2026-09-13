Ballerina Library CLI (improved)

Requirements:
- Ballerina installed (tested with Ballerina 2201+)
- A running REST service reachable by base URL

Run:
1) Clone the repository and switch to the branch `feature/cli-client`.
2) Build/run the CLI:
   bal run q1_library_service/library_client.bal http://localhost:8080
   (or run without args and the program will ask for base URL)

Schedule manager (requirement):
- Option 's' in the menu provides schedule management actions:
  1) List schedules for an asset (calls GET /api/schedule?assetId=<assetId>)
  2) Add schedule for an asset (calls POST /api/schedule with provided JSON body)
  3) Remove schedule (lists schedules for an asset and lets you pick one to DELETE using its id)
- Removal is done by selecting from a listed index; the CLI extracts a schedule id (from `id` or `scheduleId`) and issues DELETE /api/schedule/{id}.
- After add/remove the CLI re-lists schedules for confirmation.

Overdue view (reminder):
- Option 4 in the menu is the overdue items view and calls GET /api/overdue by default.
- The CLI prints every overdue item's key fields: assetTag (or tag), name (or title), and a best-effort "how overdue" value (from overdueDays/daysOverdue/howOverdue or dueDate).
- If there are no overdue items the CLI prints "Nothing overdue right now." instead of an error.

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
- Schedule manager allows adding a schedule and removing a schedule by selection; both operations are re-validated by re-listing schedules.
- Overdue and global views implemented as required.

Testing notes:
- I implemented and tested this client manually against a seeded local service returning schedules via GET /api/schedule?assetId=... and supporting POST/DELETE on /api/schedule.

What I committed:
- q1_library_service/library_client.bal - the CLI program (updated to implement schedule add/remove flows)
- q1_library_service/endpoints.json - example mapping file (schedule -> /api/schedule)
- q1_library_service/README.md - run/walkthrough instructions and notes

Next steps I can do for you:
- Add automatic endpoints.json loading at startup so the CLI is pre-configured.
- Improve JSON pretty-printing for nicer output.
- Add an automated test script that seeds a test store and runs the schedule add/remove flow to validate output.
- Update field mappings if you supply example schedule responses or an OpenAPI spec.
