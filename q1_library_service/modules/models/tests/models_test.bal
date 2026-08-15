// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/test;

@test:Config {}
function testAssetRecordCreation() {
    Asset sampleAsset = {
        assetTag: "TAG-001",
        name: "Introduction to Distributed Systems",
        description: "Standard university textbook for DSA612S course.",
        institution: "Ministry of Higher Education",
        site: "Main Campus Library",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [
            {
                compId: "COMP-01",
                name: "Hardcover Binding",
                description: "Reinforced library binding"
            }
        ],
        schedules: [
            {
                scheduleId: "SCH-01",
                dueDate: "2026-12-01",
                scheduleType: "INSPECTION",
                details: "Annual physical condition check"
            }
        ],
        workOrders: []
    };

    test:assertEquals(sampleAsset.assetTag, "TAG-001");
    test:assertEquals(sampleAsset.name, "Introduction to Distributed Systems");
    test:assertEquals(sampleAsset.institution, "Ministry of Higher Education");
    test:assertEquals(sampleAsset.site, "Main Campus Library");
    test:assertEquals(sampleAsset.status, "AVAILABLE");
    test:assertEquals(sampleAsset.dateAcquired, "2026-01-15");
    test:assertEquals(sampleAsset.components.length(), 1);
    test:assertEquals(sampleAsset.schedules.length(), 1);
    test:assertEquals(sampleAsset.workOrders.length(), 0);
}

@test:Config {}
function testJsonDeserializationAndRoundTrip() returns error? {
    json rawJson = {
        "assetTag": "TAG-002",
        "name": "3D Printer Core Unit",
        "description": "High-precision additive manufacturing unit.",
        "institution": "Polytechnic Institute",
        "site": "Engineering Lab 3",
        "status": "UNDER_MAINTENANCE",
        "dateAcquired": "2026-03-20",
        "components": [
            {
                "compId": "COMP-02",
                "name": "Nozzle Unit",
                "description": "0.4mm brass extrusion nozzle"
            }
        ],
        "schedules": [
            {
                "scheduleId": "SCH-02",
                "dueDate": "2026-10-15",
                "scheduleType": "CALIBRATION",
                "details": "Monthly bed levelling and extruder calibration"
            }
        ],
        "workOrders": [
            {
                "orderId": "WO-101",
                "status": "OPEN",
                "description": "Nozzle heating element replacement",
                "compId": "COMP-02",
                "tasks": [
                    {
                        "taskId": "TSK-01",
                        "description": "Order replacement nozzle",
                        "completed": true
                    },
                    {
                        "taskId": "TSK-02",
                        "description": "Install and test thermal runaway",
                        "completed": false
                    }
                ]
            }
        ]
    };

    // Deserialise JSON to Asset record
    Asset asset = check rawJson.cloneWithType(Asset);
    test:assertEquals(asset.assetTag, "TAG-002");
    test:assertEquals(asset.status, "UNDER_MAINTENANCE");
    test:assertEquals(asset.components.length(), 1);
    test:assertEquals(asset.schedules.length(), 1);
    test:assertEquals(asset.workOrders.length(), 1);
    test:assertEquals(asset.workOrders[0].orderId, "WO-101");
    test:assertEquals(asset.workOrders[0].compId, "COMP-02");
    test:assertEquals(asset.workOrders[0].tasks.length(), 2);
    test:assertTrue(asset.workOrders[0].tasks[0].completed);
    test:assertFalse(asset.workOrders[0].tasks[1].completed);

    // Serialise back to JSON and confirm identity
    json serializedJson = asset.toJson();
    Asset roundTripAsset = check serializedJson.cloneWithType(Asset);
    test:assertEquals(roundTripAsset.assetTag, asset.assetTag);
    test:assertEquals(roundTripAsset.name, asset.name);
    test:assertEquals(roundTripAsset.status, asset.status);
}

@test:Config {}
function testStatusValidators() {
    // Valid lifecycle states
    test:assertTrue(isValidAssetStatus("AVAILABLE"));
    test:assertTrue(isValidAssetStatus("LOANED_OUT"));
    test:assertTrue(isValidAssetStatus("OCCUPIED"));
    test:assertTrue(isValidAssetStatus("UNDER_MAINTENANCE"));
    test:assertTrue(isValidAssetStatus("DISPOSED"));

    // Invalid states
    test:assertFalse(isValidAssetStatus("BROKEN"));
    test:assertFalse(isValidAssetStatus("UNKNOWN"));
    test:assertFalse(isValidAssetStatus("available")); // case-sensitive
    test:assertFalse(isValidAssetStatus(""));
}

@test:Config {}
function testWorkOrderStatusValidators() {
    test:assertTrue(isValidWorkOrderStatus("OPEN"));
    test:assertTrue(isValidWorkOrderStatus("IN_PROGRESS"));
    test:assertTrue(isValidWorkOrderStatus("CLOSED"));

    test:assertFalse(isValidWorkOrderStatus("PENDING"));
    test:assertFalse(isValidWorkOrderStatus("RESOLVED"));
    test:assertFalse(isValidWorkOrderStatus(""));
}

@test:Config {}
function testIsoDateValidator() {
    test:assertTrue(isValidIsoDate("2026-08-16"));
    test:assertTrue(isValidIsoDate("2026-01-01"));
    test:assertTrue(isValidIsoDate("2025-12-31"));

    test:assertFalse(isValidIsoDate("16-08-2026"));
    test:assertFalse(isValidIsoDate("2026/08/16"));
    test:assertFalse(isValidIsoDate("2026-8-16"));
    test:assertFalse(isValidIsoDate("invalid-date"));
    test:assertFalse(isValidIsoDate(""));
}

@test:Config {}
function testSubRecordDefaults() {
    Task task = {
        taskId: "TSK-99",
        description: "Verify power supply stability"
    };
    test:assertFalse(task.completed, "Default task completion flag must be false");

    WorkOrder workOrder = {
        orderId: "WO-999",
        status: "OPEN",
        description: "Routine inspection"
    };
    test:assertEquals(workOrder.tasks.length(), 0, "Default task list must be empty");
    test:assertEquals(workOrder.compId, (), "Optional compId should default to nil");
}
