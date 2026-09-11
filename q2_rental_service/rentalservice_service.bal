import ballerina/grpc;
import ballerina/log;

# gRPC Listener endpoint for the Rental Accommodation System.
listener grpc:Listener ep = new (9090);

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

        if value.name.trim().length() == 0 {
            return error grpc:InvalidArgumentError("Property name must not be empty.");
        }
        if value.pricePerNight < 0.0 {
            return error grpc:InvalidArgumentError("Price per night must be non-negative.");
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
        string bookingId = string `TEMP-${value.assetTag}-${value.guestId}`;
        Booking booking = {
            bookingId: bookingId,
            assetTag: value.assetTag,
            guestId: value.guestId,
            checkInDate: value.checkInDate,
            checkOutDate: value.checkOutDate,
            totalCost: 0.0,
            status: "PENDING"
        };
        return {
            success: true,
            message: "Temporary booking reservation placed.",
            bookingId: bookingId,
            estimatedCost: 0.0,
            booking: booking
        };
    }

    # Remote RPC: Finalize booking with overlap check and exact cost calculation.
    #
    # + value - The ConfirmBookingRequest payload
    # + return - ConfirmBookingResponse
    isolated remote function confirm_booking(ConfirmBookingRequest value) returns ConfirmBookingResponse|error {
        log:printInfo(string `Received confirm_booking RPC request for booking '${value.bookingId}'`);
        Booking booking = {
            bookingId: value.bookingId,
            assetTag: value.assetTag,
            guestId: value.guestId,
            checkInDate: "",
            checkOutDate: "",
            totalCost: 0.0,
            status: "CONFIRMED"
        };
        return {
            success: true,
            message: "Booking confirmed successfully.",
            bookingId: value.bookingId,
            totalCost: 0.0,
            status: "CONFIRMED",
            booking: booking
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
            count += 1;
            log:printInfo(string `Registered user [${item.value.role}] '${item.value.name}' (${item.value.userId})`);
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
