# Question 1: Library & Resource Management System (REST)

Distributed Library and Resource Management System built with **Ballerina Swan Lake (2201.13.x)**.

---

## 1. Overview

The Library & Resource Management System provides a centralised RESTful API and command-line interface (CLI) to track books, electronic media, equipment, and physical spaces across multiple ministry institutions and campus sites.

All entity records are indexed by a unique primary key: `assetTag`.

---

## 2. Module Architecture

```text
q1_library_service/
├── Ballerina.toml             # Package definition and distribution metadata
├── Config.example.toml        # Configuration template for port and runtime settings
├── service.bal                # RESTful HTTP service listener and resource endpoints
├── types.bal                  # API response records and DTOs
├── modules/
│   ├── models/                # Canonical Ballerina record definitions and status types
│   │   ├── models.bal         # Asset, Component, Schedule, WorkOrder, Task records
│   │   └── tests/             # Record validation and serialization unit tests
│   └── store/                 # Thread-safe in-memory storage engine
│       ├── store.bal          # Isolated AssetStore with primary key indexing & sub-resources
│       └── tests/             # CRUD concurrency, sub-resources, and filter tests
└── tests/
    └── service_test.bal       # HTTP integration tests against live endpoints
```

---

## 3. Prerequisites

* **Ballerina**: `2201.13.5 (Swan Lake Update 13)` or later.
* **Operating System**: Windows 11, macOS, or Linux.

Verify installation:
```bash
bal version
```

---

## 4. Setup and Configuration

1. Copy the example configuration file:
   ```bash
   cp Config.example.toml Config.toml
   ```
2. Modify `Config.toml` to customize the listening port (default: `9090`).

---

## 5. Build, Test, and Execution

### Build Executable
```bash
bal build
```

### Run Automated Tests
```bash
bal test
```

### Run the REST Service
```bash
bal run
```

### Run the CLI Client
The interactive and command-line client is maintained in the dedicated package `q1_library_client`:
```bash
cd ../q1_library_client

# Interactive menu
bal run

# Direct CLI commands
bal run -- health
bal run -- list
bal run -- get TAG-TEST-001
bal run -- overdue
```

---

## 6. Complete Endpoints Catalog

| Method | Resource Path | Description | Status Code |
| :--- | :--- | :--- | :--- |
| `GET` | `/health` | Service health status and timestamp | `200 OK` |
| `GET` | `/` | API catalog and route listing | `200 OK` |
| `GET` | `/assets` | Retrieve all assets (supports `?institution=...&site=...`) | `200 OK` |
| `POST` | `/assets` | Register a new asset record | `201 Created`, `400 Bad Request` |
| `GET` | `/assets/{assetTag}` | Lookup an individual asset by its unique `assetTag` | `200 OK`, `404 Not Found` |
| `PUT` | `/assets/{assetTag}` | Update an existing asset metadata | `200 OK`, `404 Not Found` |
| `DELETE` | `/assets/{assetTag}` | Permanently remove an asset and attached sub-resources | `200 OK`, `404 Not Found` |
| `GET` | `/assets/{assetTag}/status`| Operational status and active work orders summary | `200 OK`, `404 Not Found` |
| `GET` | `/assets/overdue` | Query assets with overdue maintenance schedules | `200 OK` |
| `POST` | `/assets/{assetTag}/components` | Attach a component sub-resource to an asset | `201 Created`, `404 Not Found` |
| `DELETE`| `/assets/{assetTag}/components/{compId}` | Remove a component sub-resource from an asset | `200 OK`, `404 Not Found` |
| `POST` | `/assets/{assetTag}/schedules` | Attach a maintenance/booking schedule to an asset | `201 Created`, `404 Not Found` |
| `DELETE`| `/assets/{assetTag}/schedules/{scheduleId}` | Remove a schedule sub-resource from an asset | `200 OK`, `404 Not Found` |
| `POST` | `/assets/{assetTag}/work-orders` | Create a maintenance work order with checklist tasks | `201 Created`, `404 Not Found` |
| `PUT` | `/assets/{assetTag}/work-orders/{orderId}` | Update work order status and task completion states | `200 OK`, `404 Not Found` |

---

## 7. Quality Gates & Standards

* **Identifier Convention**: All asset identifiers use camelCase `assetTag`.
* **Thread Safety**: Storage modifications are guarded via `isolated` class locks and `.cloneReadOnly()`.
* **Testing Gate**: 100% test pass rate across `models`, `store`, and `service` modules.
