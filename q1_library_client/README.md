# Question 1: Library & Resource Management System Client (REST)

Console and interactive terminal client for the Library & Resource Management System built with **Ballerina Swan Lake (2201.13.5)**.

---

## 1. Overview

`q1_library_client` provides both direct command-line arguments and an interactive terminal menu interface to interact with the RESTful `q1_library_service` microservice. All entity records are addressed using the canonical camelCase primary key: `assetTag`.

---

## 2. Configuration

The client connects to `http://localhost:9090` by default. To customise the service endpoint or request timeout, copy the example configuration file:

```bash
cp Config.example.toml Config.toml
```

Edit `Config.toml`:
```toml
[peerpressure.q1_library_client]
serviceUrl = "http://localhost:9090"
clientTimeout = 10.0
```

---

## 3. Execution

Ensure the REST service is running in `q1_library_service` before launching the client:

```bash
# Terminal 1: Run Service
cd ../q1_library_service
bal run
```

In a second terminal:

```bash
# Terminal 2: Run Client
cd q1_library_client
bal run
```

---

## 4. Interactive Terminal Menu (Options 1 to 16)

When executed without arguments (`bal run`), the client presents an interactive menu covering the full lifecycle of assets, sub-resources, work orders, tasks, and institutions:

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

---

## 5. Direct Command-Line Arguments Mode

For scripted execution and rapid querying, the client supports direct sub-commands:

```bash
# Liveness and health check
bal run -- health

# List assets (unfiltered)
bal run -- list

# Filter assets by institution and site
bal run -- list NUST "Main Campus"

# Retrieve specific asset and all sub-resources
bal run -- get AST-1001

# Inspect operational status and associated work orders
bal run -- status AST-1001

# Query overdue maintenance assets against current date
bal run -- overdue

# Query overdue assets with specific date reference
bal run -- overdue 2026-09-14

# View all work orders for an asset
bal run -- work-orders AST-1001

# View tasks on a specific work order
bal run -- tasks AST-1001 WO-501

# Close a work order directly from CLI
bal run -- close-wo AST-1001 WO-501

# Delete an asset by tag
bal run -- delete AST-1001

# Display CLI help menu
bal run -- help
```

---

## 6. Build and Verification

Compile the executable JAR:
```bash
bal build
```

Run formatting checks:
```bash
bal format --dry-run
```
