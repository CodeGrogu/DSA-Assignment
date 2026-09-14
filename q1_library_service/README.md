# Question 1: Library & Resource Management Service (REST)

Distributed RESTful Web Service for multi-campus institutional resource tracking, maintenance scheduling, and work order management built with **Ballerina Swan Lake (2201.13.5)**.

---

## 1. Overview and Architecture

The `q1_library_service` microservice provides a RESTful API for academic and institutional asset tracking across university libraries and campuses. All entity records are indexed by the mandatory camelCase primary key: `assetTag`.

### Directory Structure
```text
q1_library_service/
├── Ballerina.toml             # Package metadata and Swan Lake distribution
├── Config.example.toml        # Sample environment configuration template
├── service.bal                # HTTP REST service and resource method handlers
├── types.bal                  # HTTP response records and payload definitions
├── modules/
│   ├── models/                # Domain models, sub-records, and validation
│   │   ├── models.bal         # Asset, Component, Schedule, WorkOrder, Task records
│   │   └── tests/             # Domain model unit tests
│   └── store/                 # Concurrency-safe in-memory database
│       ├── store.bal          # Isolated AssetStore and InstitutionStore with lock blocks
│       └── tests/             # Concurrency and table operation unit tests
└── tests/
    ├── Config.toml            # Test port isolation configuration (port 9095)
    └── service_test.bal       # End-to-end HTTP integration test suite
```

---

## 2. In-Memory Concurrency and State Model

- **Thread Safety:** State is encapsulated in an `isolated class AssetStore` managing `table<models:Asset> key(assetTag)`.
- **Atomic Operations:** All operations (asset creation, updates, component additions, schedule removal, task updates, work order closures) are executed inside synchronised `lock` blocks.
- **Race Condition Prevention:** Sub-resource mutations and status transitions are performed atomically within the store layer to eliminate time-of-check to time-of-use (TOCTOU) race conditions under high concurrent load.

---

## 3. REST API Endpoint Reference

The service listens on port `9090` by default.

### 3.1 Health and Root Endpoints
| Method | Path | Description | Sample Response |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Service description and API directory | `{"message": "Library & Resource Management System API"}` |
| `GET` | `/health` | Liveness and health probe | `{"status": "UP", "service": "q1_library_service"}` |

### 3.2 Asset Operations
| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/assets` | List all assets. Supports optional `?institution=NUST` and `?site=Main` query parameters. |
| `POST` | `/assets` | Register a new asset. Requires unique, non-empty `assetTag`. |
| `GET` | `/assets/{assetTag}` | Retrieve an asset and all its sub-resources by tag. |
| `PUT` | `/assets/{assetTag}` | Update asset metadata. Preserves existing components, schedules, and work orders if omitted. |
| `DELETE` | `/assets/{assetTag}` | Delete an asset and its associated sub-resources. |
| `GET` | `/assets/overdue` | Query assets with overdue maintenance schedules (`?currentDate=YYYY-MM-DD`). |

### 3.3 Sub-Resource Operations
| Method | Path | Description |
| :--- | :--- | :--- |
| `POST` | `/assets/{assetTag}/components` | Attach a hardware or software component. |
| `DELETE` | `/assets/{assetTag}/components/{compId}` | Remove an attached component. |
| `POST` | `/assets/{assetTag}/schedules` | Attach a maintenance schedule. |
| `DELETE` | `/assets/{assetTag}/schedules/{scheduleId}` | Remove a maintenance schedule. |
| `POST` | `/assets/{assetTag}/work-orders` | Create a new maintenance work order. |
| `PUT` | `/assets/{assetTag}/work-orders/{orderId}` | Update work order description or status (requires tasks complete for `CLOSED`). |
| `POST` | `/assets/{assetTag}/work-orders/{orderId}/tasks` | Append a task to an open work order. |
| `PATCH` | `/assets/{assetTag}/work-orders/{orderId}/tasks/{taskId}` | Update task completion status (`{"completed": true}`). |
| `POST` | `/assets/{assetTag}/work-orders/{orderId}/close` | Finalise and close work order (strictly validates that all tasks are completed). |

### 3.4 Institution Operations
| Method | Path | Description |
| :--- | :--- | :--- |
| `GET` | `/institutions` | List all registered educational institutions. |
| `POST` | `/institutions` | Register a new institution record. |
| `DELETE` | `/institutions/{code}` | Remove an institution record. |

---

## 4. Quick Start and Execution

### 4.1 Prerequisites
Ensure Ballerina Swan Lake 2201.13.5 is installed:
```bash
bal version
```

### 4.2 Build the Service
Compile the package and verify syntax:
```bash
bal build
```

### 4.3 Run the Test Suite
The test suite executes against an isolated test port (`9095`) configured in `tests/Config.toml`:
```bash
bal test
```
All 27 automated tests (spanning models, store, and HTTP service) will run and pass.

### 4.4 Start the Service
```bash
bal run
```
The service will start listening on `http://localhost:9090`.

---

## 5. Testing with cURL

### Register a New Asset
```bash
curl -X POST http://localhost:9090/assets \
  -H "Content-Type: application/json" \
  -d '{
    "assetTag": "AST-1001",
    "name": "Library Server Rack Alpha",
    "category": "HARDWARE",
    "status": "OPERATIONAL",
    "dateAcquired": "2026-01-15",
    "institution": "NUST",
    "site": "Main Campus"
  }'
```

### Query Overdue Maintenance
```bash
curl -X GET "http://localhost:9090/assets/overdue?currentDate=2026-09-14"
```

### Add a Task to a Work Order
```bash
curl -X POST http://localhost:9090/assets/AST-1001/work-orders/WO-501/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "TSK-01",
    "description": "Inspect power backup battery health",
    "completed": false
  }'
```

### Mark Task Completed
```bash
curl -X PATCH http://localhost:9090/assets/AST-1001/work-orders/WO-501/tasks/TSK-01 \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

### Close the Work Order
```bash
curl -X POST http://localhost:9090/assets/AST-1001/work-orders/WO-501/close
```
