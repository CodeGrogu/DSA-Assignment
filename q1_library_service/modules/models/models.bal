// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/regex;

# Defines the canonical data models, status types, and record contracts
# for the Library & Resource Management System (Q1).

# Represents the status of an asset in the library system.
# Restricted to the canonical lifecycle states defined in the specification:
# - AVAILABLE: Resource is on-site and ready to be borrowed or occupied
# - LOANED_OUT: Resource is currently issued to a borrower
# - OCCUPIED: Physical space or room is currently in use
# - UNDER_MAINTENANCE: Resource is undergoing repairs, calibration, or servicing
# - DISPOSED: Resource has reached end-of-life and is de-commissioned
public type AssetStatus "AVAILABLE"|"LOANED_OUT"|"OCCUPIED"|"UNDER_MAINTENANCE"|"DISPOSED";

# Represents the lifecycle status of a maintenance work order.
public type WorkOrderStatus "OPEN"|"IN_PROGRESS"|"CLOSED";

# Represents a component sub-part attached to a composite physical asset.
public type Component record {|
    # Unique identifier of the component (e.g. COMP-01)
    string compId;
    # Display name of the component
    string name;
    # Detailed description of the component
    string description;
|};

# Represents a servicing, maintenance, or booking schedule for an asset.
public type Schedule record {|
    # Unique identifier for the schedule entry (e.g. SCH-01)
    string scheduleId;
    # Target or due date for the scheduled action in ISO 8601 format (YYYY-MM-DD)
    string dueDate;
    # Type of schedule (e.g., MAINTENANCE, SERVICING, INSPECTION, BOOKING, CALIBRATION)
    string scheduleType;
    # Additional operational details or requirements
    string details;
|};

# Represents an individual task sub-item within a maintenance work order.
public type Task record {|
    # Unique identifier for the task (e.g. TSK-01)
    string taskId;
    # Description of work to be performed
    string description;
    # Flag indicating whether the task has been completed
    boolean completed = false;
|};

# Represents a formal work order raised against an asset or component.
public type WorkOrder record {|
    # Unique identifier for the work order (e.g. WO-101)
    string orderId;
    # Current workflow status of the work order
    WorkOrderStatus status;
    # Description of the fault or maintenance scope
    string description;
    # Associated component identifier, if raised against a specific sub-part
    string compId?;
    # List of individual sub-tasks required to resolve the work order
    Task[] tasks = [];
|};

# Canonical Asset record representing physical, electronic, and spatial resources.
# All entity lookups across the system use `assetTag` as the primary key.
public type Asset record {|
    # Unique identification tag for the asset (Primary Key, camelCase)
    readonly string assetTag;
    # Human-readable title or name of the asset
    string name;
    # Detailed description of the asset
    string description;
    # Ministry institution to which the asset belongs
    string institution;
    # Physical site or campus location where the asset is situated
    string site;
    # Current operational lifecycle status
    AssetStatus status;
    # Date on which the asset was acquired in ISO 8601 format (YYYY-MM-DD)
    string dateAcquired;
    # Nested list of constituent hardware or equipment components
    Component[] components = [];
    # Scheduled servicing, calibration, or booking windows
    Schedule[] schedules = [];
    # Active and historical maintenance work orders
    WorkOrder[] workOrders = [];
|};

# Validates if a string is a valid canonical AssetStatus.
#
# + statusStr - The string value to evaluate
# + return - True if the status is one of the 5 canonical values, false otherwise
public isolated function isValidAssetStatus(string statusStr) returns boolean {
    return statusStr == "AVAILABLE" ||
        statusStr == "LOANED_OUT" ||
        statusStr == "OCCUPIED" ||
        statusStr == "UNDER_MAINTENANCE" ||
        statusStr == "DISPOSED";
}

# Validates if a string is a valid WorkOrderStatus.
#
# + statusStr - The string value to evaluate
# + return - True if the status is OPEN, IN_PROGRESS, or CLOSED
public isolated function isValidWorkOrderStatus(string statusStr) returns boolean {
    return statusStr == "OPEN" || statusStr == "IN_PROGRESS" || statusStr == "CLOSED";
}

# Validates if a date string strictly follows the ISO 8601 YYYY-MM-DD format.
#
# + dateStr - Date string to check
# + return - True if valid format, false otherwise
public isolated function isValidIsoDate(string dateStr) returns boolean {
    return regex:matches(dateStr, "^\\d{4}-\\d{2}-\\d{2}$");
}
