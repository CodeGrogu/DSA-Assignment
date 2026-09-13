import ballerina/grpc;
import ballerina/test;

@test:Config {
    groups: ["store", "add"]
}
isolated function testAddPropertyAndRetrieve() returns error? {
    PropertyStore store = new ();

    AddPropertyRequest req = {
        name: "Ocean View Apartment",
        location: "Swakopmund",
        propertyType: "Apartment",
        pricePerNight: 850.0,
        hostId: "HOST-001"
    };

    Property prop = store.addProperty(req);
    test:assertTrue(prop.assetTag.startsWith("PROP-"), "assetTag should begin with PROP- prefix");
    test:assertEquals(prop.name, "Ocean View Apartment");
    test:assertEquals(prop.location, "Swakopmund");
    test:assertEquals(prop.propertyType, "Apartment");
    test:assertEquals(prop.pricePerNight, 850.0);
    test:assertEquals(prop.status, "AVAILABLE");
    test:assertEquals(prop.hostId, "HOST-001");

    Property? fetched = store.getProperty(prop.assetTag);
    test:assertTrue(fetched is Property, "Property should be retrievable immediately after creation");
    if fetched is Property {
        test:assertEquals(fetched.assetTag, prop.assetTag);
        test:assertEquals(fetched.name, "Ocean View Apartment");
    }
}

@test:Config {
    groups: ["store", "concurrency", "unique_id"]
}
isolated function testUniqueAssetTagsAcrossAdds() returns error? {
    PropertyStore store = new ();

    AddPropertyRequest req1 = {
        name: "Listing 1",
        location: "Windhoek",
        propertyType: "House",
        pricePerNight: 1200.0,
        hostId: "HOST-001"
    };
    AddPropertyRequest req2 = {
        name: "Listing 2",
        location: "Windhoek",
        propertyType: "House",
        pricePerNight: 1500.0,
        hostId: "HOST-001"
    };

    Property p1 = store.addProperty(req1);
    Property p2 = store.addProperty(req2);

    test:assertNotEquals(p1.assetTag, p2.assetTag, "Asset tags must be unique and collision-free");
}

@test:Config {
    groups: ["store", "update"]
}
isolated function testUpdatePropertyWithoutClobbering() returns error? {
    PropertyStore store = new ();

    AddPropertyRequest createReq = {
        name: "Sunset Villa",
        location: "Walvis Bay",
        propertyType: "Villa",
        pricePerNight: 2000.0,
        hostId: "HOST-002"
    };
    Property original = store.addProperty(createReq);

    // Partial update: modify only pricePerNight and status
    UpdatePropertyRequest updateReq = {
        assetTag: original.assetTag,
        pricePerNight: 2250.0,
        status: "RENTED"
    };

    Property updated = check store.updateProperty(updateReq);
    test:assertEquals(updated.assetTag, original.assetTag);
    test:assertEquals(updated.pricePerNight, 2250.0);
    test:assertEquals(updated.status, "RENTED");
    // Verify untouched fields were preserved
    test:assertEquals(updated.name, "Sunset Villa");
    test:assertEquals(updated.location, "Walvis Bay");
    test:assertEquals(updated.propertyType, "Villa");
    test:assertEquals(updated.hostId, "HOST-002");
}

@test:Config {
    groups: ["store", "update", "error"]
}
isolated function testUpdateNonexistentPropertyReturnsError() {
    PropertyStore store = new ();
    UpdatePropertyRequest updateReq = {
        assetTag: "PROP-9999",
        name: "Ghost Property"
    };

    Property|error result = store.updateProperty(updateReq);
    test:assertTrue(result is error, "Updating a nonexistent property must return an error");
}

@test:Config {
    groups: ["store", "remove"]
}
isolated function testRemovePropertyReturnsRegionalList() returns error? {
    PropertyStore store = new ();

    // Add two properties for HOST-003 in Windhoek and one in Swakopmund
    Property p1 = store.addProperty({
        name: "Windhoek Central Studio",
        location: "Windhoek",
        propertyType: "Studio",
        pricePerNight: 600.0,
        hostId: "HOST-003"
    });
    Property p2 = store.addProperty({
        name: "Windhoek Luxury Loft",
        location: "Windhoek",
        propertyType: "Loft",
        pricePerNight: 1400.0,
        hostId: "HOST-003"
    });
    _ = store.addProperty({
        name: "Swakopmund Beach Flat",
        location: "Swakopmund",
        propertyType: "Apartment",
        pricePerNight: 900.0,
        hostId: "HOST-003"
    });

    // Remove p1 and verify remaining in Windhoek
    Property[] remaining = check store.removeProperty(p1.assetTag, "HOST-003", "Windhoek");
    test:assertEquals(remaining.length(), 1, "Host should have 1 remaining property in Windhoek");
    test:assertEquals(remaining[0].assetTag, p2.assetTag);

    // Verify p1 is gone
    Property? deleted = store.getProperty(p1.assetTag);
    test:assertTrue(deleted is (), "Deleted property must no longer exist in the store");
}

@test:Config {
    groups: ["store", "remove", "error"]
}
isolated function testRemoveNonexistentPropertyReturnsError() {
    PropertyStore store = new ();
    Property[]|error result = store.removeProperty("PROP-NONEXISTENT", "HOST-001", "Windhoek");
    test:assertTrue(result is error, "Removing a nonexistent property must return an error");
}

