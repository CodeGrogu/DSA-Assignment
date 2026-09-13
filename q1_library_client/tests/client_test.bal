import ballerina/test;

@test:Config {
    groups: ["client"]
}
function testClientInitialization() returns error? {
    LibraryClient clientInstance = check new ("http://localhost:9090", 5.0);
    test:assertNotEquals(clientInstance, ());
}

@test:Config {
    groups: ["client"]
}
function testCliHelpCommand() returns error? {
    error? result = main("help");
    test:assertEquals(result, ());
}

@test:Config {
    groups: ["client"]
}
function testValidationHelpers() {
    test:assertTrue(isValidAssetStatus("AVAILABLE"));
    test:assertTrue(isValidAssetStatus("UNDER_MAINTENANCE"));
    test:assertFalse(isValidAssetStatus("INVALID_STATUS"));

    test:assertTrue(isValidWorkOrderStatus("OPEN"));
    test:assertTrue(isValidWorkOrderStatus("CLOSED"));
    test:assertFalse(isValidWorkOrderStatus("PENDING"));

    test:assertTrue(isValidIsoDate("2026-09-13"));
    test:assertFalse(isValidIsoDate("13-09-2026"));
    test:assertFalse(isValidIsoDate("invalid-date"));
}
