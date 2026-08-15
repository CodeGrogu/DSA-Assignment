// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/http;
import ballerina/test;

final http:Client testClient = check new (string `http://localhost:${servicePort}`);

@test:Config {}
function testHealthEndpoint() returns error? {
    json response = check testClient->/health;
    test:assertEquals(check response.status, "UP");
}

@test:Config {}
function testRootEndpoint() returns error? {
    json response = check testClient->get("/");
    test:assertEquals(check response.version, "0.1.0");
}

@test:Config {}
function testGetAssetsEmpty() returns error? {
    json[] assets = check testClient->/assets;
    test:assertEquals(assets.length(), 0);
}
