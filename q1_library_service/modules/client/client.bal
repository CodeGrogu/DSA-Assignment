import ballerina/http;
import ballerina/io;

public client class LibraryClient {
    private final http:Client httpClient;

    public isolated function init(string serviceUrl) returns error? {
        self.httpClient = check new (serviceUrl);
    }

    public isolated function getHealth() returns json|error {
        return self.httpClient->/health;
    }
}

public function runCliClient(string[] args) returns error? {
    io:println("Library Management CLI Client");
}
