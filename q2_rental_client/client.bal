import ballerina/grpc;
import ballerina/io;

# Target gRPC server endpoint URL for the RentalService microservice.
# Configurable via Config.toml or BAL_CONFIG_VAR_SERVICEURL.
configurable string serviceUrl = "http://localhost:9090";

# RPC timeout in seconds for gRPC client invocations.
# Configurable via Config.toml or BAL_CONFIG_VAR_RPCTIMEOUT to prevent indefinite blocking on network or server hangs.
configurable decimal rpcTimeout = 10.0;

# Entry point for the Vacation Property Rental CLI client application.
# Establishes a gRPC client channel with configured timeout and runs an interactive console menu.
#
# + return - Returns an error if the gRPC client stub initialization fails.
public function main() returns error? {
    // Initialise the gRPC client stub with configurable endpoint and 10s RPC timeout
    RentalServiceClient rentalClient = check new (serviceUrl, timeout = rpcTimeout);

    boolean running = true;
    int emptyInputCount = 0;
    while running {
        io:println("\n=== Rental Service Client ===");
        io:println("1. Add Property");
        io:println("2. Update Property");
        io:println("3. Remove Property");
        io:println("4. Search Property");
        io:println("5. List Available Properties");
        io:println("6. Register Users (Client Streaming)");
        io:println("7. Book Property (Book -> Confirm)");
        io:println("0. Exit");
        string choice = io:readln("Choose an option: ");

        // Guard against infinite busy-looping when stdin reaches EOF or piped input runs out
        if choice.trim().length() == 0 {
            emptyInputCount += 1;
            if emptyInputCount >= 3 {
                io:println("Multiple empty inputs or EOF detected. Exiting Rental Service Client.");
                break;
            }
            io:println("No option entered. Please select a valid menu option (0-7).");
            continue;
        }
        emptyInputCount = 0;

        match choice.trim() {
            "1" => {
                handleAddProperty(rentalClient);
            }
            "2" => {
                handleUpdateProperty(rentalClient);
            }
            "3" => {
                handleRemoveProperty(rentalClient);
            }
            "4" => {
                handleSearchProperty(rentalClient);
            }
            "5" => {
                handleListAvailableProperties(rentalClient);
            }
            "6" => {
                handleCreateUsers(rentalClient);
            }
            "7" => {
                handleBookProperty(rentalClient);
            }
            "0" => {
                running = false;
                io:println("Goodbye!");
            }
            _ => {
                io:println("Invalid option, try again.");
            }
        }
    }
}

# Handles the interactive workflow for adding a new vacation property listing.
# Collects property metadata from console input and issues an AddProperty RPC request.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleAddProperty(RentalServiceClient rentalClient) {
    string name = io:readln("Enter property name: ");
    if name.trim().length() == 0 {
        io:println("Property name cannot be empty.");
        return;
    }
    string location = io:readln("Enter location: ");
    if location.trim().length() == 0 {
        io:println("Property location cannot be empty.");
        return;
    }
    string propertyType = io:readln("Enter property type (e.g. Apartment, House, Villa): ");
    if propertyType.trim().length() == 0 {
        io:println("Property type cannot be empty.");
        return;
    }
    string priceStr = io:readln("Enter price per night: ");
    float|error price = 'float:fromString(priceStr.trim());
    if price is error || price < 0.0 || !price.isFinite() {
        io:println("Invalid price format. Must be a non-negative finite decimal number.");
        return;
    }
    string hostId = io:readln("Enter host ID: ");
    if hostId.trim().length() == 0 {
        io:println("Host ID cannot be empty.");
        return;
    }

    AddPropertyRequest req = {
        name: name.trim(),
        location: location.trim(),
        propertyType: propertyType.trim(),
        pricePerNight: price,
        hostId: hostId.trim()
    };

    AddPropertyResponse|grpc:Error resp = rentalClient->add_property(req);
    if resp is grpc:Error {
        io:println("Error adding property: ", resp.message());
    } else {
        // Display the server-assigned unique assetTag and status
        io:println(string `Property added successfully! [AssetTag: ${resp.assetTag}, Status: ${resp.status}]`);
        io:println(resp.message);
    }
}

