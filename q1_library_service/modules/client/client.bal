// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/http;
import ballerina/io;

import peerpressure/q1_library_service.models;

# Client helper for interacting with the Library & Resource Management REST API.
public client class LibraryClient {
    private final http:Client httpClient;

    # Initialises a new LibraryClient instance.
    #
    # + serviceUrl - Base URL of the REST service (e.g. `http://localhost:9090`)
    # + return - Error if client initialisation fails
    public function init(string serviceUrl = "http://localhost:9090") returns error? {
        self.httpClient = check new (serviceUrl);
    }

    # Fetches all assets across the ministry.
    #
    # + return - Array of assets or error
    public function getAssets() returns models:Asset[]|error {
        return check self.httpClient->/assets;
    }

    # Fetches a single asset by its unique assetTag.
    #
    # + assetTag - Unique asset identifier
    # + return - Matching Asset record or error
    public function getAsset(string assetTag) returns models:Asset|error {
        return check self.httpClient->/assets/[assetTag];
    }
}

# Entrypoint for running the CLI client interface.
#
# + serviceUrl - Target REST API base URL
# + return - Error if execution fails
public function runCliClient(string serviceUrl = "http://localhost:9090") returns error? {
    io:println("==================================================================");
    io:println("  Library & Resource Management System — CLI Client Interface     ");
    io:println("  Connecting to: " + serviceUrl);
    io:println("==================================================================");
    LibraryClient _ = check new (serviceUrl);
    io:println("CLI Client initialised successfully.");
    return ();
}
