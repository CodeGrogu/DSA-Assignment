# Postman Collections, Specs & Environments (v3 YAML Format)

This directory houses the version-controlled Postman collections, API specifications, and environment templates for the **PeerPressure** Postman workspace using the **Postman v3 YAML specification** required for Local Mode and Native Git workflows.

---

## Directory Structure

```text
postman/
├── collections/
│   ├── README.md                            # Collections documentation and execution guide
│   ├── q1-library-management/
│   │   ├── definition.yaml                  # Q1 Collection metadata and configuration
│   │   ├── 01-health-check.request.yaml     # GET /health
│   │   ├── 02-api-catalog.request.yaml     # GET / (API Catalog)
│   │   ├── 03-get-all-assets.request.yaml   # GET /assets
│   │   ├── 04-create-asset.request.yaml     # POST /assets
│   │   ├── 05-get-asset-by-tag.request.yaml # GET /assets/{assetTag}
│   │   ├── 06-update-asset.request.yaml     # PUT /assets/{assetTag}
│   │   ├── 07-filter-by-institution-and-site.request.yaml # GET /assets?institution=...&site=...
│   │   ├── 08-get-asset-status.request.yaml # GET /assets/{assetTag}/status
│   │   ├── 09-get-overdue-assets.request.yaml # GET /assets/overdue
│   │   ├── 10-add-component.request.yaml    # POST /assets/{assetTag}/components
│   │   ├── 11-remove-component.request.yaml # DELETE /assets/{assetTag}/components/{compId}
│   │   ├── 12-add-schedule.request.yaml     # POST /assets/{assetTag}/schedules
│   │   ├── 13-remove-schedule.request.yaml  # DELETE /assets/{assetTag}/schedules/{scheduleId}
│   │   ├── 14-create-work-order.request.yaml # POST /assets/{assetTag}/work-orders
│   │   ├── 15-update-work-order.request.yaml # PUT /assets/{assetTag}/work-orders/{orderId}
│   │   ├── 16-add-task-to-work-order.request.yaml # POST /assets/{assetTag}/work-orders/{orderId}/tasks
│   │   ├── 17-update-task-completion.request.yaml # PATCH /assets/{assetTag}/work-orders/{orderId}/tasks/{taskId}
│   │   ├── 18-close-work-order.request.yaml # POST /assets/{assetTag}/work-orders/{orderId}/close
│   │   ├── 19-delete-asset.request.yaml     # DELETE /assets/{assetTag} (Teardown)
│   │   └── .resources/                      # Supporting scripts and metadata
│   └── q2-rental-accommodation/
│       ├── definition.yaml                  # Q2 Collection metadata and configuration
│       ├── 01-add-property.request.yaml     # POST /rental.RentalService/add_property
│       ├── 02-search-property.request.yaml  # POST /rental.RentalService/search_property
│       ├── 03-update-property.request.yaml  # POST /rental.RentalService/update_property
│       ├── 04-create-users.request.yaml     # POST /rental.RentalService/create_users (Client stream)
│       ├── 05-list-available-properties.request.yaml # POST /rental.RentalService/list_available_properties (Server stream)
│       ├── 06-book-property.request.yaml    # POST /rental.RentalService/book_property (Phase 1 cart)
│       ├── 07-confirm-booking.request.yaml  # POST /rental.RentalService/confirm_booking (Phase 2 finalisation)
│       ├── 08-remove-property.request.yaml  # POST /rental.RentalService/remove_property (Teardown)
│       └── q2-rental-accommodation.postman_collection.json # Portable collection JSON
├── specs/
│   ├── README.md                            # Specifications catalogue and import guide
│   └── rental_service.proto                 # Q2 Rental Accommodation Service Protobuf contract
├── environments/
│   ├── peerpressure-dev.environment.yaml    # Development environment configuration
│   └── peerpressure-local.environment.yaml  # Local environment configuration
└── globals/
    └── workspace.globals.yaml               # Shared global variables
```

---

## Question 1: RESTful API Test Suite (`q1-library-management`)

The `q1-library-management` collection contains 19 automated request definitions executing the full asset lifecycle, component tracking, maintenance schedules, and multi-task work order resolution:

