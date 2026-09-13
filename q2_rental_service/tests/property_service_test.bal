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

@test:Config {
    groups: ["store", "remove", "security", "authorization"]
}
isolated function testRemovePropertyUnauthorizedHostFails() returns error? {
    PropertyStore store = new ();

    Property p = store.addProperty({
        name: "Sunset Beach Villa",
        location: "Swakopmund",
        propertyType: "Villa",
        pricePerNight: 2000.0,
        hostId: "HOST-001"
    });

    // Attempt removal by an unauthorized host (HOST-999)
    Property[]|error result = store.removeProperty(p.assetTag, "HOST-999", "Swakopmund");
    test:assertTrue(result is error, "Attempting to remove property by non-owning host must fail");
    if result is error {
        test:assertTrue(result.message().includes("Unauthorized"), "Error message must indicate unauthorized access");
    }

    // Verify property was NOT removed from store
    Property? stillThere = store.getProperty(p.assetTag);
    test:assertTrue(stillThere is Property, "Property must remain intact after unauthorized removal attempt");
}

@test:Config {
    groups: ["store", "remove", "validation"]
}
isolated function testRemovePropertyMismatchedLocationFails() returns error? {
    PropertyStore store = new ();

    Property p = store.addProperty({
        name: "Mountain Vista Lodge",
        location: "Windhoek",
        propertyType: "Lodge",
        pricePerNight: 1500.0,
        hostId: "HOST-002"
    });

    // Attempt removal specifying wrong location
    Property[]|error result = store.removeProperty(p.assetTag, "HOST-002", "Swakopmund");
    test:assertTrue(result is error, "Attempting to remove property with mismatched location must fail");
    if result is error {
        test:assertTrue(result.message().includes("Location mismatch"), "Error message must indicate location mismatch");
    }

    // Verify property was NOT removed
    Property? stillThere = store.getProperty(p.assetTag);
    test:assertTrue(stillThere is Property, "Property must remain intact after location-mismatched removal attempt");
}

@test:Config {
    groups: ["store", "update", "validation"]
}
isolated function testUpdatePropertyWithoutWhitespaceClobbering() returns error? {
    PropertyStore store = new ();

    Property p = store.addProperty({
        name: "Original Name",
        location: "Original Location",
        propertyType: "Original Type",
        pricePerNight: 1000.0,
        hostId: "HOST-003"
    });

    // Update with whitespace strings
    Property updated = check store.updateProperty({
        assetTag: p.assetTag,
        name: "   ",
        location: "   ",
        propertyType: "   "
    });

    // Verify original values are retained rather than replaced by whitespace
    test:assertEquals(updated.name, "Original Name", "Whitespace update must not clobber existing name");
    test:assertEquals(updated.location, "Original Location", "Whitespace update must not clobber existing location");
    test:assertEquals(updated.propertyType, "Original Type", "Whitespace update must not clobber existing type");
}

@test:Config {
    groups: ["store", "update", "validation"]
}
isolated function testUpdatePropertyValidatesStatus() returns error? {
    PropertyStore store = new ();

    Property p = store.addProperty({
        name: "Desert Oasis",
        location: "Sossusvlei",
        propertyType: "Camp",
        pricePerNight: 1200.0,
        hostId: "HOST-004"
    });

    // Valid status updates
    Property updatedMaintenance = check store.updateProperty({
        assetTag: p.assetTag,
        status: "MAINTENANCE"
    });
    test:assertEquals(updatedMaintenance.status, "MAINTENANCE");

    Property updatedAvailable = check store.updateProperty({
        assetTag: p.assetTag,
        status: "available"
    });
    test:assertEquals(updatedAvailable.status, "AVAILABLE");

    // Invalid status update
    Property|error invalidResult = store.updateProperty({
        assetTag: p.assetTag,
        status: "HACKED_STATUS"
    });
    test:assertTrue(invalidResult is error, "Updating with invalid status string must return an error");
}

@test:Config {
    groups: ["store", "update", "validation"]
}
isolated function testUpdatePropertyPriceValidation() returns error? {
    PropertyStore store = new ();

    Property p = store.addProperty({
        name: "Safari Camp",
        location: "Etosha",
        propertyType: "Tent",
        pricePerNight: 800.0,
        hostId: "HOST-005"
    });

    // Negative price update
    Property|error negResult = store.updateProperty({
        assetTag: p.assetTag,
        pricePerNight: -500.0
    });
    test:assertTrue(negResult is error, "Negative price update must return an error");

    // Non-finite price update (NaN)
    Property|error nanResult = store.updateProperty({
        assetTag: p.assetTag,
        pricePerNight: float:NaN
    });
    test:assertTrue(nanResult is error, "NaN price update must return an error");
}

@test:Config {
    groups: ["store", "add", "sanitization"]
}
isolated function testAddPropertyTrimsInputs() returns error? {
    PropertyStore store = new ();

    Property p = store.addProperty({
        name: "  Spacious Loft  ",
        location: "  Windhoek  ",
        propertyType: "  Loft  ",
        pricePerNight: 950.0,
        hostId: "  HOST-006  "
    });

    test:assertEquals(p.name, "Spacious Loft", "Name must be trimmed");
    test:assertEquals(p.location, "Windhoek", "Location must be trimmed");
    test:assertEquals(p.propertyType, "Loft", "Property type must be trimmed");
    test:assertEquals(p.hostId, "HOST-006", "Host ID must be trimmed");
}

