import ballerina/http;
import ballerina/io;

import peerpressure/q1_library_service.models;

# HTTP client class for communicating with the Library & Resource Management System.
public client class LibraryClient {
    private final http:Client httpClient;

    # Initializes the LibraryClient with the target REST service base URL.
    # + serviceUrl - Base URL of the running REST service (e.g. "http://localhost:9090")
    # + return - error if initialization fails
    public isolated function init(string serviceUrl) returns error? {
        self.httpClient = check new (serviceUrl);
    }

    # Retrieves service health status.
    # + return - JSON health response or error
    public isolated function getHealth() returns json|error {
        return self.httpClient->/health;
    }

    # Retrieves the API catalog.
    # + return - JSON catalog response or error
    public isolated function getCatalog() returns json|error {
        return self.httpClient->get("/");
    }

    # Retrieves all assets with optional filtering.
    # + institution - Optional institution filter
    # + site - Optional campus site filter
    # + return - Array of assets or error
    public isolated function getAllAssets(string? institution = (), string? site = ()) returns models:Asset[]|error {
        if institution is string && site is string {
            return self.httpClient->/assets(institution = institution, site = site);
        } else if institution is string {
            return self.httpClient->/assets(institution = institution);
        } else if site is string {
            return self.httpClient->/assets(site = site);
        }
        return self.httpClient->/assets;
    }

    # Retrieves a single asset by unique asset tag.
    # + assetTag - Unique asset tag
    # + return - Asset record or error
    public isolated function getAsset(string assetTag) returns models:Asset|error {
        return self.httpClient->/assets/[assetTag];
    }

    # Creates a new asset.
    # + asset - Asset record to create
    # + return - Created asset or error
    public isolated function createAsset(models:Asset asset) returns models:Asset|error {
        return self.httpClient->/assets.post(asset);
    }

    # Updates an existing asset.
    # + assetTag - Unique asset tag
    # + asset - Updated asset payload
    # + return - Updated asset record or error
    public isolated function updateAsset(string assetTag, models:Asset asset) returns models:Asset|error {
        return self.httpClient->/assets/[assetTag].put(asset);
    }

    # Deletes an asset by unique asset tag.
    # + assetTag - Unique asset tag
    # + return - JSON confirmation response or error
    public isolated function deleteAsset(string assetTag) returns json|error {
        return self.httpClient->/assets/[assetTag].delete();
    }

    # Retrieves asset operational status summary.
    # + assetTag - Unique asset tag
    # + return - Status summary JSON or error
    public isolated function getAssetStatus(string assetTag) returns json|error {
        return self.httpClient->/assets/[assetTag]/status;
    }

    # Retrieves overdue maintenance assets.
    # + currentDate - Optional ISO comparison date
    # + return - Array of overdue assets or error
    public isolated function getOverdueAssets(string? currentDate = ()) returns models:Asset[]|error {
        if currentDate is string {
            return self.httpClient->/assets/overdue(currentDate = currentDate);
        }
        return self.httpClient->/assets/overdue;
    }

    # Attaches a component to an asset.
    # + assetTag - Unique asset tag
    # + component - Component payload
    # + return - Created component or error
    public isolated function addComponent(string assetTag, models:Component component) returns models:Component|error {
        return self.httpClient->/assets/[assetTag]/components.post(component);
    }

    # Removes a component from an asset.
    # + assetTag - Unique asset tag
    # + compId - Unique component identifier
    # + return - JSON confirmation response or error
    public isolated function removeComponent(string assetTag, string compId) returns json|error {
        return self.httpClient->/assets/[assetTag]/components/[compId].delete();
    }

    # Attaches a schedule to an asset.
    # + assetTag - Unique asset tag
    # + schedule - Schedule payload
    # + return - Created schedule or error
    public isolated function addSchedule(string assetTag, models:Schedule schedule) returns models:Schedule|error {
        return self.httpClient->/assets/[assetTag]/schedules.post(schedule);
    }

    # Removes a schedule from an asset.
    # + assetTag - Unique asset tag
    # + scheduleId - Unique schedule identifier
    # + return - JSON confirmation response or error
    public isolated function removeSchedule(string assetTag, string scheduleId) returns json|error {
        return self.httpClient->/assets/[assetTag]/schedules/[scheduleId].delete();
    }

    # Creates a work order for an asset.
    # + assetTag - Unique asset tag
    # + workOrder - Work order payload
    # + return - Created work order or error
    public isolated function createWorkOrder(string assetTag, models:WorkOrder workOrder) returns models:WorkOrder|error {
        return self.httpClient->post(string `/assets/${assetTag}/work-orders`, workOrder);
    }

    # Updates a work order on an asset.
    # + assetTag - Unique asset tag
    # + orderId - Work order identifier
    # + workOrder - Updated work order payload
    # + return - Updated work order or error
    public isolated function updateWorkOrder(string assetTag, string orderId, models:WorkOrder workOrder) returns models:WorkOrder|error {
        return self.httpClient->put(string `/assets/${assetTag}/work-orders/${orderId}`, workOrder);
    }
}

# Entry point for the interactive CLI client.
# + args - Command line arguments passed from caller
# + return - error if CLI execution fails
public function runCliClient(string[] args) returns error? {
    io:println("=================================================");
    io:println("  Library & Resource Management System CLI Client ");
    io:println("=================================================");

    string serviceUrl = args.length() > 0 ? args[0] : "http://localhost:9090";
    LibraryClient clientInstance = check new (serviceUrl);

    if args.length() > 1 {
        string command = args[1];
        match command {
            "health" => {
                json health = check clientInstance.getHealth();
                io:println("Health: ", health.toJsonString());
            }
            "list" => {
                models:Asset[] assets = check clientInstance.getAllAssets();
                io:println(string `Found ${assets.length()} asset(s):`);
                foreach models:Asset a in assets {
                    io:println(string `- [${a.assetTag}] ${a.name} (${a.status}) at ${a.institution} - ${a.site}`);
                }
            }
            "get" => {
                if args.length() > 2 {
                    string tag = args[2];
                    models:Asset asset = check clientInstance.getAsset(tag);
                    io:println(string `Asset [${asset.assetTag}]: ${asset.name} - Status: ${asset.status}`);
                } else {
                    io:println("Usage: get <assetTag>");
                }
            }
            "overdue" => {
                models:Asset[] overdue = check clientInstance.getOverdueAssets();
                io:println(string `Found ${overdue.length()} overdue asset(s):`);
                foreach models:Asset a in overdue {
                    io:println(string `- [${a.assetTag}] ${a.name}`);
                }
            }
            _ => {
                io:println(string `Unknown command: ${command}`);
                io:println("Available commands: health, list, get <assetTag>, overdue");
            }
        }
    } else {
        io:println("Connected to service at: ", serviceUrl);
        io:println("Run with arguments: <serviceUrl> <command> [args...]");
        io:println("Commands: health, list, get <assetTag>, overdue");
    }
}