| Step | Request Name | Method | Path | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **01** | Health Check | `GET` | `/health` | Verify operational health |
| **02** | API Catalog | `GET` | `/` | Discover available routes |
| **03** | Get All Assets | `GET` | `/assets` | Retrieve initial asset inventory |
| **04** | Create Asset | `POST` | `/assets` | Register a new asset entity |
| **05** | Get Asset by Tag | `GET` | `/assets/{{assetTag}}` | Retrieve asset by unique tag |
| **06** | Update Asset | `PUT` | `/assets/{{assetTag}}` | Modify asset metadata |
| **07** | Filter by Institution & Site | `GET` | `/assets?institution=...&site=...` | Query assets by location |
| **08** | Get Asset Status | `GET` | `/assets/{{assetTag}}/status` | Inspect status and active orders |
| **09** | Get Overdue Assets | `GET` | `/assets/overdue` | Detect overdue maintenance or booking |
| **10** | Add Component | `POST` | `/assets/{{assetTag}}/components` | Attach hardware sub-component |
| **11** | Remove Component | `DELETE` | `/assets/{{assetTag}}/components/{{compId}}` | Detach sub-component |
| **12** | Add Schedule | `POST` | `/assets/{{assetTag}}/schedules` | Attach maintenance schedule |
| **13** | Remove Schedule | `DELETE` | `/assets/{{assetTag}}/schedules/{{scheduleId}}` | Detach schedule |
| **14** | Create Work Order | `POST` | `/assets/{{assetTag}}/work-orders` | Open repair work order with task |
| **15** | Update Work Order | `PUT` | `/assets/{{assetTag}}/work-orders/{{orderId}}` | Update work order to IN_PROGRESS |
| **16** | Add Task to Work Order | `POST` | `/assets/{{assetTag}}/work-orders/{{orderId}}/tasks` | Attach actionable sub-task |
| **17** | Update Task Completion | `PATCH` | `/assets/{{assetTag}}/work-orders/{{orderId}}/tasks/{{taskId}}` | Mark sub-task completed |
| **18** | Close Work Order | `POST` | `/assets/{{assetTag}}/work-orders/{{orderId}}/close` | Finalise and close order |
| **19** | Delete Asset | `DELETE` | `/assets/{{assetTag}}` | Teardown cleanup |

---

## Question 2: gRPC Service Test Suite (`q2-rental-accommodation`)

The `q2-rental-accommodation` collection contains 8 automated request definitions testing all RPC methods of the Vacation Property Rental Accommodation System:

| Step | Request Name | RPC Method | Type | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **01** | Add Property | `add_property` | Unary | Register property, auto-generate `assetTag`, initialise `AVAILABLE` status |
| **02** | Search Property | `search_property` | Unary | Query property by `assetTag`, verify `Available` status |
| **03** | Update Property | `update_property` | Unary | Update pricing, title, and operational status |
| **04** | Create Users | `create_users` | Client Streaming | Batch register stream of Host and Guest user accounts |
| **05** | List Available Properties | `list_available_properties` | Server Streaming | Stream active listings filtered by location, type, and price range |
| **06** | Book Property | `book_property` | Unary | Phase 1: validate dates, stage reservation in cart, capture `bookingId` |
| **07** | Confirm Booking | `confirm_booking` | Unary | Phase 2: mutex-locked overlap check, finalise booking, clear cart |
| **08** | Remove Property | `remove_property` | Unary | Verify host ownership, remove property, return remaining listings |

---

## Environment Variables Reference

Both `peerpressure-local.environment.yaml` and `peerpressure-dev.environment.yaml` provide complete configuration for Question 1 (REST) and Question 2 (gRPC):

| Variable Name | Default Local Value | Purpose / Scope |
| :--- | :--- | :--- |
| `base_url` | `http://localhost` | Q1 REST service base URL |
| `port` | `9090` | Q1 REST service port |
| `assetTag` | `TAG-TEST-001` | Q1 Asset unique identifier |
| `compId` | `COMP-01` | Q1 Sub-component identifier |
| `scheduleId` | `SCH-01` | Q1 Maintenance schedule identifier |
| `orderId` | `WO-101` | Q1 Work order identifier |
| `taskId` | `TSK-02` | Q1 Work order sub-task identifier |
| `instCode` | `NUST` | Q1 Institution code |
| `grpc_host` | `localhost` | Q2 gRPC service host address |
| `grpc_port` | `9090` | Q2 gRPC service port |
| `propertyTag` | `PROP-1001` | Q2 Property listing `assetTag` |
| `hostId` | `HOST-001` | Q2 Host user identifier |
| `guestId` | `GUEST-001` | Q2 Guest user identifier |
| `bookingId` | `BOOK-1` | Q2 Booking reservation identifier |
| `userId` | `USR-101` | Q2 Registered user identifier |
| `location` | `Swakopmund` | Q2 Regional location filter |
| `propertyType` | `Apartment` | Q2 Accommodation category |
| `pricePerNight` | `1200.0` | Q2 Nightly rental rate |

---

## Running Collections in Postman Local Mode

### Prerequisites

1. Start the Q1 REST service:
   ```bash
   cd q1_library_service
   bal run
   ```
2. Start the Q2 gRPC service (on a distinct port if running concurrently, e.g. `bal run` with port configured in `Config.toml`):
   ```bash
   cd q2_rental_service
   bal run
   ```

### Execution via Postman Desktop (Local Mode)

1. Open Postman connected to this local repository.
2. Select the **PeerPressure Local** or **PeerPressure Dev** environment.
3. Open either:
   - **Q1 - Library & Resource Management System** collection to run all 19 REST tests.
   - **Q2 - Vacation Property Rental Accommodation System** collection to run all 8 gRPC tests.
4. Click **Run collection** to execute the test suite sequentially with automated assertions.

### Execution via Postman CLI

```bash
# Execute Question 1 REST collection
postman collection run postman/collections/q1-library-management \
  --environment postman/environments/peerpressure-local.environment.yaml

# Execute Question 2 gRPC collection
postman collection run postman/collections/q2-rental-accommodation \
  --environment postman/environments/peerpressure-local.environment.yaml
```
