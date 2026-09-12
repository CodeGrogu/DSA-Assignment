import ballerina/grpc;
import ballerina/io;

public function main() returns error? {
    // Connect to the RentalService server running on localhost:9090
    RentalServiceClient rentalClient = check new ("http://localhost:9090");

    boolean running = true;
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

        match choice {
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

function handleAddProperty(RentalServiceClient rentalClient) {
    string name = io:readln("Enter property name: ");
    string location = io:readln("Enter location: ");
    string propertyType = io:readln("Enter property type (e.g. Apartment, House, Villa): ");
    string priceStr = io:readln("Enter price per night: ");
    float|error price = 'float:fromString(priceStr.trim());
    if price is error {
        io:println("Invalid price format. Must be a decimal number.");
        return;
    }
    string hostId = io:readln("Enter host ID: ");

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
        io:println(string `Property added successfully! [AssetTag: ${resp.assetTag}, Status: ${resp.status}]`);
        io:println(resp.message);
    }
}

function handleUpdateProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to update: ");
    string name = io:readln("Enter new name (leave empty to keep current): ");
    string location = io:readln("Enter new location (leave empty to keep current): ");
    string propertyType = io:readln("Enter new property type (leave empty to keep current): ");
    string priceStr = io:readln("Enter new price per night (leave empty to keep current): ");
    float price = 0.0;
    if priceStr.trim().length() > 0 {
        float|error parsedPrice = 'float:fromString(priceStr.trim());
        if parsedPrice is error {
            io:println("Invalid price format. Keeping current price.");
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

function handleRemoveProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to remove: ");
    string hostId = io:readln("Enter host ID: ");
    string location = io:readln("Enter location: ");

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

function handleSearchProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to search: ");

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

function handleListAvailableProperties(RentalServiceClient rentalClient) {
    string location = io:readln("Filter by location (leave empty for all): ");
    string propType = io:readln("Filter by property type (leave empty for all): ");
    string minPriceStr = io:readln("Filter by min price (leave empty for none): ");
    string maxPriceStr = io:readln("Filter by max price (leave empty for none): ");

    float minPrice = 0.0;
    if minPriceStr.trim().length() > 0 {
        float|error parsed = 'float:fromString(minPriceStr.trim());
        if parsed is float {
            minPrice = parsed;
        } else {
            io:println("Invalid min price format, ignoring that filter.");
        }
    }

    float maxPrice = 0.0;
    if maxPriceStr.trim().length() > 0 {
        float|error parsed = 'float:fromString(maxPriceStr.trim());
        if parsed is float {
            maxPrice = parsed;
        } else {
            io:println("Invalid max price format, ignoring that filter.");
        }
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
        string userId = io:readln("  User ID: ");
        string name = io:readln("  Name: ");
        string role = io:readln("  Role (HOST/GUEST): ");
        string email = io:readln("  Email: ");
        string phoneNumber = io:readln("  Phone Number: ");

        User user = {
            userId: userId.trim(),
            name: name.trim(),
            role: role.trim().toUpperAscii(),
            email: email.trim(),
            phoneNumber: phoneNumber.trim()
        };

        grpc:Error? sendErr = streamingClient->sendUser(user);
        if sendErr is grpc:Error {
            io:println("  Error sending user: ", sendErr.message());
        } else {
            count += 1;
            io:println(string `  Queued '${user.name}' [${user.role}] for registration.`);
        }

        string more = io:readln("Add another user? (y/n): ");
        if more.trim().toLowerAscii() != "y" {
            addingUsers = false;
        }
    }

    grpc:Error? completeErr = streamingClient->complete();
    if completeErr is grpc:Error {
        io:println("Error closing the stream: ", completeErr.message());
        return;
    }

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

function handleBookProperty(RentalServiceClient rentalClient) {
    string assetTag = io:readln("Enter asset tag to book: ");
    string guestId = io:readln("Enter guest ID: ");
    string checkInDate = io:readln("Enter check-in date (e.g. 2026-09-20): ");
    string checkOutDate = io:readln("Enter check-out date (e.g. 2026-09-25): ");

    BookPropertyRequest bookReq = {
        assetTag: assetTag.trim(),
        guestId: guestId.trim(),
        checkInDate: checkInDate.trim(),
        checkOutDate: checkOutDate.trim()
    };

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
