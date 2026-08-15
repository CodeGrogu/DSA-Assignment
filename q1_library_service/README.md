# Question 1: Library & Resource Management System (REST)

Distributed Library and Resource Management System built with **Ballerina Swan Lake (2201.13.5)**.

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
├── modules/
│   ├── models/                # Canonical Ballerina record definitions and status types
│   │   ├── models.bal         # Asset, Component, Schedule, WorkOrder, Task records
│   │   └── tests/             # Record validation and serialization unit tests
│   ├── store/                 # Thread-safe in-memory storage engine
│   │   ├── store.bal          # Isolated AssetStore with primary key indexing
│   │   └── tests/             # CRUD concurrency and failure mode tests
│   └── client/                # CLI client communication module
│       ├── client.bal         # HTTP client helper and interactive prompt interface
│       └── tests/             # Client initialisation and integration tests
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

---

## 6. Endpoints Baseline

| Method | Resource Path | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | Service health status and metadata |
| `GET` | `/` | API catalog and route listing |
| `GET` | `/assets` | Retrieve all assets across all campuses |
| `GET` | `/assets/{assetTag}` | Lookup an individual asset by its unique `assetTag` |
| `POST` | `/assets` | Register a new asset *(in development)* |
| `PUT` | `/assets/{assetTag}` | Update an existing asset *(in development)* |
| `DELETE` | `/assets/{assetTag}` | Remove an asset from the store *(in development)* |

---

## 7. Quality Gates & Standards

* **Identifier Convention**: All asset identifiers use camelCase `assetTag`.
* **Thread Safety**: Storage modifications are guarded via `isolated` class locks.
* **Testing Gate**: Must pass 100% of unit and integration tests before commit.
