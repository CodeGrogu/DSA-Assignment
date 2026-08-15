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
    test:assertEquals(sampleAsset.status, "AVAILABLE");
    test:assertEquals(sampleAsset.components.length(), 1);
    test:assertEquals(sampleAsset.schedules.length(), 1);
}

@test:Config {}
function testJsonDeserialization() returns error? {
    json rawJson = {
        "assetTag": "TAG-002",
        "name": "3D Printer Core Unit",
        "description": "High-precision additive manufacturing unit.",
        "institution": "Polytechnic Institute",
        "site": "Engineering Lab 3",
        "status": "UNDER_MAINTENANCE",
        "dateAcquired": "2026-03-20",
        "components": [],
        "schedules": [],
        "workOrders": [
            {
                "orderId": "WO-101",
                "status": "OPEN",
                "description": "Nozzle heating element replacement",
                "tasks": [
                    {
                        "taskId": "TSK-01",
                        "description": "Order replacement nozzle",
                        "completed": true
                    }
                ]
            }
        ]
    };

    Asset asset = check rawJson.cloneWithType(Asset);
    test:assertEquals(asset.assetTag, "TAG-002");
    test:assertEquals(asset.status, "UNDER_MAINTENANCE");
    test:assertEquals(asset.workOrders.length(), 1);
    test:assertEquals(asset.workOrders[0].tasks.length(), 1);
    test:assertTrue(asset.workOrders[0].tasks[0].completed);
}
