# PEE-9: Canonical Asset Data Models & Validation Contracts

## 1. Overview & Objectives
**Linear Issue**: PEE-9  
**Parent Epic**: [PEE-7] Question 1 – Library & Resource Management System  
**Module**: `peerpressure/q1_library_service.models`  

PEE-9 establishes the canonical domain models, nested sub-resource records, union types, and integrity validators used throughout the REST API and storage layer.

---

## 2. Core Type Definitions

### 2.1 Asset Entity Record (`models:Asset`)
The central record representing an educational or institutional asset:

```ballerina
public type Asset record {|
    readonly string assetTag;
    string name;
    string description;
    string institution;
    string site;
    AssetStatus status;
    string dateAcquired;
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};
```

### 2.2 Status Union Types
- **AssetStatus**: `"AVAILABLE" | "LOANED_OUT" | "OCCUPIED" | "UNDER_MAINTENANCE" | "DISPOSED"`
- **WorkOrderStatus**: `"OPEN" | "IN_PROGRESS" | "CLOSED"`

### 2.3 Nested Sub-Resources
- **Component**: Modular hardware or equipment attachments (`compId`, `name`, `description`).
- **Schedule**: Time-bound maintenance or booking events (`scheduleId`, `dueDate`, `scheduleType`, `details`).
- **WorkOrder & Task**: Actionable maintenance checklists (`orderId`, `status`, `description`, `compId?`, `tasks: Task[]`).

---

## 3. Data Integrity & Validation Rules

1. **Asset Identification**: Primary entity identifier is strictly `assetTag` in camelCase.
2. **Date Format Compliance**: `dateAcquired` and `dueDate` must follow ISO-8601 (`YYYY-MM-DD`). Checked via `isValidIsoDate()`.
3. **Status Guardrails**: `isValidAssetStatus()` and `isValidWorkOrderStatus()` ensure runtime payload data matches domain union types before persistence.

---

## 4. Test Coverage & Verification

Located in `modules/models/tests/models_test.bal`:
- `testAssetRecordCreation`: Record construction and default collection fields.
- `testIsoDateValidator`: Regex pattern matching for standard dates.
- `testStatusValidators`: Status union guard functions.
- `testWorkOrderStatusValidators`: Work order state transition checks.
- `testJsonDeserializationAndRoundTrip`: JSON to typed record casting.
- `testSubRecordDefaults`: Empty array initializations for components, schedules, and work orders.
