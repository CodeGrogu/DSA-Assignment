# PEE-10: Thread-Safe In-Memory Asset Store with Sub-Resource Management

## 1. Overview & Objectives
**Linear Issue**: PEE-10  
**Parent Epic**: [PEE-7] Question 1 – Library & Resource Management System  
**Module**: `peerpressure/q1_library_service.store`  

PEE-10 implements an isolated, high-performance, thread-safe in-memory database engine for managing assets, querying overdue maintenance schedules, filtering by institution/site, and performing atomic mutations on nested sub-resources.

---

## 2. Concurrency Architecture & Thread Safety

### 2.1 Isolated Class & Table Storage
The repository encapsulates state using Ballerina's `table<models:Asset> key(assetTag)` inside an `isolated class AssetStore`:

```ballerina
isolated class AssetStore {
    private table<models:Asset> key(assetTag) assetTable = table [];
    // Isolated methods guarded by lock statements
}
```

### 2.2 Immutability & Data Race Prevention
- All mutation operations accept domain records and store them using `.cloneReadOnly()`.
- All read accessors (`getAsset`, `getAllAssets`, `filterAssets`, `getOverdueAssets`) return read-only clones (`.cloneReadOnly()`), preventing external callers from mutating internal state without acquiring class locks.

---

## 3. Storage API & Capabilities

| Function | Parameters | Return Type | Description |
| :--- | :--- | :--- | :--- |
| `addAsset` | `models:Asset asset` | `error?` | Inserts asset; rejects duplicate `assetTag`. |
| `getAsset` | `string assetTag` | `models:Asset?` | Retrieves asset by primary key. |
| `updateAsset` | `models:Asset asset` | `error?` | Replaces asset fields; returns error if not found. |
| `deleteAsset` | `string assetTag` | `boolean` | Removes asset from store. |
| `getAllAssets` | None | `models:Asset[]` | Returns all registered assets. |
| `filterAssets` | `string? institution`, `string? site` | `models:Asset[]` | Returns assets matching optional filters. |
| `getOverdueAssets`| `string currentDate` | `models:Asset[]` | Identifies assets with `schedule.dueDate < currentDate`. |
| `addComponent` | `string assetTag`, `models:Component` | `error?` | Appends component sub-resource. |
| `removeComponent`| `string assetTag`, `string compId` | `error?` | Detaches component sub-resource. |
| `addSchedule` | `string assetTag`, `models:Schedule` | `error?` | Appends maintenance/booking schedule. |
| `removeSchedule`| `string assetTag`, `string scheduleId` | `error?` | Detaches maintenance/booking schedule. |
| `createWorkOrder`| `string assetTag`, `models:WorkOrder` | `error?` | Appends maintenance work order. |
| `updateWorkOrder`| `string assetTag`, `models:WorkOrder` | `error?` | Updates work order status and checklist tasks. |
| `resetStore` | None | `()` | Resets the in-memory table (useful for test setup). |

---

## 4. Concurrency Testing & Validation

Located in `modules/store/tests/store_test.bal`:
- `testStoreBasicCrud`: Full create, read, update, delete cycle.
- `testDuplicateAssetTagRejection`: Asserts uniqueness of `assetTag`.
- `testNonExistentAssetOperations`: Error handling on missing keys.
- `testFilterAssets`: Multi-dimensional filtering by institution and site.
- `testOverdueAssetsDetection`: Temporal date comparison for overdue schedules.
- `testComponentSubResourceOperations`: Sub-resource lifecycle.
- `testScheduleSubResourceOperations`: Schedule sub-resource lifecycle.
- `testWorkOrderSubResourceOperations`: Work order update and task completion.
- `testConcurrentStoreAccess`: Multi-threaded concurrent worker test validating lock safety without deadlocks or race conditions.
