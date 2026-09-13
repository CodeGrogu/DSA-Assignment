import ballerina/http;
import ballerina/io;

# Target REST service endpoint base URL for the Library & Resource Management System.
# Configurable via Config.toml or BAL_CONFIG_VAR_SERVICEURL.
configurable string serviceUrl = "http://localhost:9090";

# HTTP request timeout in seconds for REST client invocations.
# Configurable via Config.toml or BAL_CONFIG_VAR_CLIENTTIMEOUT.
configurable decimal clientTimeout = 10.0;

# Reusable HTTP client class for communicating with the Library & Resource Management System.
public client class LibraryClient {
    private final http:Client httpClient;

    # Initializes the LibraryClient with the target REST service base URL.
    # + targetUrl - Base URL of the running REST service (e.g. "http://localhost:9090")
    # + timeout - Client timeout in seconds
    # + return - error if initialization fails
    public isolated function init(string targetUrl = serviceUrl, decimal timeout = clientTimeout) returns error? {
        self.httpClient = check new (targetUrl, timeout = timeout);
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

    # Retrieves all assets with optional filtering by institution and site.
    # + institution - Optional institution filter
    # + site - Optional campus site filter
    # + return - Array of assets or error
    public isolated function getAllAssets(string? institution = (), string? site = ()) returns Asset[]|error {
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
    public isolated function getAsset(string assetTag) returns Asset|error {
        return self.httpClient->/assets/[assetTag];
    }

    # Registers a new asset record.
    # + asset - Asset record to create
    # + return - Created asset or error
    public isolated function createAsset(Asset asset) returns Asset|error {
        return self.httpClient->/assets.post(asset);
    }

    # Updates an existing asset record.
    # + assetTag - Unique asset tag
    # + asset - Updated asset payload
    # + return - Updated asset record or error
    public isolated function updateAsset(string assetTag, Asset asset) returns Asset|error {
        return self.httpClient->/assets/[assetTag].put(asset);
    }

    # Deletes an asset by unique asset tag.
    # + assetTag - Unique asset tag
    # + return - JSON confirmation response or error
    public isolated function deleteAsset(string assetTag) returns json|error {
        return self.httpClient->/assets/[assetTag].delete();
    }

    # Retrieves asset operational status summary and active work orders.
    # + assetTag - Unique asset tag
    # + return - Status summary JSON or error
    public isolated function getAssetStatus(string assetTag) returns json|error {
        return self.httpClient->/assets/[assetTag]/status;
    }

    # Retrieves assets with overdue maintenance schedules.
    # + currentDate - Optional ISO comparison date
    # + return - Array of overdue assets or error
    public isolated function getOverdueAssets(string? currentDate = ()) returns Asset[]|error {
        if currentDate is string {
            return self.httpClient->/assets/overdue(currentDate = currentDate);
        }
        return self.httpClient->/assets/overdue;
    }

    # Attaches a component sub-resource to an asset.
    # + assetTag - Unique asset tag
    # + component - Component payload
    # + return - Created component or error
    public isolated function addComponent(string assetTag, Component component) returns Component|error {
        return self.httpClient->/assets/[assetTag]/components.post(component);
    }

    # Removes a component sub-resource from an asset.
    # + assetTag - Unique asset tag
    # + compId - Unique component identifier
    # + return - JSON confirmation response or error
    public isolated function removeComponent(string assetTag, string compId) returns json|error {
        return self.httpClient->/assets/[assetTag]/components/[compId].delete();
    }

    # Attaches a maintenance/booking schedule to an asset.
    # + assetTag - Unique asset tag
    # + schedule - Schedule payload
    # + return - Created schedule or error
    public isolated function addSchedule(string assetTag, Schedule schedule) returns Schedule|error {
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
    public isolated function createWorkOrder(string assetTag, WorkOrder workOrder) returns WorkOrder|error {
        return self.httpClient->post(string `/assets/${assetTag}/work-orders`, workOrder);
    }

    # Updates a work order on an asset.
    # + assetTag - Unique asset tag
    # + orderId - Work order identifier
    # + workOrder - Updated work order payload
    # + return - Updated work order or error
    public isolated function updateWorkOrder(string assetTag, string orderId, WorkOrder workOrder) returns WorkOrder|error {
        return self.httpClient->put(string `/assets/${assetTag}/work-orders/${orderId}`, workOrder);
    }
}

# Entry point for the CLI client application.
# Supports both direct CLI argument execution and interactive console menu mode.
#
# + args - Optional command-line arguments (e.g., 'list', 'get TAG-001', 'health', 'overdue')
# + return - Returns error if command execution fails
public function main(string... args) returns error? {
    LibraryClient clientInstance = check new (serviceUrl, clientTimeout);

    if args.length() > 0 {
        return executeCliCommand(clientInstance, args);
    }

    return runInteractiveMenu(clientInstance);
}

# Executes direct CLI commands passed via command line arguments.
# + clientInstance - Active LibraryClient instance
# + args - CLI arguments array
# + return - error if invocation fails
function executeCliCommand(LibraryClient clientInstance, string[] args) returns error? {
    string command = args[0];

    // Check if first arg is an override URL (e.g. "http://localhost:9090" list)
    if (command.startsWith("http://") || command.startsWith("https://")) && args.length() > 1 {
        LibraryClient overriddenClient = check new (command, clientTimeout);
        string[] shiftedArgs = args.slice(1);
        return executeCliCommand(overriddenClient, shiftedArgs);
    }

    match command {
        "health" => {
            json health = check clientInstance.getHealth();
            io:println("Service Health: ", health.toJsonString());
        }
        "list" => {
            string? institution = args.length() > 1 ? args[1] : ();
            string? site = args.length() > 2 ? args[2] : ();
            Asset[] assets = check clientInstance.getAllAssets(institution, site);
            io:println(string `Found ${assets.length()} asset(s):`);
            foreach Asset a in assets {
                io:println(string `  - [${a.assetTag}] ${a.name} (${a.status}) | ${a.institution} - ${a.site}`);
            }
        }
        "get" => {
            if args.length() > 1 {
                string tag = args[1];
                Asset|error asset = clientInstance.getAsset(tag);
                if asset is Asset {
                    io:println(string `Asset Tag:    ${asset.assetTag}`);
                    io:println(string `Name:         ${asset.name}`);
                    io:println(string `Description:  ${asset.description}`);
                    io:println(string `Institution:  ${asset.institution}`);
                    io:println(string `Site:         ${asset.site}`);
                    io:println(string `Status:       ${asset.status}`);
                    io:println(string `Acquired:     ${asset.dateAcquired}`);
                    io:println(string `Components:   ${asset.components.length()}`);
                    io:println(string `Schedules:    ${asset.schedules.length()}`);
                    io:println(string `Work Orders:  ${asset.workOrders.length()}`);
                } else {
                    io:println(string `Asset with assetTag '${tag}' not found or error occurred: ${asset.message()}`);
                }
            } else {
                io:println("Usage: bal run -- get <assetTag>");
            }
        }
        "overdue" => {
            string? dateParam = args.length() > 1 ? args[1] : ();
            Asset[] overdue = check clientInstance.getOverdueAssets(dateParam);
            io:println(string `Found ${overdue.length()} overdue asset(s):`);
            foreach Asset a in overdue {
                io:println(string `  - [${a.assetTag}] ${a.name} (${a.status})`);
            }
        }
        "status" => {
            if args.length() > 1 {
                string tag = args[1];
                json statusJson = check clientInstance.getAssetStatus(tag);
                io:println("Asset Status: ", statusJson.toJsonString());
            } else {
                io:println("Usage: bal run -- status <assetTag>");
            }
        }
        "delete" => {
            if args.length() > 1 {
                string tag = args[1];
                json resp = check clientInstance.deleteAsset(tag);
                io:println("Delete Response: ", resp.toJsonString());
            } else {
                io:println("Usage: bal run -- delete <assetTag>");
            }
        }
        "help" => {
            printUsage();
        }
        _ => {
            io:println(string `Unknown command: '${command}'`);
            printUsage();
        }
    }
}

# Runs the interactive terminal console menu.
# + clientInstance - Active LibraryClient instance
# + return - error if menu operation fails
function runInteractiveMenu(LibraryClient clientInstance) returns error? {
    io:println("=================================================");
    io:println("  Library & Resource Management System Client    ");
    io:println(string `  Connected to: ${serviceUrl}                     `);
    io:println("=================================================");

    boolean running = true;
    int emptyInputCount = 0;

    while running {
        io:println("\n--- MAIN MENU ---");
        io:println("1. Check Service Health");
        io:println("2. List All Assets");
        io:println("3. Get Asset by assetTag");
        io:println("4. Register New Asset");
        io:println("5. Update Asset Status / Metadata");
        io:println("6. Delete Asset");
        io:println("7. View Asset Status & Work Orders");
        io:println("8. View Overdue Maintenance Assets");
        io:println("9. Attach Component to Asset");
        io:println("10. Attach Schedule to Asset");
        io:println("0. Exit");

        string input = io:readln("Select an option (0-10): ");
        string choice = input.trim();

        // Guard against infinite loop on EOF or piped stdin
        if choice.length() == 0 {
            emptyInputCount += 1;
            if emptyInputCount >= 3 {
                io:println("Multiple empty inputs or EOF detected. Exiting client.");
                break;
            }
            io:println("No selection entered. Please choose an option (0-10).");
            continue;
        }
        emptyInputCount = 0;

        match choice {
            "1" => {
                json|error health = clientInstance.getHealth();
                if health is json {
                    io:println("Health: ", health.toJsonString());
                } else {
                    io:println("Error checking health: ", health.message());
                }
            }
            "2" => {
                string instFilter = io:readln("Filter by Institution (leave blank for all): ").trim();
                string siteFilter = io:readln("Filter by Site (leave blank for all): ").trim();
                string? inst = instFilter.length() > 0 ? instFilter : ();
                string? st = siteFilter.length() > 0 ? siteFilter : ();

                Asset[]|error assets = clientInstance.getAllAssets(inst, st);
                if assets is Asset[] {
                    if assets.length() == 0 {
                        io:println("No assets found matching the criteria.");
                    } else {
                        io:println(string `Found ${assets.length()} asset(s):`);
                        foreach Asset a in assets {
                            io:println(string `  - [${a.assetTag}] ${a.name} (${a.status}) at ${a.institution} - ${a.site}`);
                        }
                    }
                } else {
                    io:println("Error retrieving assets: ", assets.message());
                }
            }
            "3" => {
                string tag = io:readln("Enter unique assetTag: ").trim();
                if tag.length() == 0 {
                    io:println("assetTag cannot be empty.");
                    continue;
                }
                Asset|error asset = clientInstance.getAsset(tag);
                if asset is Asset {
                    io:println(string `Tag:         ${asset.assetTag}`);
                    io:println(string `Name:        ${asset.name}`);
                    io:println(string `Description: ${asset.description}`);
                    io:println(string `Institution: ${asset.institution}`);
                    io:println(string `Site:        ${asset.site}`);
                    io:println(string `Status:      ${asset.status}`);
                    io:println(string `Acquired:    ${asset.dateAcquired}`);
                } else {
                    io:println("Error fetching asset: ", asset.message());
                }
            }
            "4" => {
                string tag = io:readln("Asset Tag (e.g. AST-101): ").trim();
                string name = io:readln("Asset Name: ").trim();
                string desc = io:readln("Description: ").trim();
                string inst = io:readln("Institution (e.g. NUST): ").trim();
                string site = io:readln("Site (e.g. Main Campus): ").trim();
                string statusInput = io:readln("Status (AVAILABLE, LOANED_OUT, OCCUPIED, UNDER_MAINTENANCE, DISPOSED): ").trim().toUpperAscii();
                string acquired = io:readln("Date Acquired (YYYY-MM-DD): ").trim();

                AssetStatus status = isValidAssetStatus(statusInput) ? <AssetStatus>statusInput : "AVAILABLE";
                Asset newAsset = {
                    assetTag: tag,
                    name: name,
                    description: desc,
                    institution: inst,
                    site: site,
                    status: status,
                    dateAcquired: acquired
                };

                Asset|error result = clientInstance.createAsset(newAsset);
                if result is Asset {
                    io:println(string `Successfully registered asset [${result.assetTag}]: ${result.name}`);
                } else {
                    io:println("Failed to create asset: ", result.message());
                }
            }
            "5" => {
                string tag = io:readln("Enter assetTag to update: ").trim();
                Asset|error existing = clientInstance.getAsset(tag);
                if existing is Asset {
                    string newName = io:readln(string `Name [${existing.name}]: `).trim();
                    string newDesc = io:readln(string `Description [${existing.description}]: `).trim();
                    string newStatus = io:readln(string `Status [${existing.status}]: `).trim().toUpperAscii();

                    Asset updated = {
                        assetTag: existing.assetTag,
                        name: newName.length() > 0 ? newName : existing.name,
                        description: newDesc.length() > 0 ? newDesc : existing.description,
                        institution: existing.institution,
                        site: existing.site,
                        status: isValidAssetStatus(newStatus) ? <AssetStatus>newStatus : existing.status,
                        dateAcquired: existing.dateAcquired,
                        components: existing.components,
                        schedules: existing.schedules,
                        workOrders: existing.workOrders
                    };

                    Asset|error res = clientInstance.updateAsset(tag, updated);
                    if res is Asset {
                        io:println(string `Successfully updated asset [${res.assetTag}]`);
                    } else {
                        io:println("Update failed: ", res.message());
                    }
                } else {
                    io:println("Asset not found: ", existing.message());
                }
            }
            "6" => {
                string tag = io:readln("Enter assetTag to delete: ").trim();
                json|error resp = clientInstance.deleteAsset(tag);
                if resp is json {
                    io:println("Asset deleted: ", resp.toJsonString());
                } else {
                    io:println("Delete failed: ", resp.message());
                }
            }
            "7" => {
                string tag = io:readln("Enter assetTag: ").trim();
                json|error st = clientInstance.getAssetStatus(tag);
                if st is json {
                    io:println("Operational Status: ", st.toJsonString());
                } else {
                    io:println("Error getting status: ", st.message());
                }
            }
            "8" => {
                string cmpDate = io:readln("Comparison date YYYY-MM-DD (blank for today): ").trim();
                string? d = cmpDate.length() > 0 ? cmpDate : ();
                Asset[]|error overdue = clientInstance.getOverdueAssets(d);
                if overdue is Asset[] {
                    io:println(string `Overdue maintenance assets: ${overdue.length()}`);
                    foreach Asset a in overdue {
                        io:println(string `  - [${a.assetTag}] ${a.name}`);
                    }
                } else {
                    io:println("Error fetching overdue assets: ", overdue.message());
                }
            }
            "9" => {
                string tag = io:readln("Enter assetTag: ").trim();
                string compId = io:readln("Component ID (e.g. CMP-01): ").trim();
                string name = io:readln("Component Name: ").trim();
                string desc = io:readln("Component Description: ").trim();

                Component comp = {compId: compId, name: name, description: desc};
                Component|error res = clientInstance.addComponent(tag, comp);
                if res is Component {
                    io:println(string `Attached component [${res.compId}] to asset [${tag}]`);
                } else {
                    io:println("Failed to attach component: ", res.message());
                }
            }
            "10" => {
                string tag = io:readln("Enter assetTag: ").trim();
                string schId = io:readln("Schedule ID (e.g. SCH-01): ").trim();
                string dueDate = io:readln("Due Date (YYYY-MM-DD): ").trim();
                string schType = io:readln("Schedule Type (MAINTENANCE, INSPECTION, BOOKING): ").trim();
                string details = io:readln("Details: ").trim();

                Schedule sch = {scheduleId: schId, dueDate: dueDate, scheduleType: schType, details: details};
                Schedule|error res = clientInstance.addSchedule(tag, sch);
                if res is Schedule {
                    io:println(string `Attached schedule [${res.scheduleId}] to asset [${tag}]`);
                } else {
                    io:println("Failed to attach schedule: ", res.message());
                }
            }
            "0" => {
                io:println("Exiting Library Client. Goodbye!");
                running = false;
            }
            _ => {
                io:println("Invalid option. Please choose between 0 and 10.");
            }
        }
    }
}

# Prints usage instructions for direct CLI arguments.
function printUsage() {
    io:println("Usage:");
    io:println("  bal run                          # Run interactive menu");
    io:println("  bal run -- health                # Check service health");
    io:println("  bal run -- list [inst] [site]    # List assets with optional filtering");
    io:println("  bal run -- get <assetTag>        # Inspect asset by tag");
    io:println("  bal run -- overdue [date]        # View overdue maintenance assets");
    io:println("  bal run -- status <assetTag>     # View asset operational status");
    io:println("  bal run -- delete <assetTag>     # Delete an asset");
    io:println("  bal run -- help                  # Show this help message");
}
