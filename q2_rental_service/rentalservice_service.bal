import ballerina/grpc;
import ballerina/log;
import ballerina/time;

# Server port for the Rental Accommodation gRPC service endpoint.
# Configurable via Config.toml or BAL_CONFIG_VAR_PORT per workspace standards.
configurable int port = 9090;

# gRPC Listener endpoint for the Rental Accommodation System.
listener grpc:Listener ep = new (port);

# Server-side gRPC Service implementing the Rental Accommodation contract.
@grpc:Descriptor {value: RENTAL_SERVICE_DESC}
isolated service "RentalService" on ep {

    // Thread-safe in-memory store for all property operations
    private final PropertyStore store = new ();

    # Remote RPC: Adds a new property listing to the system.
    #
    # + value - The AddPropertyRequest payload
    # + return - AddPropertyResponse with the generated assetTag or error
    isolated remote function add_property(AddPropertyRequest value) returns AddPropertyResponse|error {
        log:printInfo(string `Received add_property RPC request for '${value.name}' at '${value.location}'`);

        // Validate that essential property fields are non-empty
        if value.name.trim().length() == 0 {
            return error grpc:InvalidArgumentError("Property name must not be empty.");
        }
        if value.name.trim().length() > 120 {
            return error grpc:InvalidArgumentError("Property name must not exceed 120 characters.");
        }
        if value.location.trim().length() == 0 {
            return error grpc:InvalidArgumentError("Property location must not be empty.");
        }
        if value.propertyType.trim().length() == 0 {
            return error grpc:InvalidArgumentError("Property type must not be empty.");
        }
        if value.hostId.trim().length() == 0 {
            return error grpc:InvalidArgumentError("Host ID must not be empty.");
        }

        // Validate IEEE 754 finite floating point value and non-negativity
        if !value.pricePerNight.isFinite() || value.pricePerNight < 0.0 {
            return error grpc:InvalidArgumentError("Price per night must be a non-negative finite number.");
        }

        Property prop = self.store.addProperty(value);
        log:printInfo(string `Listing created successfully with assetTag '${prop.assetTag}'`);

        return {
            assetTag: prop.assetTag,
            status: prop.status,
            message: string `Property listing created successfully with assetTag '${prop.assetTag}'.`
        };
    }

    # Remote RPC: Updates an existing property listing. Only supplied fields are updated.
    #
    # + value - The UpdatePropertyRequest payload
    # + return - UpdatePropertyResponse with updated listing or error
    isolated remote function update_property(UpdatePropertyRequest value) returns UpdatePropertyResponse|error {
        log:printInfo(string `Received update_property RPC request for assetTag '${value.assetTag}'`);

        if value.assetTag.trim().length() == 0 {
            return error grpc:InvalidArgumentError("Asset tag must not be empty.");
        }
        if value.pricePerNight < 0.0 {
            return error grpc:InvalidArgumentError("Price per night must be non-negative.");
        }

        Property|error result = self.store.updateProperty(value);
        if result is error {
            log:printWarn(string `Update failed for assetTag '${value.assetTag}': ${result.message()}`);
            return {
                success: false,
                message: result.message(),
                property: {}
            };
        }

        log:printInfo(string `Updated property '${value.assetTag}' successfully`);
        return {
            success: true,
            message: string `Property '${value.assetTag}' updated successfully.`,
            property: result
        };
    }

    # Remote RPC: Removes a property listing and returns the host's remaining listings in that region.
    #
    # + value - The RemovePropertyRequest payload
    # + return - RemovePropertyResponse with remaining listings or error
    isolated remote function remove_property(RemovePropertyRequest value) returns RemovePropertyResponse|error {
        log:printInfo(string `Received remove_property RPC request for assetTag '${value.assetTag}'`);

        Property[]|error result = self.store.removeProperty(value.assetTag, value.hostId, value.location);
        if result is error {
            log:printWarn(string `Remove failed for assetTag '${value.assetTag}': ${result.message()}`);
            return {
                success: false,
                message: result.message(),
                remainingProperties: []
            };
        }

        log:printInfo(string `Removed property '${value.assetTag}'. Remaining in '${value.location}': ${result.length()}`);
        return {
            success: true,
            message: string `Property '${value.assetTag}' removed successfully.`,
            remainingProperties: result
        };
    }

    # Remote RPC: Searches for a property by its assetTag.
    # Per acceptance criteria: if missing, returns "Not Available" status rather than failing with an error.
    #
    # + value - The SearchPropertyRequest payload
    # + return - SearchPropertyResponse with found indicator and property details
    isolated remote function search_property(SearchPropertyRequest value) returns SearchPropertyResponse|error {
        log:printInfo(string `Received search_property RPC request for assetTag '${value.assetTag}'`);

        Property? prop = self.store.searchProperty(value.assetTag);
        if prop is () {
            log:printInfo(string `Property with assetTag '${value.assetTag}' not found; returning 'Not Available' status`);
            return {
                found: false,
                status: "Not Available",
                property: {}
            };
        }

        return {
            found: true,
            status: prop.status == "AVAILABLE" ? "Available" : prop.status,
            property: prop
        };
    }

    # Remote RPC: Tentative booking request (stages reservation in temporary cart).
    #
    # + value - The BookPropertyRequest payload
    # + return - BookPropertyResponse
    isolated remote function book_property(BookPropertyRequest value) returns BookPropertyResponse|error {
        log:printInfo(string `Received book_property RPC request for '${value.assetTag}' by '${value.guestId}'`);

        // --- Validate required fields ---
        if value.assetTag.trim().length() == 0 {
            return error grpc:InvalidArgumentError("assetTag must not be empty.");
        }
        if value.guestId.trim().length() == 0 {
            return error grpc:InvalidArgumentError("guestId must not be empty.");
        }
        if value.checkInDate.trim().length() == 0 || value.checkOutDate.trim().length() == 0 {
            return error grpc:InvalidArgumentError("checkInDate and checkOutDate must not be empty.");
        }

        // --- Parse dates ---
        time:Civil checkIn = check parseDate(value.checkInDate);
        time:Civil checkOut = check parseDate(value.checkOutDate);

        // --- Validate checkOut > checkIn ---
        int nights = check nightsBetween(checkIn, checkOut);
        if nights <= 0 {
            return error grpc:InvalidArgumentError("checkOutDate must be after checkInDate.");
        }

        // --- Verify property exists and is available ---
        Property? prop = self.store.getProperty(value.assetTag);
        if prop is () {
            return error("Property not found.");
        }
        if prop.status != "AVAILABLE" {
            return error("Property is not available for booking.");
        }

        // --- Compute cost and generate a unique bookingId ---
        string bookingId = self.store.nextBookingId();
        float estimatedCost = <float>(<decimal>nights * <decimal>prop.pricePerNight);

        // --- Place into the temporary cart ---
        BookingCartEntry entry = {
            bookingId: bookingId,
            assetTag: value.assetTag,
            guestId: value.guestId,
            checkIn: checkIn,
            checkOut: checkOut,
            pricePerNightSnapshot: prop.pricePerNight,
            nights: nights,
            estimatedCost: estimatedCost
        };
        check self.store.addToCart(entry.clone());

        // --- Build response ---
        Booking pending = {
            bookingId: bookingId,
            assetTag: value.assetTag,
            guestId: value.guestId,
            checkInDate: value.checkInDate,
            checkOutDate: value.checkOutDate,
            totalCost: estimatedCost,
            status: "PENDING"
        };

        log:printInfo(string `Temporary booking '${bookingId}' placed with estimated cost ${estimatedCost}`);

        return {
            success: true,
            message: "Temporary booking reservation placed. Call confirm_booking to finalize.",
            bookingId: bookingId,
            estimatedCost: estimatedCost,
            booking: pending
        };
    }

    # Remote RPC: Finalize booking with overlap check and exact cost calculation.
    #
    # + value - The ConfirmBookingRequest payload
    # + return - ConfirmBookingResponse
    isolated remote function confirm_booking(ConfirmBookingRequest value) returns ConfirmBookingResponse|error {
        log:printInfo(string `Received confirm_booking RPC request for booking '${value.bookingId}'`);

        // --- Validate required fields ---
        if value.bookingId.trim().length() == 0 {
            return error grpc:InvalidArgumentError("bookingId must not be empty.");
        }
        if value.guestId.trim().length() == 0 {
            return error grpc:InvalidArgumentError("guestId must not be empty.");
        }
        if value.assetTag.trim().length() == 0 {
            return error grpc:InvalidArgumentError("assetTag must not be empty.");
        }

        // --- Delegate to store: overlap check, promote to confirmed, clear cart ---
        Booking|error result = self.store.confirmBooking(value.bookingId, value.guestId, value.assetTag);
        if result is error {
            log:printWarn(string `Confirm failed for booking '${value.bookingId}': ${result.message()}`);
            return error(result.message());
        }

        log:printInfo(string `Booking '${result.bookingId}' confirmed. Total cost: ${result.totalCost}`);

        return {
            success: true,
            message: "Booking confirmed successfully.",
            bookingId: result.bookingId,
            totalCost: result.totalCost,
            status: "CONFIRMED",
            booking: result
        };
    }

    # Remote RPC: Client-streaming endpoint for registering multiple users in a single call.
    #
    # + clientStream - Stream of incoming User messages
    # + return - Single CreateUsersResponse confirmation
    isolated remote function create_users(stream<User, grpc:Error?> clientStream) returns CreateUsersResponse|error {
        int count = 0;
        record {|User value;|}|grpc:Error? item = clientStream.next();
        while item is record {|User value;|} {
            User user = item.value;
            _ = self.store.addUser(user);
            count += 1;
            log:printInfo(string `Registered user [${user.role}] '${user.name}' (${user.userId})`);
            item = clientStream.next();
        }
        if item is grpc:Error {
            return item;
        }

        return {
            count: count,
            message: string `Successfully registered ${count} user(s).`,
            success: true
        };
    }

    # Remote RPC: Server-streaming endpoint for browsing available property listings.
    #
    # + value - Optional search filters
    # + return - Stream of matching Property messages
    isolated remote function list_available_properties(ListAvailablePropertiesRequest value) returns stream<Property, error?>|error {
        log:printInfo(string `Received list_available_properties streaming request for location: '${value.location}'`);
        Property[] matches = self.store.listAvailableProperties(value);
        return matches.toStream();
    }
}
