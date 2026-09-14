# Postman Collections (v3 YAML Format)

Collections in Postman Local Mode are stored as modular directories containing v3 YAML files for Git version control:

```text
postman/collections/
├── README.md                            # Collections documentation and execution guide
├── q1-library-management/               # Question 1 REST API test collection (19 requests)
│   ├── definition.yaml                  # Collection metadata and configuration
│   ├── 01-health-check.request.yaml
│   ├── ...
│   └── 19-delete-asset.request.yaml
└── q2-rental-accommodation/             # Question 2 gRPC test collection (8 operations)
    ├── definition.yaml                  # Collection metadata and configuration
    ├── 01-add-property.request.yaml
    ├── ...
    ├── 08-remove-property.request.yaml
    └── q2-rental-accommodation.postman_collection.json # Portable collection JSON export
```

---

## Collections Overview

### 1. `q1-library-management`
- **Protocol**: HTTP / RESTful API (Port `9090`)
- **Requests**: 19 requests covering health check, catalogue, asset CRUD, institution filtering, component management, maintenance scheduling, and work order lifecycle.
- **Execution Order**: Sequential execution (orders `1000` through `19000`) enabling automated variable chaining (e.g. capturing `assetTag`, `compId`, `scheduleId`, `orderId`, `taskId`).

### 2. `q2-rental-accommodation`
- **Protocol**: gRPC over HTTP/2 (Port `9090` / `9096`)
- **Requests**: 8 operations spanning Unary property management, Client-streaming user onboarding, Server-streaming availability listing, and Two-Phase booking reservation and confirmation.
- **Execution Order**: Sequential execution (orders `1000` through `8000`) testing property creation, retrieval, updates, user registration, filtered discovery, cart staging (`book_property`), finalisation (`confirm_booking`), and teardown (`remove_property`).

---

## Running with Postman CLI

```bash
# Execute Question 1 REST collection
postman collection run postman/collections/q1-library-management \
  --environment postman/environments/peerpressure-local.environment.yaml

# Execute Question 2 gRPC collection
postman collection run postman/collections/q2-rental-accommodation \
  --environment postman/environments/peerpressure-local.environment.yaml
```
