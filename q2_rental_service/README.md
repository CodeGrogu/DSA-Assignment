# Question 2: Rental Accommodation System (gRPC)

Distributed Rental Accommodation Microservice built with **Ballerina Swan Lake (2201.13.x)** and **Protocol Buffers v3**.

---

## 1. Overview

The Rental Accommodation System provides a high-performance gRPC service for managing property listings, streaming user registrations, browsing available properties with real-time streaming, and handling guest reservations.

All property listings are uniquely indexed by a mandatory primary key: `assetTag`.

---

## 2. Architecture & File Structure

```text
q2_rental_service/
├── Ballerina.toml             # Package definition and distribution metadata
├── proto/
│   └── rental_service.proto   # Protobuf v3 schema defining all 8 gRPC operations
├── rental_service_pb.bal      # Code-generated stubs, callers, and record types
├── rentalservice_service.bal  # Main gRPC service listener and RPC handlers
├── store.bal                  # Concurrency-safe in-memory PropertyStore with table storage
└── tests/
    └── property_service_test.bal # Automated unit and integration test suite
```

---

## 3. Protocol Buffers & Code Generation

The gRPC contract is defined in `proto/rental_service.proto`. To regenerate the Ballerina stubs and descriptors, run:

```bash
bal tool pull grpc
bal grpc --input proto/rental_service.proto --output . --mode service
```

---

## 4. Operations Catalog

The service exposes 8 gRPC operations spanning three interaction patterns:

| # | RPC Method | Paradigm | Description | Status |
| :- | :--- | :--- | :--- | :--- |
| 1 | `add_property` | Unary | Creates listing; auto-generates unique `assetTag` | Implemented |
| 2 | `update_property` | Unary | Updates provided fields without clobbering existing data | Implemented |
| 3 | `remove_property` | Unary | Deletes listing; returns host's remaining regional listings | Implemented |
| 4 | `search_property` | Unary | Searches by `assetTag`; returns details or "Not Available" | Implemented |
| 5 | `create_users` | Client Streaming | Registers a stream of multiple Host/Guest user profiles | Stub |
| 6 | `list_available_properties` | Server Streaming | Streams available listings matching optional filters | Implemented |
| 7 | `book_property` | Unary | Stages tentative booking in temporary guest cart | Stub |
| 8 | `confirm_booking` | Unary | Validates overlap, calculates total cost, finalizes booking | Stub |

---

## 5. Quick Start

### Build Package
```bash
bal build
```

### Run Automated Tests
```bash
bal test
```

### Run the gRPC Service
```bash
bal run
```
The gRPC listener will start on port `9090`.

---

## 6. Concurrency & Quality Gates

* **Thread-Safe Store**: In-memory state is managed in an `isolated class PropertyStore` using `table<PropertyRecord> key(assetTag)` guarded by `lock` statements and `.cloneReadOnly()`.
* **Identifier Standard**: All unique entity IDs strictly follow the camelCase `assetTag` convention.
* **Testing**: Comprehensive automated test coverage in `tests/property_service_test.bal`.
