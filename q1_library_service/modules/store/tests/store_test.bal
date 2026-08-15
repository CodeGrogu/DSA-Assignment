// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/test;

import peerpressure/q1_library_service.models;

@test:Config {}
function testAssetStoreCrudOperations() returns error? {
    AssetStore store = new ();

    models:Asset testAsset = {
        assetTag: "TAG-TEST-001",
        name: "Test Lab Microscope",
        description: "Optical microscope for biology department.",
        institution: "National University",
        site: "North Campus Lab",
        status: "AVAILABLE",
        dateAcquired: "2026-02-10",
        components: [],
        schedules: [],
        workOrders: []
    };

    // 1. Test Add
    DuplicateAssetError? addResult = store.addAsset(testAsset);
    test:assertTrue(addResult is ());

    // 2. Test Duplicate Add Rejection
    DuplicateAssetError? duplicateResult = store.addAsset(testAsset);
    test:assertTrue(duplicateResult is DuplicateAssetError);

    // 3. Test Get
    models:Asset|AssetNotFoundError retrieved = store.getAsset("TAG-TEST-001");
    test:assertTrue(retrieved is models:Asset);
    if retrieved is models:Asset {
        test:assertEquals(retrieved.name, "Test Lab Microscope");
        test:assertEquals(retrieved.status, "AVAILABLE");
    }

    // 4. Test Update
    models:Asset updatedAsset = {
        assetTag: "TAG-TEST-001",
        name: "Test Lab Microscope (Calibrated)",
        description: "Optical microscope for biology department.",
        institution: "National University",
        site: "North Campus Lab",
        status: "LOANED_OUT",
        dateAcquired: "2026-02-10",
        components: [],
        schedules: [],
        workOrders: []
    };
    AssetNotFoundError? updateResult = store.updateAsset("TAG-TEST-001", updatedAsset);
    test:assertTrue(updateResult is ());

    models:Asset|AssetNotFoundError postUpdate = store.getAsset("TAG-TEST-001");
    test:assertTrue(postUpdate is models:Asset);
    if postUpdate is models:Asset {
        test:assertEquals(postUpdate.status, "LOANED_OUT");
    }

    // 5. Test Delete
    models:Asset|AssetNotFoundError deleted = store.deleteAsset("TAG-TEST-001");
    test:assertTrue(deleted is models:Asset);

    // 6. Verify NotFound after deletion
    models:Asset|AssetNotFoundError postDelete = store.getAsset("TAG-TEST-001");
    test:assertTrue(postDelete is AssetNotFoundError);
}
