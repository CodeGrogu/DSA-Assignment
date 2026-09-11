# PEE-37: Q2 Proto Contract Definition & Server Property Management

## 1. Overview & Objectives
**Linear Issue**: PEE-37 (GitHub Issues: #32, #37)  
**Sub-Issues**: #33, #34, #35, #36 (Proto Contract) & #38, #39 (Server Property Management)  
**Parent Epic**: Question 2 – Rental Accommodation System (gRPC)  
**Package**: `peerpressure/q2_rental_service`  

PEE-37 establishes the foundational Protocol Buffers v3 IDL contract for all 8 gRPC operations of the Rental Accommodation System and delivers the server-side property listing management subsystem backed by an ultra-lean, thread-safe in-memory store.

---

## 2. Protocol Buffers Contract (`proto/rental_service.proto`)

The contract defines 8 operations across unary, client-streaming, and server-streaming interaction patterns:

```protobuf
syntax = "proto3";

package rental;

service RentalService {
    // Property Management (Unary)
    rpc add_property (AddPropertyRequest) returns (AddPropertyResponse);
    rpc update_property (UpdatePropertyRequest) returns (UpdatePropertyResponse);
    rpc remove_property (RemovePropertyRequest) returns (RemovePropertyResponse);
    rpc search_property (SearchPropertyRequest) returns (SearchPropertyResponse);

    // User Registration (Client Streaming)
    rpc create_users (stream User) returns (CreateUsersResponse);

    // Listing Browsing (Server Streaming)
    rpc list_available_properties (ListAvailablePropertiesRequest) returns (stream Property);

    // Booking Flow (Unary)
    rpc book_property (BookPropertyRequest) returns (BookPropertyResponse);
    rpc confirm_booking (ConfirmBookingRequest) returns (ConfirmBookingResponse);
}
```

### Mandated Identifier Rule
Per repository standard `asset-identifiers.md`, all primary entity keys across message definitions, record types, and RPC parameters are strictly named `assetTag` in camelCase.

---

## 3. Concurrency Architecture & Thread Safety

### 3.1 Isolated Class & Native Map Storage
State is encapsulated inside an `isolated class PropertyStore` using Ballerina's native `map<Property & readonly>`:

```ballerina
public isolated class PropertyStore {
    private map<Property & readonly> properties = {};
    private int counter = 1001;

    // Guarded within lock blocks
}
```

### 3.2 Data Race Prevention & Isolation
- **Atomic Counter**: Generates collision-free IDs (`PROP-1001`, `PROP-1002`, ...) directly inside the synchronized mutation lock.
- **Single-Pass Immutability**: All storage insertions store an immutable read-only record (`.cloneReadOnly()`) once, preserving thread isolation boundaries without redundant memory cloning.
- **Non-Clobbering Updates**: `updateProperty` only updates fields that are provided, keeping untouched metadata intact.
- **Declarative Query Expressions**: Filtering and regional listing retrieval use clean, native Ballerina query syntax (`from Property p in self.properties.toArray() where ... select p`).
- **Graceful Search**: If an `assetTag` is not found, `search_property` returns `{found: false, status: "Not Available", property: {}}` rather than failing with an unhandled runtime error.

---

## 4. Implemented RPC Handlers & Operations Catalog

| RPC Method | Request Type | Response Type | Description |
| :--- | :--- | :--- | :--- |
| `add_property` | `AddPropertyRequest` | `AddPropertyResponse` | Creates listing with auto-generated `assetTag`. |
| `update_property` | `UpdatePropertyRequest` | `UpdatePropertyResponse` | Updates specified fields without clobbering. |
| `remove_property` | `RemovePropertyRequest` | `RemovePropertyResponse` | Deletes listing; returns host's remaining regional listings. |
| `search_property` | `SearchPropertyRequest` | `SearchPropertyResponse` | Looks up listing; returns details or "Not Available". |
| `create_users` | `stream User` | `CreateUsersResponse` | Client-streaming registration stub. |
| `list_available_properties` | `ListAvailablePropertiesRequest` | `stream Property` | Server-streaming filtered browsing. |
| `book_property` | `BookPropertyRequest` | `BookPropertyResponse` | Temporary cart reservation stub. |
| `confirm_booking` | `ConfirmBookingRequest` | `ConfirmBookingResponse` | Booking finalization stub. |

---

## 5. Automated Testing & Verification

Located in `tests/property_service_test.bal`:
- `testAddPropertyAndRetrieve`: Validates listing creation and immediate retrieval.
- `testUniqueAssetTagsAcrossAdds`: Ensures monotonic non-colliding identifier generation.
- `testUpdatePropertyWithoutClobbering`: Validates partial updates without overwriting untouched fields.
- `testUpdateNonexistentPropertyReturnsError`: Validates error handling on missing update targets.
- `testRemovePropertyReturnsRegionalList`: Validates regional listing filtering after removal.
- `testRemoveNonexistentPropertyReturnsError`: Validates error handling on nonexistent deletion targets.
- `testSearchPropertyFoundAndNotFound`: Validates both found details and graceful "Not Available" fallback.
- `testListAvailablePropertiesFilters`: Validates location, type, and price range filtering.

Execution results:
```text
8 passing | 0 failing | 0 skipped
```
