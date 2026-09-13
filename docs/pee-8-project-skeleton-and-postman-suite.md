# PEE-8: Ballerina Project Skeleton & Postman Test Suite Initialization

## 1. Overview & Objectives
**Linear Issue**: PEE-8  
**Parent Epic**: [PEE-7] Question 1 – Library & Resource Management System  
**Lead Contributor**: Peer Pressure Team  

The objective of PEE-8 was to establish the foundational Ballerina Swan Lake package structure and configure an enterprise-grade automated API testing harness adhering to the **v3 YAML Local Mode** Postman format.

---

## 2. Project Architecture & Directory Layout

The service package is located under `q1_library_service` with modular package separation:

```
q1_library_service/
├── Ballerina.toml             # Package definition and compiler metadata
├── Config.example.toml        # Environment configuration template
├── Dependencies.toml          # Resolved Ballerina Swan Lake dependencies
├── service.bal                # HTTP REST service and resource definitions
├── types.bal                  # API response records and DTOs
├── modules/
│   ├── models/                # Canonical domain models and validation rules
│   └── store/                 # Thread-safe in-memory asset storage engine
└── tests/
    └── service_test.bal       # Integration tests against local test listener

q1_library_client/             # Dedicated CLI & interactive terminal client package
├── Ballerina.toml             # Client package metadata
├── Config.example.toml        # Client configuration template
├── client.bal                 # Dual-mode CLI commands and interactive console UI
├── types.bal                  # Client-side domain records
└── tests/                     # Automated client test suite
```

---

## 3. Postman Collection Architecture (v3 YAML)

All API test definitions are version-controlled in `.postman/` and `postman/collections/q1-library-management/` using the v3 YAML format:

- **Environment Config**: Port, hostname, and dynamic session variables (`{{assetTag}}`, `{{compId}}`, `{{scheduleId}}`, `{{orderId}}`).
- **Standardized Identifier**: `assetTag` in camelCase across all URLs, body payloads, and assertions.
- **Request Catalog**:
  1. `01-health-check.request.yaml` – Liveness and health check (`/health`).
  2. `02-api-catalog.request.yaml` – Root discovery endpoint listing available routes (`/`).
  3. `03-get-all-assets.request.yaml` – Retrieve all registered assets (`/assets`).
  4. `04-create-asset.request.yaml` – Create new asset (`POST /assets`).
  5. `05-get-asset-by-tag.request.yaml` – Read asset by primary tag (`/assets/{{assetTag}}`).
  6. `06-update-asset.request.yaml` – Update asset metadata (`PUT /assets/{{assetTag}}`).
  7. `07-filter-by-institution-and-site.request.yaml` – Query parameter filtering.
  8. `08-get-asset-status.request.yaml` – Status and active booking summary.
  9. `09-get-overdue-assets.request.yaml` – Filter overdue maintenance schedules.
  10. `10-add-component.request.yaml` – Attach sub-component item.
  11. `11-remove-component.request.yaml` – Detach sub-component item.
  12. `12-add-schedule.request.yaml` – Attach maintenance schedule.
  13. `13-remove-schedule.request.yaml` – Detach maintenance schedule.
  14. `14-create-work-order.request.yaml` – Create maintenance work order.
  15. `15-update-work-order.request.yaml` – Resolve work order and checklist tasks.
  16. `16-delete-asset.request.yaml` – Delete asset by tag.

---

## 4. Verification & Quality Gates
- Compiles with Ballerina Swan Lake 2201.13.x toolchain.
- Validated via `bal build` and `bal test`.
- Conforms to KISS architectural principles and clean module boundaries.