# Handles the interactive workflow for updating an existing property listing.
# Resolves the target listing by its unique `assetTag` and transmits update fields.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleUpdateProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to update: ");
    // Validate that the domain identifier assetTag is provided
    if assetTag.trim().length() == 0 {
        io:println("Asset tag cannot be empty.");
        return;
    }

    string name = io:readln("Enter new name (leave empty to keep current): ");
    string location = io:readln("Enter new location (leave empty to keep current): ");
    string propertyType = io:readln("Enter new property type (leave empty to keep current): ");
    string priceStr = io:readln("Enter new price per night (leave empty to keep current): ");
    float price = 0.0;
    if priceStr.trim().length() > 0 {
        float|error parsedPrice = 'float:fromString(priceStr.trim());
        if parsedPrice is error || parsedPrice < 0.0 || !parsedPrice.isFinite() {
            io:println("Invalid price format. Must be non-negative and finite. Keeping current price.");
        } else {
            price = parsedPrice;
        }
    }
    string status = io:readln("Enter new status (leave empty to keep current): ");

    UpdatePropertyRequest req = {
        assetTag: assetTag.trim(),
        name: name.trim(),
        location: location.trim(),
        propertyType: propertyType.trim(),
        pricePerNight: price,
        status: status.trim()
    };

    UpdatePropertyResponse|grpc:Error resp = rentalClient->update_property(req);
    if resp is grpc:Error {
        io:println("Error updating property: ", resp.message());
    } else if !resp.success {
        io:println("Update failed: ", resp.message);
    } else {
        io:println("Property updated successfully!");
        io:println(string `[${resp.property.assetTag}] ${resp.property.name} - ${resp.property.location} - ${resp.property.propertyType} - N$${resp.property.pricePerNight} - ${resp.property.status}`);
    }
}

# Handles the interactive workflow for removing a property listing by its `assetTag`.
# Displays all remaining active listings registered under the specified host and location.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleRemoveProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to remove: ");
    // Ensure the entity assetTag identifier is present before invoking RPC
    if assetTag.trim().length() == 0 {
        io:println("Asset tag cannot be empty.");
        return;
    }
    string hostId = io:readln("Enter host ID: ");
    if hostId.trim().length() == 0 {
        io:println("Host ID cannot be empty.");
        return;
    }
    string location = io:readln("Enter location: ");
    if location.trim().length() == 0 {
        io:println("Location cannot be empty.");
        return;
    }

    RemovePropertyRequest req = {
        assetTag: assetTag.trim(),
        hostId: hostId.trim(),
        location: location.trim()
    };

    RemovePropertyResponse|grpc:Error resp = rentalClient->remove_property(req);
    if resp is grpc:Error {
        io:println("Error removing property: ", resp.message());
    } else if !resp.success {
        io:println("Remove failed: ", resp.message);
    } else {
        io:println("Property removed successfully!");
        io:println(resp.message);
        io:println(string `Host has ${resp.remainingProperties.length()} remaining property(ies) in this location:`);
        foreach Property p in resp.remainingProperties {
            io:println(string `- [${p.assetTag}] ${p.name} (${p.propertyType}) - N$${p.pricePerNight}`);
        }
    }
}

# Handles querying a property listing by its unique `assetTag` identifier.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleSearchProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to search: ");
    // Guard against empty assetTag search queries
    if assetTag.trim().length() == 0 {
        io:println("Asset tag cannot be empty.");
        return;
    }

    SearchPropertyRequest req = {
        assetTag: assetTag.trim()
    };

    SearchPropertyResponse|grpc:Error resp = rentalClient->search_property(req);
    if resp is grpc:Error {
        io:println("Error searching property: ", resp.message());
    } else if !resp.found {
        io:println(string `Property with asset tag '${assetTag.trim()}' was not found. Status: ${resp.status}`);
    } else {
        Property p = resp.property;
        io:println("Property Found:");
        io:println(string `  Asset Tag:      ${p.assetTag}`);
        io:println(string `  Name:           ${p.name}`);
        io:println(string `  Location:       ${p.location}`);
        io:println(string `  Type:           ${p.propertyType}`);
        io:println(string `  Price/Night:    N$${p.pricePerNight}`);
        io:println(string `  Status:         ${p.status}`);
        io:println(string `  Host ID:        ${p.hostId}`);
    }
}

