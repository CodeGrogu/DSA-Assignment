import peerpressure/q1_library_service.models;

# Represents the health status response for the service.
public type HealthResponse record {|
    # Service health status flag (e.g. "UP")
    string status;
    # Epoch timestamp in milliseconds
    int timestamp;
    # Name of the service
    string 'service;
|};

# Represents the service discovery catalog response.
public type ApiCatalogResponse record {|
    # Service title
    string 'service;
    # Semantic version string
    string version;
    # Array of available resource endpoint paths
    string[] endpoints;
|};

# Represents a structured error response payload.
public type ErrorResponse record {|
    # ISO timestamp when the error occurred
    string timestamp;
    # HTTP status code
    int status;
    # Short HTTP reason phrase
    string reason;
    # Human-readable error description
    string message;
    # URI path of the failing request
    string path;
    # Optional detailed diagnostics
    map<string> details?;
|};

# Payload record for creating a new asset.
public type CreateAssetPayload record {|
    # Unique asset tag identifier
    string assetTag;
    # Asset name or title
    string name;
    # Detailed description
    string description;
    # Owning educational institution
    string institution;
    # Campus or facility site location
    string site;
    # Operational asset status
    models:AssetStatus status;
    # Date of acquisition in ISO-8601 format (YYYY-MM-DD)
    string dateAcquired;
    # Attached component sub-parts
    models:Component[] components = [];
    # Maintenance and booking schedules
    models:Schedule[] schedules = [];
    # Active or historical work orders
    models:WorkOrder[] workOrders = [];
|};

# Payload record for updating existing asset metadata.
public type UpdateAssetPayload record {|
    # Updated asset name
    string name?;
    # Updated description
    string description?;
    # Updated institution
    string institution?;
    # Updated site
    string site?;
    # Updated status
    models:AssetStatus status?;
    # Updated acquisition date
    string dateAcquired?;
|};

# Summary record representing an overdue maintenance or booking schedule.
public type OverdueSchedule record {|
    # Associated asset tag
    string assetTag;
    # Name of the asset
    string assetName;
    # Owning institution
    string institution;
    # Campus site
    string site;
    # Schedule identifier
    string scheduleId;
    # Due date (ISO format)
    string dueDate;
    # Type of schedule
    string scheduleType;
    # Schedule details
    string details;
|};

# Operational status and active work orders summary for an asset.
public type AssetStatusSummary record {|
    # Unique asset tag identifier
    string assetTag;
    # Asset title
    string name;
    # Current status
    models:AssetStatus status;
    # All registered schedules
    models:Schedule[] schedules;
    # Currently open or in-progress work orders
    models:WorkOrder[] activeWorkOrders;
|};

# Generic message response for successful mutations and deletions.
public type MessageResponse record {|
    # Confirmation message
    string message;
    # Associated asset tag if applicable
    string? assetTag = ();
|};
