// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/test;

@test:Config {}
function testClientInitialization() returns error? {
    LibraryClient clientInstance = check new ("http://localhost:9090");
    test:assertNotEquals(clientInstance, ());
}
