// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import peerpressure/q1_library_service.models;

# Common API and REST communication types for the Library & Resource Management System.

# Health check response envelope.
public type HealthResponse record {|
    # Service operational status (e.g. UP)
    string status;
    # Server epoch timestamp in milliseconds
    int timestamp;
    # Service package identifier
    string 'service;
|};

# API root discovery catalog response envelope.
public type ApiCatalogResponse record {|
    # Official name of the REST service
    string 'service;
    # Semantic version string
    string version;
    # List of public endpoints supported by this service
    string[] endpoints;
|};

# Standard error response envelope following RFC 7807 principles.
public type ErrorResponse record {|
    # ISO 8601 timestamp of the error occurrence
    string timestamp;
    # HTTP status code
    int status;
    # Standard HTTP status reason phrase
    string reason;
    # Human-readable diagnostic error message
    string message;
    # Target resource path requested
    string path;
    # Optional field-level validation errors
    map<string> details?;
|};

# Request payload for creating a new asset.
public type CreateAssetPayload record {|
    # Unique identification tag for the asset (Primary Key)
    string assetTag;
    # Title or name of the asset
    string name;
    # Detailed description of the asset
    string description;
    # Ministry institution
    string institution;
    # Physical site or campus
    string site;
    # Initial lifecycle status
    models:AssetStatus status;
    # Acquisition date (YYYY-MM-DD)
    string dateAcquired;
    # Initial attached components
    models:Component[] components = [];
    # Initial schedules
    models:Schedule[] schedules = [];
    # Initial work orders
    models:WorkOrder[] workOrders = [];
|};

# Request payload for updating an existing asset.
public type UpdateAssetPayload record {|
    # Updated asset name
    string name?;
    # Updated description
    string description?;
    # Updated institution
    string institution?;
    # Updated physical site
    string site?;
    # Updated operational status
    models:AssetStatus status?;
    # Updated acquisition date (YYYY-MM-DD)
    string dateAcquired?;
|};

# Response record for overdue maintenance schedules.
public type OverdueSchedule record {|
    # Primary tag of the asset
    string assetTag;
    # Name of the asset
    string assetName;
    # Institution owning the asset
    string institution;
    # Campus or physical site
    string site;
    # Unique schedule identifier
    string scheduleId;
    # Due date that is past due (YYYY-MM-DD)
    string dueDate;
    # Type of schedule
    string scheduleType;
    # Operational details
    string details;
|};

# Response record for asset operational status and active bookings.
public type AssetStatusSummary record {|
    # Unique asset tag identifier
    string assetTag;
    # Asset title
    string name;
    # Current status
    models:AssetStatus status;
    # Active or upcoming schedules
    models:Schedule[] schedules;
    # Unresolved work orders
    models:WorkOrder[] activeWorkOrders;
|};
