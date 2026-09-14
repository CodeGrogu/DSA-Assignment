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

    # Adds a sub-task to an existing work order.
    # + assetTag - Unique asset tag
    # + orderId - Work order identifier
    # + task - Task payload
    # + return - Created task or error
    public isolated function addTask(string assetTag, string orderId, Task task) returns Task|error {
        return self.httpClient->post(string `/assets/${assetTag}/work-orders/${orderId}/tasks`, task);
    }

    # Updates a sub-task's completion status within a work order.
    # + assetTag - Unique asset tag
    # + orderId - Work order identifier
    # + taskId - Unique task identifier
    # + completed - New completion status
    # + return - Updated work order or error
    public isolated function updateTaskStatus(string assetTag, string orderId, string taskId, boolean completed) returns WorkOrder|error {
        return self.httpClient->patch(string `/assets/${assetTag}/work-orders/${orderId}/tasks/${taskId}`, {completed: completed});
    }

    # Closes a work order once all its tasks are completed.
    # + assetTag - Unique asset tag
    # + orderId - Unique work order identifier
    # + return - Closed work order or error
    public isolated function closeWorkOrder(string assetTag, string orderId) returns WorkOrder|error {
        return self.httpClient->post(string `/assets/${assetTag}/work-orders/${orderId}/close`, ());
    }

    # Retrieves all registered institutions.
    # + return - Array of institutions or error
    public isolated function getAllInstitutions() returns Institution[]|error {
        return self.httpClient->/institutions;
    }

    # Registers a new institution.
    # + institution - Institution payload
    # + return - Created institution or error
    public isolated function addInstitution(Institution institution) returns Institution|error {
        return self.httpClient->/institutions.post(institution);
    }

    # Removes an institution by unique ID.
    # + id - Institution ID
    # + return - JSON confirmation response or error
    public isolated function deleteInstitution(string id) returns json|error {
        return self.httpClient->/institutions/[id].delete();
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
        "workorder" => {
            if args.length() > 3 && args[1] == "create" {
                string tag = args[2];
                string orderId = args[3];
                string desc = args.length() > 4 ? args[4] : "Maintenance work order";
                WorkOrder wo = {orderId: orderId, status: "OPEN", description: desc, tasks: []};
                WorkOrder|error res = clientInstance.createWorkOrder(tag, wo);
                if res is WorkOrder {
                    io:println(string `Created work order [${res.orderId}] on asset [${tag}]`);
                } else {
                    io:println("Failed to create work order: ", res.message());
                }
            } else if args.length() > 2 && args[1] == "close" {
                string tag = args[2];
                string orderId = args.length() > 3 ? args[3] : "";
                if orderId.length() == 0 {
                    io:println("Usage: bal run -- workorder close <assetTag> <orderId>");
                } else {
                    WorkOrder|error res = clientInstance.closeWorkOrder(tag, orderId);
                    if res is WorkOrder {
                        io:println(string `Work order [${res.orderId}] successfully closed.`);
                    } else {
                        io:println("Failed to close work order: ", res.message());
                    }
                }
            } else {
                io:println("Usage: bal run -- workorder create <assetTag> <orderId> [desc] | workorder close <assetTag> <orderId>");
            }
        }
        "task" => {
            if args.length() > 4 && args[1] == "add" {
                string tag = args[2];
                string orderId = args[3];
                string taskId = args[4];
                string desc = args.length() > 5 ? args[5] : "Work order task";
                Task t = {taskId: taskId, description: desc, completed: false};
                Task|error res = clientInstance.addTask(tag, orderId, t);
                if res is Task {
                    io:println(string `Added task [${res.taskId}] to work order [${orderId}]`);
                } else {
                    io:println("Failed to add task: ", res.message());
                }
            } else if args.length() > 4 && args[1] == "complete" {
                string tag = args[2];
                string orderId = args[3];
                string taskId = args[4];
                WorkOrder|error res = clientInstance.updateTaskStatus(tag, orderId, taskId, true);
                if res is WorkOrder {
                    io:println(string `Task [${taskId}] marked complete on work order [${orderId}].`);
                } else {
                    io:println("Failed to update task: ", res.message());
                }
            } else {
                io:println("Usage: bal run -- task add <assetTag> <orderId> <taskId> [desc] | task complete <assetTag> <orderId> <taskId>");
            }
        }
        "institutions" => {
            Institution[]|error insts = clientInstance.getAllInstitutions();
            if insts is Institution[] {
                io:println(string `Found ${insts.length()} institution(s):`);
                foreach Institution inst in insts {
                    io:println(string `  - [${inst.id}] ${inst.name}`);
                }
            } else {
                io:println("Failed to retrieve institutions: ", insts.message());
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
        io:println("11. Create Work Order for Asset");
        io:println("12. Add Task to Work Order");
        io:println("13. Mark Task Completed");
        io:println("14. Close Work Order");
        io:println("15. List Institutions");
        io:println("16. Add Institution");
        io:println("0. Exit");

        string input = io:readln("Select an option (0-16): ");
        string choice = input.trim();

        // Guard against infinite loop on EOF or piped stdin
        if choice.length() == 0 {
            emptyInputCount += 1;
            if emptyInputCount >= 3 {
                io:println("Multiple empty inputs or EOF detected. Exiting client.");
                break;
            }
            io:println("No selection entered. Please choose an option (0-16).");
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
            "11" => {
                string tag = io:readln("Enter assetTag: ").trim();
                string orderId = io:readln("Work Order ID (e.g. WO-01): ").trim();
                string desc = io:readln("Work Order Description: ").trim();
                string compId = io:readln("Component ID (optional, leave blank if none): ").trim();

                WorkOrder wo = {
                    orderId: orderId,
                    status: "OPEN",
                    description: desc,
                    compId: compId.length() > 0 ? compId : (),
                    tasks: []
                };
                WorkOrder|error res = clientInstance.createWorkOrder(tag, wo);
                if res is WorkOrder {
                    io:println(string `Successfully created work order [${res.orderId}] on asset [${tag}]`);
                } else {
                    io:println("Failed to create work order: ", res.message());
                }
            }
            "12" => {
                string tag = io:readln("Enter assetTag: ").trim();
                string orderId = io:readln("Enter Work Order ID: ").trim();
                string taskId = io:readln("Task ID (e.g. T-01): ").trim();
                string desc = io:readln("Task Description: ").trim();

                Task t = {taskId: taskId, description: desc, completed: false};
                Task|error res = clientInstance.addTask(tag, orderId, t);
                if res is Task {
                    io:println(string `Successfully added task [${res.taskId}] to work order [${orderId}]`);
                } else {
                    io:println("Failed to add task: ", res.message());
                }
            }
            "13" => {
                string tag = io:readln("Enter assetTag: ").trim();
                string orderId = io:readln("Enter Work Order ID: ").trim();
                string taskId = io:readln("Enter Task ID to complete: ").trim();

                WorkOrder|error res = clientInstance.updateTaskStatus(tag, orderId, taskId, true);
                if res is WorkOrder {
                    io:println(string `Task [${taskId}] marked complete on work order [${orderId}].`);
                } else {
                    io:println("Failed to update task: ", res.message());
                }
            }
            "14" => {
                string tag = io:readln("Enter assetTag: ").trim();
                string orderId = io:readln("Enter Work Order ID to close: ").trim();

                WorkOrder|error res = clientInstance.closeWorkOrder(tag, orderId);
                if res is WorkOrder {
                    io:println(string `Successfully closed work order [${res.orderId}]. Status: ${res.status}`);
                } else {
                    io:println("Failed to close work order: ", res.message());
                }
            }
            "15" => {
                Institution[]|error insts = clientInstance.getAllInstitutions();
                if insts is Institution[] {
                    io:println(string `Found ${insts.length()} institution(s):`);
                    foreach Institution inst in insts {
                        io:println(string `  - [${inst.id}] ${inst.name}`);
                    }
                } else {
                    io:println("Failed to retrieve institutions: ", insts.message());
                }
            }
            "16" => {
                string id = io:readln("Institution ID (e.g. INST-01): ").trim();
                string name = io:readln("Institution Name: ").trim();
                Institution inst = {id: id, name: name};
                Institution|error res = clientInstance.addInstitution(inst);
                if res is Institution {
                    io:println(string `Successfully added institution [${res.id}]: ${res.name}`);
                } else {
                    io:println("Failed to add institution: ", res.message());
                }
            }
            "0" => {
                io:println("Exiting Library Client. Goodbye!");
                running = false;
            }
            _ => {
                io:println("Invalid option. Please choose between 0 and 16.");
            }
        }
    }
}

# Prints usage instructions for direct CLI arguments.
function printUsage() {
    io:println("Usage:");
    io:println("  bal run                                      # Run interactive menu");
    io:println("  bal run -- health                            # Check service health");
    io:println("  bal run -- list [inst] [site]                # List assets with optional filtering");
    io:println("  bal run -- get <assetTag>                    # Inspect asset by tag");
    io:println("  bal run -- overdue [date]                    # View overdue maintenance assets");
    io:println("  bal run -- status <assetTag>                 # View asset operational status");
    io:println("  bal run -- delete <assetTag>                 # Delete an asset");
    io:println("  bal run -- workorder create <tag> <id> [desc]# Create work order");
    io:println("  bal run -- workorder close <tag> <id>        # Close work order");
    io:println("  bal run -- task add <tag> <woId> <id> [desc] # Add task to work order");
    io:println("  bal run -- task complete <tag> <woId> <id>   # Mark task as completed");
    io:println("  bal run -- institutions                      # List all institutions");
    io:println("  bal run -- help                              # Show this help message");
}
