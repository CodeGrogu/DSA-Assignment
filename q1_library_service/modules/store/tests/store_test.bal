import ballerina/test;

import peerpressure/q1_library_service.models;

function createTestAsset(string tag, string institution = "Ministry of Education", string site = "Main Library") returns models:Asset {
    return {
        assetTag: tag,
        name: string `Asset ${tag}`,
        description: string `Description for ${tag}`,
        institution: institution,
        site: site,
        status: "AVAILABLE",
        dateAcquired: "2026-01-01",
        components: [],
        schedules: [],
        workOrders: []
    };
}

@test:BeforeEach
function beforeEachTest() {
    resetStore();
}

@test:Config {}
function testStoreBasicCrud() returns error? {
    models:Asset asset = createTestAsset("TAG-CRUD-01");
    check addAsset(asset);

    models:Asset? retrieved = getAsset("TAG-CRUD-01");
    test:assertNotEquals(retrieved, ());
    if retrieved is models:Asset {
        test:assertEquals(retrieved.name, "Asset TAG-CRUD-01");
        test:assertEquals(retrieved.status, "AVAILABLE");
    }

    models:Asset updatedAsset = {
        assetTag: "TAG-CRUD-01",
        name: "Updated Asset Name",
        description: "Updated description",
        institution: "Ministry of Education",
        site: "Main Library",
        status: "LOANED_OUT",
        dateAcquired: "2026-01-01",
        components: [],
        schedules: [],
        workOrders: []
    };
    check updateAsset(updatedAsset);

    models:Asset? postUpdate = getAsset("TAG-CRUD-01");
    test:assertNotEquals(postUpdate, ());
    if postUpdate is models:Asset {
        test:assertEquals(postUpdate.name, "Updated Asset Name");
        test:assertEquals(postUpdate.status, "LOANED_OUT");
    }

    test:assertTrue(deleteAsset("TAG-CRUD-01"));
    test:assertEquals(getAsset("TAG-CRUD-01"), ());
}

@test:Config {}
function testGetAllAssetsOnEmptyStore() {
    models:Asset[] assets = getAllAssets();
    test:assertEquals(assets.length(), 0);
}

@test:Config {}
function testDuplicateAssetTagRejection() returns error? {
    models:Asset asset1 = createTestAsset("TAG-DUP-01");
    check addAsset(asset1);

    models:Asset asset2 = createTestAsset("TAG-DUP-01");
    error? result = addAsset(asset2);
    test:assertTrue(result is error, "Adding duplicate assetTag must return an error");
}

@test:Config {}
function testNonExistentAssetOperations() {
    test:assertEquals(getAsset("TAG-NON-EXISTENT"), ());
    test:assertFalse(deleteAsset("TAG-NON-EXISTENT"));

    models:Asset dummy = createTestAsset("TAG-NON-EXISTENT");
    error? updateResult = updateAsset(dummy);
    test:assertTrue(updateResult is error, "Updating non-existent asset must return error");
}

@test:Config {}
function testFilterAssets() returns error? {
    check addAsset(createTestAsset("TAG-F1", "Ministry of Higher Education", "North Campus"));
    check addAsset(createTestAsset("TAG-F2", "Ministry of Higher Education", "South Campus"));
    check addAsset(createTestAsset("TAG-F3", "Polytechnic Institute", "North Campus"));
    check addAsset(createTestAsset("TAG-F4", "Polytechnic Institute", "East Campus"));

    // Filter by institution only
    models:Asset[] mheAssets = filterAssets("Ministry of Higher Education", ());
    test:assertEquals(mheAssets.length(), 2);

    // Filter by site only
    models:Asset[] northAssets = filterAssets((), "North Campus");
    test:assertEquals(northAssets.length(), 2);

    // Filter by both institution and site
    models:Asset[] mheNorth = filterAssets("Ministry of Higher Education", "North Campus");
    test:assertEquals(mheNorth.length(), 1);
    test:assertEquals(mheNorth[0].assetTag, "TAG-F1");

    // Filter with no parameters (returns all)
    models:Asset[] all = filterAssets((), ());
    test:assertEquals(all.length(), 4);
}

@test:Config {}
function testOverdueAssetsDetection() returns error? {
    models:Asset overdueAsset = {
        assetTag: "TAG-OVERDUE-01",
        name: "Microscope A1",
        description: "Optical microscope",
        institution: "Science Dept",
        site: "Lab 1",
        status: "AVAILABLE",
        dateAcquired: "2025-01-01",
        components: [],
        schedules: [
            {
                scheduleId: "SCH-PAST",
                dueDate: "2026-01-15",
                scheduleType: "MAINTENANCE",
                details: "Annual lens service"
            }
        ],
        workOrders: []
    };

    models:Asset futureAsset = {
        assetTag: "TAG-FUTURE-01",
        name: "Spectrometer B2",
        description: "Digital spectrometer",
        institution: "Science Dept",
        site: "Lab 2",
        status: "AVAILABLE",
        dateAcquired: "2025-06-01",
        components: [],
        schedules: [
            {
                scheduleId: "SCH-FUTURE",
                dueDate: "2026-12-31",
                scheduleType: "CALIBRATION",
                details: "End of year calibration"
            }
        ],
        workOrders: []
    };

    check addAsset(overdueAsset);
    check addAsset(futureAsset);

    models:Asset[] overdueList = getOverdueAssets("2026-08-16");
    test:assertEquals(overdueList.length(), 1);
    test:assertEquals(overdueList[0].assetTag, "TAG-OVERDUE-01");
    test:assertEquals(overdueList[0].schedules.length(), 1);
    test:assertEquals(overdueList[0].schedules[0].scheduleId, "SCH-PAST");
    test:assertEquals(overdueList[0].schedules[0].dueDate, "2026-01-15");
}

