# Question 2: Rental Accommodation System (gRPC)

Distributed Vacation Property Rental Accommodation Microservice built with **Ballerina Swan Lake (2201.13.5)** and **Protocol Buffers v3**.

---

## 1. Overview and Architecture

The `q2_rental_service` microservice provides high-performance gRPC communication for vacation rental listings, streaming user onboarding, server-streaming property browsing, and two-phase booking reservations.

All properties are uniquely identified across the service and database by the mandatory camelCase primary key: `assetTag`.

### Directory Structure
```text
q2_rental_service/
├── Ballerina.toml             # Package definition and Swan Lake distribution
├── Config.example.toml        # Sample environment configuration template
├── proto/
│   └── rental_service.proto   # Protobuf v3 schema defining all 8 gRPC operations
├── rental_service_pb.bal      # Code-generated stubs, callers, and record types
├── rentalservice_service.bal  # Main gRPC service listener and RPC implementations
├── store.bal                  # Concurrency-safe PropertyStore with table storage & mutex locks
└── tests/
    ├── Config.toml            # Isolated test port configuration (port 9096)
    └── property_service_test.bal # Comprehensive unit and streaming integration test suite
```

---

## 2. Protocol Buffers & Stub Compilation (`bal grpc`)

The service and data contracts are defined in `proto/rental_service.proto`. To compile or regenerate Ballerina stubs:

### Step 1: Ensure the gRPC Tool is Installed
```bash
bal tool pull grpc
```

### Step 2: Generate Service Stubs
To regenerate the service stubs and descriptors in `q2_rental_service`:
```bash
bal grpc --input proto/rental_service.proto --output . --mode service
```

### Step 3: Generate Client Stubs (for Client Package)
To regenerate client stubs in `q2_rental_client`:
```bash
bal grpc --input ../q2_rental_service/proto/rental_service.proto --output ../q2_rental_client --mode client
```

---

## 3. Operations Catalog (All 8 Operations Implemented)

The gRPC service implements all eight required operations:

| # | RPC Method | Interaction Paradigm | Description | Status |
| :- | :--- | :--- | :--- | :--- |
| 1 | `add_property` | Unary | Creates a new property listing with auto-generated unique `assetTag`. | Implemented |
| 2 | `update_property` | Unary | Updates property metadata (name, price, status) without clobbering omitted fields. | Implemented |
| 3 | `remove_property` | Unary | Validates host ownership, removes listing, and returns remaining regional properties. | Implemented |
| 4 | `search_property` | Unary | Queries listing by `assetTag`. Returns listing details or "Not Available". | Implemented |
| 5 | `create_users` | Client Streaming | Ingests a continuous stream of Host and Guest profiles over a single channel. | Implemented |
| 6 | `list_available_properties` | Server Streaming | Streams matching available listings back to the client one by one. | Implemented |
| 7 | `book_property` | Unary | Validates dates, checks overlap, and stages tentative reservation in temporary cart. | Implemented |
| 8 | `confirm_booking` | Unary | Serialises finalisation inside mutex lock, calculates cost, and confirms booking. | Implemented |

---

## 4. In-Memory Concurrency and Two-Phase Booking Architecture

- **Isolated Property Store:** Managed in `isolated class PropertyStore` in `store.bal` using `table<Property & readonly> key(assetTag)` and `table<User & readonly> key(userId)`.
- **Two-Phase Booking Protocol:**
  - **Phase 1 (`book_property`):** Validates check-in dates (rejecting dates in the past and verifying check-out is after check-in), verifies property status, checks date overlap against confirmed bookings, calculates estimated cost, and stages a `BookingCartEntry`.
  - **Phase 2 (`confirm_booking`):** Serialises booking finalisation inside a synchronized mutex `lock` block. Prevents double-booking even when multiple clients attempt to confirm simultaneously.

---

## 5. Quick Start and Execution

### 5.1 Build the Package
```bash
bal build
```

### 5.2 Run Automated Tests
Tests execute against isolated port `9096` defined in `tests/Config.toml`:
```bash
bal test
```
All 24 automated unit and integration tests (including client streaming and server streaming) will run and pass.

### 5.3 Run the Service
```bash
bal run
```
The gRPC listener will start listening on port `9090`.

### 5.4 Run the Interactive Client
In a separate terminal:
```bash
cd ../q2_rental_client
bal run
```
