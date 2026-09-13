# Postman Collections, Specs & Environments (v3 YAML Format)

This directory houses the version-controlled Postman collections, API specifications, and environment templates for the **PeerPressure** Postman workspace using the **Postman v3 YAML specification** required for Local Mode and Native Git workflows.

---

## Directory Structure

```text
postman/
├── collections/
│   └── q1-library-management/
│       ├── definition.yaml                  # Collection metadata & configuration
│       ├── 01-health-check.request.yaml     # GET /health
│       ├── 02-api-catalog.request.yaml     # GET / (API Catalog)
│       ├── 03-get-all-assets.request.yaml   # GET /assets
│       ├── 04-create-asset.request.yaml     # POST /assets
│       ├── 05-get-asset-by-tag.request.yaml # GET /assets/{assetTag}
│       ├── 06-update-asset.request.yaml     # PUT /assets/{assetTag}
│       ├── 07-filter-by-institution-and-site.request.yaml # GET /assets?institution=...&site=...
│       ├── 08-get-asset-status.request.yaml # GET /assets/{assetTag}/status
│       ├── 09-get-overdue-assets.request.yaml # GET /assets/overdue
│       ├── 10-add-component.request.yaml    # POST /assets/{assetTag}/components
│       ├── 11-remove-component.request.yaml # DELETE /assets/{assetTag}/components/{compId}
│       ├── 12-add-schedule.request.yaml     # POST /assets/{assetTag}/schedules
│       ├── 13-remove-schedule.request.yaml  # DELETE /assets/{assetTag}/schedules/{scheduleId}
│       ├── 14-create-work-order.request.yaml # POST /assets/{assetTag}/work-orders
│       ├── 15-update-work-order.request.yaml # PUT /assets/{assetTag}/work-orders/{orderId}
│       ├── 16-add-task-to-work-order.request.yaml # POST /assets/{assetTag}/work-orders/{orderId}/tasks
│       ├── 17-update-task-completion.request.yaml # PATCH /assets/{assetTag}/work-orders/{orderId}/tasks/{taskId}
│       ├── 18-close-work-order.request.yaml # POST /assets/{assetTag}/work-orders/{orderId}/close
│       ├── 19-delete-asset.request.yaml     # DELETE /assets/{assetTag} (Teardown)
│       └── .resources/                      # Supporting scripts and metadata
├── specs/
│   ├── README.md                            # Specifications catalog & import guide
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
| **09** | Get Overdue Assets | `GET` | `/assets/overdue` | Detect overdue maintenance/booking |
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

## Question 2: gRPC Service Specifications (`specs/`)

The `postman/specs/` directory hosts `rental_service.proto` defining the 8 gRPC operations of the Rental Accommodation System:
- Unary Property Operations: `add_property`, `update_property`, `remove_property`, `search_property`
- Client Streaming: `create_users` (register multiple Hosts/Guests in one streamed call)
- Server Streaming: `list_available_properties` (stream matching listings one by one)
- Booking Operations: `book_property`, `confirm_booking`

In Postman Local Mode, import `postman/specs/rental_service.proto` to generate native gRPC requests.

---

## Environment Variables Reference

| Variable Name | Default Dev Value | Description |
| :--- | :--- | :--- |
| `base_url` | `http://localhost` | REST API host address |
| `port` | `9090` | Active REST HTTP port |
| `assetTag` | `TAG-TEST-001` | Active asset tag identifier |
| `compId` | `COMP-01` | Component sub-resource identifier |
| `scheduleId` | `SCH-01` | Maintenance schedule identifier |
| `orderId` | `WO-101` | Work order identifier |
| `taskId` | `TSK-02` | Work order sub-task identifier |
| `grpc_host` | `localhost` | gRPC service host address |
| `grpc_port` | `9090` | Active gRPC service port |

---

## Running Collections in Postman Local Mode

1. Open Postman desktop connected to this repository.
2. Select the **PeerPressure Dev** environment from the environment selector.
3. Open the **Q1 - Library & Resource Management System** collection.
4. Click **Run collection** to execute all 19 requests sequentially with automated assertion validation.
