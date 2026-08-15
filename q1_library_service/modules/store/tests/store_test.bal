import ballerina/test;

import peerpressure/q1_library_service.models;

@test:Config {}
function testAssetStoreCrudOperations() returns error? {
    models:Asset sampleAsset = {
        assetTag: "TAG-TEST-99",
        name: "Test Asset",
        description: "Temporary asset for store testing.",
        institution: "Test Inst",
        site: "Test Site",
        status: "AVAILABLE",
        dateAcquired: "2026-01-01",
        components: [],
        schedules: [],
        workOrders: []
    };

    check addAsset(sampleAsset);

    models:Asset? retrieved = getAsset("TAG-TEST-99");
    test:assertNotEquals(retrieved, ());
    if retrieved is models:Asset {
        test:assertEquals(retrieved.name, "Test Asset");
    }

    test:assertTrue(deleteAsset("TAG-TEST-99"));
    test:assertEquals(getAsset("TAG-TEST-99"), ());
}
