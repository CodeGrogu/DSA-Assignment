import ballerina/test;

@test:Config {
    groups: ["client"]
}
function testClientInitialization() returns error? {
    LibraryClient clientInstance = check new ("http://localhost:9090");
    test:assertNotEquals(clientInstance, ());
}

@test:Config {
    groups: ["client"]
}
function testCliClientInvocationNoArgs() returns error? {
    error? result = runCliClient([]);
    test:assertEquals(result, ());
}

@test:Config {
    groups: ["client"]
}
function testCliClientInvocationUnknownCommand() returns error? {
    error? result = runCliClient(["http://localhost:9090", "unknown-cmd"]);
    test:assertEquals(result, ());
}