# Handles server-streaming retrieval of available properties with optional search filters.
# Enforces bound validation (minPrice <= maxPrice) to avoid empty-result filter inversions.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleListAvailableProperties(RentalServiceClient rentalClient) {
    string location = io:readln("Filter by location (leave empty for all): ");
    string propType = io:readln("Filter by property type (leave empty for all): ");
    string minPriceStr = io:readln("Filter by min price (leave empty for none): ");
    string maxPriceStr = io:readln("Filter by max price (leave empty for none): ");

    float minPrice = 0.0;
    boolean hasMinPrice = false;
    if minPriceStr.trim().length() > 0 {
        float|error parsed = 'float:fromString(minPriceStr.trim());
        if parsed is float {
            if parsed < 0.0 || !parsed.isFinite() {
                io:println("Validation error: Minimum price cannot be negative or invalid.");
                return;
            }
            minPrice = parsed;
            hasMinPrice = true;
        } else {
            io:println("Invalid min price format, ignoring that filter.");
        }
    }

    float maxPrice = 0.0;
    boolean hasMaxPrice = false;
    if maxPriceStr.trim().length() > 0 {
        float|error parsed = 'float:fromString(maxPriceStr.trim());
        if parsed is float {
            if parsed < 0.0 || !parsed.isFinite() {
                io:println("Validation error: Maximum price cannot be negative or invalid.");
                return;
            }
            maxPrice = parsed;
            hasMaxPrice = true;
        } else {
            io:println("Invalid max price format, ignoring that filter.");
        }
    }

    // Validate that minimum price does not exceed maximum price when both bounds are supplied
    if hasMinPrice && hasMaxPrice && minPrice > maxPrice {
        io:println(string `Validation error: Minimum price (N$${minPrice}) cannot exceed maximum price (N$${maxPrice}).`);
        return;
    }

    ListAvailablePropertiesRequest req = {
        location: location.trim(),
        propertyType: propType.trim(),
        minPrice: minPrice,
        maxPrice: maxPrice
    };

    stream<Property, grpc:Error?>|grpc:Error propStream = rentalClient->list_available_properties(req);
    if propStream is grpc:Error {
        io:println("Error listing properties: ", propStream.message());
        return;
    }

    io:println("\n--- Available Properties ---");
    int count = 0;
    error? e = propStream.forEach(function(Property p) {
        count += 1;
        io:println(string `${count}. [${p.assetTag}] ${p.name} in ${p.location} (${p.propertyType}) - N$${p.pricePerNight}/night`);
    });

    if e is error {
        io:println("Error reading stream: ", e.message());
    } else if count == 0 {
        io:println("No available properties found matching the criteria.");
    }
}

# Handles client-streaming bulk user registration to the RentalService.
# Streams User records to the gRPC server and terminates immediately on stream write failures.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleCreateUsers(RentalServiceClient rentalClient) {
    Create_usersStreamingClient|grpc:Error streamingClient = rentalClient->create_users();
    if streamingClient is grpc:Error {
        io:println("Error starting user registration stream: ", streamingClient.message());
        return;
    }

    io:println();
    io:println("--- Register Users ---");
    int count = 0;
    boolean addingUsers = true;

    while addingUsers {
        io:println();
        io:println(string `User #${count + 1}:`);
        string userId = io:readln("  User ID (leave empty to stop): ");
        // Immediately abort on empty user ID or EOF so extra prompts are not asked
        if userId.trim().length() == 0 {
            io:println("  Empty user ID detected. Stopping user entry.");
            break;
        }

        string name = io:readln("  Name: ");
        if name.trim().length() == 0 {
            io:println("  User name cannot be empty. Skipping this entry.");
            continue;
        }

        string role = io:readln("  Role (HOST/GUEST): ");
        string normalizedRole = role.trim().toUpperAscii();
        if normalizedRole != "HOST" && normalizedRole != "GUEST" {
            io:println("  Invalid role provided. Defaulting to GUEST.");
            normalizedRole = "GUEST";
        }
        string email = io:readln("  Email: ");
        string phoneNumber = io:readln("  Phone Number: ");

        User user = {
            userId: userId.trim(),
            name: name.trim(),
            role: normalizedRole,
            email: email.trim(),
            phoneNumber: phoneNumber.trim()
        };

        // Terminate the streaming loop immediately on grpc:Error instead of attempting writes on broken stream
        grpc:Error? sendErr = streamingClient->sendUser(user);
        if sendErr is grpc:Error {
            io:println("  Error sending user (terminating stream): ", sendErr.message());
            return;
        }

        count += 1;
        io:println(string `  Queued '${user.name}' [${user.role}] for registration.`);

        string more = io:readln("Add another user? (y/n): ");
        if more.trim().toLowerAscii() != "y" {
            addingUsers = false;
        }
    }

    // Gracefully handle the scenario where no users were queued
    if count == 0 {
        io:println("No users were registered. Exiting user registration.");
        grpc:Error? completeErr = streamingClient->complete();
        if completeErr is grpc:Error {
            io:println("Error completing stream: ", completeErr.message());
        }
        // Drain and discard any pending server response to ensure clean stream termination
        CreateUsersResponse|grpc:Error? drainResp = streamingClient->receiveCreateUsersResponse();
        if drainResp is grpc:Error {
            io:println("Notice: stream closed: ", drainResp.message());
        }
        return;
    }

    // Signal completion of the client stream to the server
    grpc:Error? completeErr = streamingClient->complete();
    if completeErr is grpc:Error {
        io:println("Error closing the stream: ", completeErr.message());
        return;
    }

    // Await server acknowledgement containing aggregate registration count
    CreateUsersResponse|grpc:Error? resp = streamingClient->receiveCreateUsersResponse();
    if resp is grpc:Error {
        io:println("Error receiving confirmation: ", resp.message());
    } else if resp is () {
        io:println("No confirmation received from server.");
    } else {
        io:println();
        io:println(string `Registration confirmation: ${resp.message}`);
        io:println(string `Total registered: ${resp.count} | Success: ${resp.success}`);
    }
}