@test:Config {}
function testComponentSubResourceOperations() returns error? {
    check addAsset(createTestAsset("TAG-COMP-01"));

    models:Component comp1 = {
        compId: "C-01",
        name: "Laser Module",
        description: "5mW diode laser"
    };

    check addComponent("TAG-COMP-01", comp1);
    models:Asset? asset = getAsset("TAG-COMP-01");
    test:assertNotEquals(asset, ());
    if asset is models:Asset {
        test:assertEquals(asset.components.length(), 1);
        test:assertEquals(asset.components[0].compId, "C-01");
    }

    // Duplicate component id
    error? dupComp = addComponent("TAG-COMP-01", comp1);
    test:assertTrue(dupComp is error, "Duplicate component ID should return error");

    // Remove component
    check removeComponent("TAG-COMP-01", "C-01");
    models:Asset? postRemove = getAsset("TAG-COMP-01");
    if postRemove is models:Asset {
        test:assertEquals(postRemove.components.length(), 0);
    }

    // Removing non-existent component
    error? remNonExist = removeComponent("TAG-COMP-01", "C-NON-EXIST");
    test:assertTrue(remNonExist is error);
}

@test:Config {}
function testScheduleSubResourceOperations() returns error? {
    check addAsset(createTestAsset("TAG-SCHED-01"));

    models:Schedule schedule1 = {
        scheduleId: "SCH-100",
        dueDate: "2026-10-01",
        scheduleType: "INSPECTION",
        details: "Q4 Safety Inspection"
    };

    check addSchedule("TAG-SCHED-01", schedule1);
    models:Asset? asset = getAsset("TAG-SCHED-01");
    if asset is models:Asset {
        test:assertEquals(asset.schedules.length(), 1);
        test:assertEquals(asset.schedules[0].scheduleId, "SCH-100");
    }

    // Duplicate schedule id
    error? dupSched = addSchedule("TAG-SCHED-01", schedule1);
    test:assertTrue(dupSched is error);

    // Remove schedule
    check removeSchedule("TAG-SCHED-01", "SCH-100");
    models:Asset? postRemove = getAsset("TAG-SCHED-01");
    if postRemove is models:Asset {
        test:assertEquals(postRemove.schedules.length(), 0);
    }
}

@test:Config {}
function testWorkOrderSubResourceOperations() returns error? {
    check addAsset(createTestAsset("TAG-WO-01"));

    models:WorkOrder wo = {
        orderId: "WO-500",
        status: "OPEN",
        description: "Power supply fan issue",
        tasks: [
            {
                taskId: "T-1",
                description: "Inspect bearings",
                completed: false
            }
        ]
    };

    check createWorkOrder("TAG-WO-01", wo);
    models:Asset? asset = getAsset("TAG-WO-01");
    if asset is models:Asset {
        test:assertEquals(asset.workOrders.length(), 1);
        test:assertEquals(asset.workOrders[0].status, "OPEN");
    }

    // Update work order
    models:WorkOrder updatedWo = {
        orderId: "WO-500",
        status: "CLOSED",
        description: "Power supply fan issue resolved",
        tasks: [
            {
                taskId: "T-1",
                description: "Inspect bearings",
                completed: true
            }
        ]
    };
    check updateWorkOrder("TAG-WO-01", updatedWo);

    models:Asset? postUpdate = getAsset("TAG-WO-01");
    if postUpdate is models:Asset {
        test:assertEquals(postUpdate.workOrders[0].status, "CLOSED");
        test:assertTrue(postUpdate.workOrders[0].tasks[0].completed);
    }
}

@test:Config {}
function testConcurrentStoreAccess() returns error? {
    worker w1 returns error? {
        foreach int i in 1 ..< 20 {
            models:Asset a = createTestAsset(string `TAG-CONC-A-${i}`);
            check addAsset(a);
        }
    }

    worker w2 returns error? {
        foreach int i in 1 ..< 20 {
            models:Asset b = createTestAsset(string `TAG-CONC-B-${i}`);
            check addAsset(b);
        }
    }

    worker w3 returns error? {
        foreach int i in 1 ..< 20 {
            _ = getAllAssets();
            _ = filterAssets("Ministry of Education", ());
        }
    }

    check wait w1;
    check wait w2;
    check wait w3;

    models:Asset[] all = getAllAssets();
    test:assertEquals(all.length(), 38);
}