@test:Config {
    groups: ["store", "search"]
}
isolated function testSearchPropertyFoundAndNotFound() returns error? {
    PropertyStore store = new ();

    Property prop = store.addProperty({
        name: "Kalahari Bush Camp",
        location: "Mariental",
        propertyType: "Cottage",
        pricePerNight: 1100.0,
        hostId: "HOST-004"
    });

    // Found case
    Property? found = store.searchProperty(prop.assetTag);
    test:assertTrue(found is Property, "Existing property must be found");
    if found is Property {
        test:assertEquals(found.name, "Kalahari Bush Camp");
    }

    // Missing case
    Property? missing = store.searchProperty("PROP-UNKNOWN");
    test:assertTrue(missing is (), "Nonexistent property must return nil");
}

@test:Config {
    groups: ["store", "filter", "streaming"]
}
isolated function testListAvailablePropertiesFilters() returns error? {
    PropertyStore store = new ();

    _ = store.addProperty({
        name: "Budget Room",
        location: "Windhoek",
        propertyType: "Room",
        pricePerNight: 350.0,
        hostId: "HOST-005"
    });
    _ = store.addProperty({
        name: "Mid-Range Flat",
        location: "Windhoek",
        propertyType: "Apartment",
        pricePerNight: 750.0,
        hostId: "HOST-005"
    });
    Property p3 = store.addProperty({
        name: "Luxury Penthouse",
        location: "Windhoek",
        propertyType: "Apartment",
        pricePerNight: 2500.0,
        hostId: "HOST-005"
    });

    // Mark p3 as RENTED so it should not appear in available listings
    _ = check store.updateProperty({
        assetTag: p3.assetTag,
        status: "RENTED"
    });

    // Filter by location Windhoek and maxPrice 1000
    ListAvailablePropertiesRequest filter = {
        location: "Windhoek",
        maxPrice: 1000.0
    };

    Property[] available = store.listAvailableProperties(filter);
    test:assertEquals(available.length(), 2, "Should return 2 available properties under 1000");
}

@test:Config {
    groups: ["proto", "user", "issue34"]
}
isolated function testUserModelCreationAndRoleDistinction() {
    User hostUser = {
        userId: "USR-001",
        name: "Alice Host",
        role: "HOST",
        email: "alice@example.com",
        phoneNumber: "+264811234567"
    };
    User guestUser = {
        userId: "USR-002",
        name: "Bob Guest",
        role: "GUEST",
        email: "bob@example.com",
        phoneNumber: "+264819876543"
    };

    test:assertEquals(hostUser.role, "HOST", "User model must distinguish Host role");
    test:assertEquals(guestUser.role, "GUEST", "User model must distinguish Guest role");
    test:assertEquals(hostUser.userId, "USR-001");
    test:assertEquals(guestUser.userId, "USR-002");
}

@test:Config {
    groups: ["streaming", "issue41"]
}
isolated function testCreateUsersStreamsMoreThanThreeUsers() returns error? {
    RentalServiceClient rentalClient = check new ("http://localhost:9090");
    Create_usersStreamingClient userStream = check rentalClient->create_users();
    int expectedCount = 5;

    foreach int index in 1 ... expectedCount {
        User user = {
            userId: string `USR-${index}`,
            name: string `Test User ${index}`,
            role: index == 1 ? "HOST" : "GUEST",
            email: string `user${index}@example.com`,
            phoneNumber: string `+2648100000${index}`
        };
        check userStream->sendUser(user);
    }

    check userStream->complete();
    CreateUsersResponse|grpc:Error? response = check userStream->receiveCreateUsersResponse();
    test:assertTrue(response is CreateUsersResponse, "The stream should return one final response");
    if response is CreateUsersResponse {
        test:assertEquals(response.count, expectedCount);
        test:assertTrue(response.success);
    }
}

@test:Config {
    groups: ["proto", "booking", "issue36"]
}
isolated function testBookingModelAndResponseCarriesGuestIdentifier() {
    Booking booking = {
        bookingId: "BOOK-2026-001",
        assetTag: "PROP-1001",
        guestId: "GUEST-555",
        checkInDate: "2026-10-01",
        checkOutDate: "2026-10-05",
        totalCost: 3400.0,
        status: "CONFIRMED"
    };

    test:assertEquals(booking.bookingId, "BOOK-2026-001");
    test:assertEquals(booking.assetTag, "PROP-1001");
    test:assertEquals(booking.guestId, "GUEST-555", "Booking must carry guest identifier for cart state");
    test:assertEquals(booking.totalCost, 3400.0);
    test:assertEquals(booking.status, "CONFIRMED");

    ConfirmBookingResponse confirmResp = {
        success: true,
        message: "Booking confirmed successfully.",
        bookingId: booking.bookingId,
        totalCost: booking.totalCost,
        status: "CONFIRMED",
        booking: booking
    };

    test:assertTrue(confirmResp.success);
    test:assertEquals(confirmResp.totalCost, 3400.0);
    test:assertEquals(confirmResp.booking.guestId, "GUEST-555");
}