# Handles the two-phase booking workflow: creating a provisional booking followed by confirmation.
# Targets the reservation by its unique `assetTag` identifier.
#
# + rentalClient - Active gRPC client stub connected to RentalService.
function handleBookProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to book: ");
    // Validate target assetTag before initiating booking RPC
    if assetTag.trim().length() == 0 {
        io:println("Asset tag cannot be empty.");
        return;
    }
    string guestId = io:readln("Enter guest ID: ");
    if guestId.trim().length() == 0 {
        io:println("Guest ID cannot be empty.");
        return;
    }
    string checkInDate = io:readln("Enter check-in date (e.g. 2026-09-20): ");
    if checkInDate.trim().length() == 0 {
        io:println("Check-in date cannot be empty.");
        return;
    }
    string checkOutDate = io:readln("Enter check-out date (e.g. 2026-09-25): ");
    if checkOutDate.trim().length() == 0 {
        io:println("Check-out date cannot be empty.");
        return;
    }

    BookPropertyRequest bookReq = {
        assetTag: assetTag.trim(),
        guestId: guestId.trim(),
        checkInDate: checkInDate.trim(),
        checkOutDate: checkOutDate.trim()
    };

    // Phase 1: Request provisional booking
    BookPropertyResponse|grpc:Error bookResp = rentalClient->book_property(bookReq);
    if bookResp is grpc:Error {
        io:println("Error placing booking: ", bookResp.message());
        return;
    }
    if !bookResp.success {
        io:println(string `Booking could not be placed: ${bookResp.message}`);
        return;
    }

    io:println(string `Temporary booking placed. [Booking ID: ${bookResp.bookingId}]`);
    io:println(bookResp.message);

    string proceed = io:readln("Confirm this booking now? (y/n): ");
    if proceed.trim().toLowerAscii() != "y" {
        io:println("Booking left unconfirmed in your cart.");
        return;
    }

    // Phase 2: Confirm provisional booking using returned bookingId and assetTag
    ConfirmBookingRequest confirmReq = {
        bookingId: bookResp.bookingId,
        guestId: guestId.trim(),
        assetTag: assetTag.trim()
    };

    ConfirmBookingResponse|grpc:Error confirmResp = rentalClient->confirm_booking(confirmReq);
    if confirmResp is grpc:Error {
        io:println("Error confirming booking: ", confirmResp.message());
        return;
    }
    if !confirmResp.success {
        io:println(string `Booking rejected: ${confirmResp.message}`);
        return;
    }

    io:println();
    io:println("Booking confirmed successfully!");
    io:println(string `  Booking ID:   ${confirmResp.bookingId}`);
    io:println(string `  Total Cost:   N$${confirmResp.totalCost}`);
    io:println(string `  Status:       ${confirmResp.status}`);
}
