// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

# Defines the canonical data models, status types, and record contracts
# for the Library & Resource Management System (Q1).

# Represents the status of an asset in the library system.
# Restricted to the five canonical lifecycle states defined in the specification.
public type AssetStatus "AVAILABLE"|"LOANED_OUT"|"OCCUPIED"|"UNDER_MAINTENANCE"|"DISPOSED";

# Represents a component sub-part attached to a composite physical asset.
public type Component record {|
    # Unique identifier of the component
    string compId;
    # Display name of the component
    string name;
    # Detailed description of the component
    string description;
|};

# Represents a servicing, maintenance, or booking schedule for an asset.
public type Schedule record {|
    # Unique identifier for the schedule entry
    string scheduleId;
    # Target or due date for the scheduled action (YYYY-MM-DD)
    string dueDate;
    # Type of schedule (e.g., MAINTENANCE, SERVICING, INSPECTION, BOOKING)
    string scheduleType;
    # Additional operational details or requirements
    string details;
|};

# Represents a task sub-item within a maintenance work order.
public type Task record {|
    # Unique identifier for the task
    string taskId;
    # Description of work to be performed
    string description;
    # Flag indicating whether the task has been completed
    boolean completed = false;
|};

# Represents a formal work order raised against an asset or component.
public type WorkOrder record {|
    # Unique identifier for the work order
    string orderId;
    # Current workflow status of the work order
    "OPEN"|"IN_PROGRESS"|"CLOSED" status;
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
    # Unique identification tag for the asset (Primary Key)
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
    # Date on which the asset was acquired (YYYY-MM-DD)
    string dateAcquired;
    # Nested list of constituent hardware or equipment components
    Component[] components = [];
    # Scheduled servicing, calibration, or booking windows
    Schedule[] schedules = [];
    # Active and historical maintenance work orders
    WorkOrder[] workOrders = [];
|};
