import peerpressure/q1_library_service.models;

public type HealthResponse record {|
    string status;
    int timestamp;
    string 'service;
|};

public type ApiCatalogResponse record {|
    string 'service;
    string version;
    string[] endpoints;
|};

public type ErrorResponse record {|
    string timestamp;
    int status;
    string reason;
    string message;
    string path;
    map<string> details?;
|};

public type CreateAssetPayload record {|
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    models:AssetStatus status;
    string dateAcquired;
    models:Component[] components = [];
    models:Schedule[] schedules = [];
    models:WorkOrder[] workOrders = [];
|};

public type UpdateAssetPayload record {|
    string name?;
    string description?;
    string institution?;
    string site?;
    models:AssetStatus status?;
    string dateAcquired?;
|};

public type OverdueSchedule record {|
    string assetTag;
    string assetName;
    string institution;
    string site;
    string scheduleId;
    string dueDate;
    string scheduleType;
    string details;
|};

public type AssetStatusSummary record {|
    string assetTag;
    string name;
    models:AssetStatus status;
    models:Schedule[] schedules;
    models:WorkOrder[] activeWorkOrders;
|};
