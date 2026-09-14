# Distributed Systems & Applications (DSA612S) Assignment 1

**Team:** Peer Pressure (`PEE`)  
**Lead:** Jaden Awaseb  
**Runtime:** Ballerina Swan Lake 2201.13.5  
**Target Repository:** [CodeGrogu/DSA-Assignment](https://github.com/CodeGrogu/DSA-Assignment)

---

## 1. Project Overview

This repository contains the complete implementation of Assignment 1 for Distributed Systems & Applications (DSA612S), architected into two distinct distributed microservices:

1. **Question 1: Library & Resource Management System (REST)**
   - Located in [`q1_library_service/`](file:///c:/Users/Jaden/Documents/Programming/University/DSA/DSA-Assignment/q1_library_service) and [`q1_library_client/`](file:///c:/Users/Jaden/Documents/Programming/University/DSA/DSA-Assignment/q1_library_client)
   - **Architecture:** RESTful HTTP microservice + Interactive and scriptable CLI client
   - **Data Layer:** In-memory `AssetStore` and `InstitutionStore` using Ballerina Swan Lake `table` data structures guarded by synchronized mutex locks to prevent TOCTOU race conditions
   - **Identifiers:** Canonical `assetTag` in camelCase across all records, payloads, and endpoints

2. **Question 2: Vacation Property Rental Accommodation System (gRPC)**
   - Located in [`q2_rental_service/`](file:///c:/Users/Jaden/Documents/Programming/University/DSA/DSA-Assignment/q2_rental_service) and [`q2_rental_client/`](file:///c:/Users/Jaden/Documents/Programming/University/DSA/DSA-Assignment/q2_rental_client)
   - **Architecture:** Protocol Buffers v3 contract + High-performance Ballerina gRPC Service and Client
   - **Communication Paradigms:** Unary RPCs, client-streaming (`create_users`), and server-streaming (`list_available_properties`)
   - **Booking Safety:** Two-phase reservation architecture (`book_property` + `confirm_booking`) ensuring thread-safe date conflict resolution and preventing double-booking

---

## 2. Prerequisites

Before running the project, ensure the following tools are installed:

- **Ballerina Swan Lake 2201.13.5** (Official Swan Lake release)
- **Git**
- A terminal shell such as PowerShell, Bash, or Command Prompt

Verify your local Ballerina installation:

```bash
bal version
```

Expected output:
```text
Ballerina 2201.13.5 (Swan Lake Update 13)
Language specification 2024R1
Update Tool 1.5.0
```

---

## 3. Clone and Repository Structure

Clone the repository from GitHub:

```bash
git clone https://github.com/CodeGrogu/DSA-Assignment.git
cd DSA-Assignment
```

### Directory Layout

```text
.
├── q1_library_service/        # Question 1: REST Service, Models, and In-Memory Store
├── q1_library_client/         # Question 1: REST CLI and Interactive Terminal Client
├── q2_rental_service/         # Question 2: gRPC Service, Proto Contract, and Store
├── q2_rental_client/          # Question 2: gRPC Interactive Terminal Client
├── postman/                   # Postman v3 YAML Collections and Local Environments
├── docs/                      # Technical architecture documentation
├── .agents/                   # Workspace rules and development skills
├── AGENTS.md                  # Developer guidelines and quality gate standards
└── README.md                  # Master project documentation
```

---

## 4. Quick Start: Question 1 (REST Service & Client)

The REST service must be started before launching the client.

### Terminal 1: Start the REST Service

```bash
cd q1_library_service
bal build
bal test
bal run
```

The service will start listening on:
```text
http://localhost:9090
```

### Terminal 2: Run the CLI Client

Open a second terminal window:

```bash
cd q1_library_client
bal build
bal run
```

### Interactive Menu Mode (Options 1 to 16)

When executed without arguments (`bal run`), the client provides an interactive terminal interface:

```text
======================================================
  Library & Resource Management System - CLI Client   
======================================================
1.  Check Service Health
2.  List All Assets
3.  Get Asset by Asset Tag
4.  Register New Asset
5.  Update Asset Status / Metadata
6.  Delete Asset
7.  View Asset Status & Work Orders
8.  View Overdue Maintenance Assets
9.  Attach Component to Asset
10. Attach Schedule to Asset
11. View All Work Orders for Asset
12. Create Work Order for Asset
13. Add Task to Work Order
14. Mark Task Completed
15. Close Work Order
16. Manage Institutions
0.  Exit
```

### Direct Command-Line Arguments Mode

The client also supports direct command execution for scripting and quick checks:

```bash
# Verify service health
bal run -- health

# List all registered assets
bal run -- list

# Filter assets by institution and site
bal run -- list NUST "Main Campus"

# Inspect a specific asset by assetTag
bal run -- get AST-1001

# Inspect operational status and work orders
bal run -- status AST-1001

# Check for overdue maintenance
bal run -- overdue

# Query work orders for an asset
bal run -- work-orders AST-1001

# Query tasks on a work order
bal run -- tasks AST-1001 WO-501

# Close a completed work order
bal run -- close-wo AST-1001 WO-501

# Delete an asset by tag
bal run -- delete AST-1001

# Display usage instructions
bal run -- help
```

---

## 5. Quick Start: Question 2 (gRPC Service & Client)

### Terminal 1: Start the gRPC Service

```bash
cd q2_rental_service
bal build
bal test
bal run
```

The gRPC server listener will initialise and listen on port `9090`.

### Terminal 2: Run the gRPC Client

Open a second terminal window:

```bash
cd q2_rental_client
bal build
bal run
```

The client will display the interactive menu allowing you to exercise all 8 operations:

```text
======================================================
     Rental Accommodation System - gRPC Client        
======================================================
1.  Add Property (Host)
2.  Update Property (Host)
3.  Remove Property (Host)
4.  Search Property
5.  List Available Properties (Server Streaming)
6.  Register Users (Client Streaming)
7.  Book Property (Two-Phase Guest Reservation)
0.  Exit
```

### Protocol Buffers Compilation (`bal grpc`)

The service schema is defined in `q2_rental_service/proto/rental_service.proto`. To compile or regenerate Ballerina code stubs:

1. **Pull the Ballerina gRPC tool** (first-time setup):
   ```bash
   bal tool pull grpc
   ```

2. **Generate Service Stubs** (in `q2_rental_service`):
   ```bash
   cd q2_rental_service
   bal grpc --input proto/rental_service.proto --output . --mode service
   ```

3. **Generate Client Stubs** (in `q2_rental_client`):
   ```bash
   cd q2_rental_client
   bal grpc --input ../q2_rental_service/proto/rental_service.proto --output . --mode client
   ```

### Exercising the 8 gRPC Operations

| # | RPC Method | Interaction Type | How to Test via Interactive Client |
| :- | :--- | :--- | :--- |
| 1 | `add_property` | Unary | Select option `1`. Provide property title, location, type, and nightly price. Server returns a unique `assetTag` (e.g. `PROP-1001`). |
| 2 | `update_property` | Unary | Select option `2`. Provide existing `assetTag` and updated fields. Omitted fields retain stored values. |
| 3 | `remove_property` | Unary | Select option `3`. Enter `assetTag`, host ID, and location. Verifies ownership and returns host's remaining regional listings. |
| 4 | `search_property` | Unary | Select option `4`. Enter `assetTag`. Returns listing details or "Not Available". |
| 5 | `create_users` | Client Streaming | Select option `6`. Stream multiple user accounts (Hosts and Guests) over a single connection. Closing the stream returns a total registration count. |
| 6 | `list_available_properties` | Server Streaming | Select option `5`. Specify optional filters (location, type, price bounds). Server streams matching listings in real time. |
| 7 | `book_property` | Unary (Phase 1) | Select option `7`. Enter `assetTag`, guest ID, check-in, and check-out. Checks availability, validates dates, and stages booking in cart. |
| 8 | `confirm_booking` | Unary (Phase 2) | Enter `y` when prompted by option `7`. Serialises finalisation inside mutex lock, calculates total cost, and confirms booking. |

---

## 6. Automated Testing & Verification

Both services provide automated test suites configured with isolated test ports to prevent collisions with running servers:

### Run Question 1 Tests
```bash
cd q1_library_service
bal test
```
*Port configuration:* Isolated on port `9095` via `tests/Config.toml`.  
*Coverage:* 27 passing tests across models, in-memory store concurrency, and REST endpoints.

### Run Question 2 Tests
```bash
cd q2_rental_service
bal test
```
*Port configuration:* Isolated on port `9096` via `tests/Config.toml`.  
*Coverage:* 24 passing tests covering all 8 RPCs, client streaming, server streaming, and two-phase booking conflict resolution.

### Code Formatting Verification
```bash
bal format --dry-run
```
All packages strictly adhere to Ballerina official formatting rules with 0 diffs.

---

## 7. Postman API Testing (Local Mode v3 YAML)

The repository includes a version-controlled Postman test suite under `postman/`:
- **Collection:** [`postman/collections/q1-library-management/`](file:///c:/Users/Jaden/Documents/Programming/University/DSA/DSA-Assignment/postman/collections/q1-library-management) containing 19 individual request files in v3 YAML format.
- **Environment:** [`postman/environments/peerpressure-local.environment.yaml`](file:///c:/Users/Jaden/Documents/Programming/University/DSA/DSA-Assignment/postman/environments/peerpressure-local.environment.yaml) preconfigured for `http://localhost:9090`.

---

## 8. Academic Integrity and Group Work Declaration

This project represents genuine, collaborative group work authored by the members of the Peer Pressure team. In full accordance with the academic integrity policy of the Namibia University of Science and Technology (NUST) and the DSA612S course brief:

- **Original Authorship:** All software architectures, service implementations, in-memory data structures, client applications, and test harnesses were designed and produced collaboratively by the team.
- **Individual Understanding:** Each team member understands the implementation of their assigned modules and is prepared to discuss and defend their contributions during assessments.
- **Responsible Tool Use:** Development tools, linters, and AI coding assistants were utilised solely for code quality verification and iterative assistance. All logic was reviewed, tested, and validated by human team members. The submission is not an unverified or 100% automated AI generation.
