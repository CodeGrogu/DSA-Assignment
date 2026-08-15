import ballerina/test;

@test:Config {}
function testClientInitialization() returns error? {
    LibraryClient clientInstance = check new ("http://localhost:9090");
    test:assertNotEquals(clientInstance, ());
}
