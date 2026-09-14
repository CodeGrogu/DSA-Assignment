import ballerina/regex;

# Allowed lifecycle states for library and equipment assets.
public type AssetStatus "AVAILABLE"|"LOANED_OUT"|"OCCUPIED"|"UNDER_MAINTENANCE"|"DISPOSED";

# Status lifecycle for maintenance work orders.
public type WorkOrderStatus "OPEN"|"IN_PROGRESS"|"CLOSED";

# Modular component sub-resource attached to a parent asset.
# + compId - Unique identifier of the component
# + name - Descriptive name of the component
# + description - Details and specifications of the component
public type Component record {|
    string compId;
    string name;
    string description;
|};

# Scheduled booking or maintenance date sub-resource for an asset.
# + scheduleId - Unique identifier of the schedule
# + dueDate - Scheduled due date in ISO YYYY-MM-DD format
# + scheduleType - Type classification (e.g. MAINTENANCE, INSPECTION, BOOKING)
# + details - Scope or details of the schedule
public type Schedule record {|
    string scheduleId;
    string dueDate;
    string scheduleType;
    string details;
|};

# Individual maintenance task within a work order.
# + taskId - Unique task identifier
# + description - Actionable task description
# + completed - Completion flag for this task
public type Task record {|
    string taskId;
    string description;
    boolean completed = false;
|};

# Maintenance work order issued against an asset or attached component.
# + orderId - Unique work order identifier
# + status - Current status lifecycle of the order
# + description - Work order description and objectives
# + compId - Optional component identifier if targeting a sub-component
# + tasks - Checklist of actionable tasks belonging to this order
public type WorkOrder record {|
    string orderId;
    WorkOrderStatus status;
    string description;
    string compId?;
    Task[] tasks = [];
|};

# Core asset entity record representing tracked books, media, equipment, or spaces.
# Uses camelCase 'assetTag' as the unique primary identifier.
# + assetTag - Unique primary identifier for the asset
# + name - Display name of the asset
# + description - Detailed description
# + institution - Owning ministry or university institution
# + site - Campus site or building location
# + status - Operational lifecycle status
# + dateAcquired - Acquisition date in ISO format
# + components - Modular attached component records
# + schedules - Scheduled dates and maintenance bookings
# + workOrders - Maintenance work orders issued for this asset
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

# Organization or ministry institution record.
# + id - Unique institution identifier
# + name - Display name of the institution
public type Institution record {|
    readonly string id;
    string name;
|};

# Validates whether a given status string matches an allowed AssetStatus.
# + statusStr - Status string to validate
# + return - True if valid, false otherwise
public isolated function isValidAssetStatus(string statusStr) returns boolean {
    return statusStr == "AVAILABLE" ||
        statusStr == "LOANED_OUT" ||
        statusStr == "OCCUPIED" ||
        statusStr == "UNDER_MAINTENANCE" ||
        statusStr == "DISPOSED";
}

# Validates whether a given status string matches an allowed WorkOrderStatus.
# + statusStr - Status string to validate
# + return - True if valid, false otherwise
public isolated function isValidWorkOrderStatus(string statusStr) returns boolean {
    return statusStr == "OPEN" || statusStr == "IN_PROGRESS" || statusStr == "CLOSED";
}

# Validates whether a date string conforms to standard ISO YYYY-MM-DD format.
# + dateStr - Date string to inspect
# + return - True if valid ISO format, false otherwise
public isolated function isValidIsoDate(string dateStr) returns boolean {
    return regex:matches(dateStr, "^\\d{4}-\\d{2}-\\d{2}$");
}
