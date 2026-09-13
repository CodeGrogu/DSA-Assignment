import ballerina/regex;

public type AssetStatus "AVAILABLE"|"LOANED_OUT"|"OCCUPIED"|"UNDER_MAINTENANCE"|"DISPOSED";

public type WorkOrderStatus "OPEN"|"IN_PROGRESS"|"CLOSED";

public type Component record {|
    string compId;
    string name;
    string description;
|};

public type Schedule record {|
    string scheduleId;
    string dueDate;
    string scheduleType;
    string details;
|};

public type Task record {|
    string taskId;
    string description;
    boolean completed = false;
|};

public type WorkOrder record {|
    string orderId;
    WorkOrderStatus status;
    string description;
    string compId?;
    Task[] tasks = [];
|};

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

public type Institution record {|
    readonly string id;
    string name;
|};

public isolated function isValidAssetStatus(string statusStr) returns boolean {
    return statusStr == "AVAILABLE" ||
        statusStr == "LOANED_OUT" ||
        statusStr == "OCCUPIED" ||
        statusStr == "UNDER_MAINTENANCE" ||
        statusStr == "DISPOSED";
}

public isolated function isValidWorkOrderStatus(string statusStr) returns boolean {
    return statusStr == "OPEN" || statusStr == "IN_PROGRESS" || statusStr == "CLOSED";
}

public isolated function isValidIsoDate(string dateStr) returns boolean {
    return regex:matches(dateStr, "^\\d{4}-\\d{2}-\\d{2}$");
}
