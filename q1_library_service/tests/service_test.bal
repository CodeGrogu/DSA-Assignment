import ballerina/http;
import ballerina/test;

import peerpressure/q1_library_service.models;

final http:Client testClient = check new (string `http://localhost:${servicePort}`);

@test:Config {
    groups: ["service", "health"]
}
function testHealthEndpoint() returns error? {
    json response = check testClient->/health;
    test:assertEquals(check response.status, "UP");
    test:assertEquals(check response.'service, "q1_library_service");
}

@test:Config {
    groups: ["service", "catalog"]
}
function testRootEndpoint() returns error? {
    json response = check testClient->get("/");
    test:assertEquals(check response.version, "0.1.0");
    test:assertEquals(check response.'service, "Library & Resource Management System");
}

@test:Config {
    groups: ["service", "crud"]
}

function testCompleteAssetLifecycleAndEndpoints() returns error? {
    // 1. Initial count
    json[] initialAssets = check testClient->/assets;
    int initialCount = initialAssets.length();

    // 2. Create Asset
    models:Asset newAsset = {
        assetTag: "TAG-TEST-001",
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
                dueDate: "2026-05-01",
                scheduleType: "INSPECTION",
                details: "Annual physical condition check"
            }
        ],
        workOrders: []
    };

    http:Response createRes = check testClient->/assets.post(newAsset.toJson());
    test:assertEquals(createRes.statusCode, 201);
    json createdJson = check createRes.getJsonPayload();
    test:assertEquals(check createdJson.assetTag, "TAG-TEST-001");

    // 3. Get Asset by Tag
    json fetchedJson = check testClient->/assets/["TAG-TEST-001"];
    models:Asset fetched = check fetchedJson.cloneWithType(models:Asset);
    test:assertEquals(fetched.assetTag, "TAG-TEST-001");
    test:assertEquals(fetched.name, "Introduction to Distributed Systems");
    test:assertEquals(fetched.status, "AVAILABLE");

    // 4. Update Asset
    models:Asset assetUpdate = {
        assetTag: "TAG-TEST-001",
        name: "Introduction to Distributed Systems (Updated)",
        description: "Updated edition for DSA612S course.",
        institution: "Ministry of Higher Education",
        site: "Main Campus Library",
        status: "LOANED_OUT",
        dateAcquired: "2026-01-15",
        components: fetched.components,
        schedules: fetched.schedules,
        workOrders: []
    };
    json updatedJson = check testClient->/assets/["TAG-TEST-001"].put(assetUpdate.toJson());
    models:Asset updated = check updatedJson.cloneWithType(models:Asset);
    test:assertEquals(updated.status, "LOANED_OUT");
    test:assertEquals(updated.name, "Introduction to Distributed Systems (Updated)");

    // 5. Filter by institution and site
    json[] filtered = check testClient->/assets(institution = "Ministry of Higher Education", site = "Main Campus Library");
    test:assertTrue(filtered.length() >= 1);

    // 6. Get Asset Status
    json statusRes = check testClient->/assets/["TAG-TEST-001"]/status;
    test:assertEquals(check statusRes.assetTag, "TAG-TEST-001");
    test:assertEquals(check statusRes.status, "LOANED_OUT");

    // 7. Add Component sub-resource
    models:Component newComp = {
        compId: "COMP-02",
        name: "Optical Lens Unit",
        description: "High magnification objective lens"
    };
    http:Response addCompRes = check testClient->/assets/["TAG-TEST-001"]/components.post(newComp.toJson());
    test:assertEquals(addCompRes.statusCode, 201);

    // 8. Remove Component sub-resource
    http:Response delCompRes = check testClient->/assets/["TAG-TEST-001"]/components/["COMP-02"].delete();
    test:assertEquals(delCompRes.statusCode, 200);

    // 9. Add Schedule sub-resource
    models:Schedule newSched = {
        scheduleId: "SCH-02",
        dueDate: "2026-04-01",
        scheduleType: "BOOKING",
        details: "Reserved for the Engineering Department"
    };
    http:Response addSchedRes = check testClient->/assets/["TAG-TEST-001"]/schedules.post(newSched.toJson());
    test:assertEquals(addSchedRes.statusCode, 201);

    json bookingStatus = check testClient->/assets/["TAG-TEST-001"]/status;
    test:assertEquals(check bookingStatus.status, "LOANED_OUT");
    json bookingSchedulesJson = check bookingStatus.bookingSchedules;
    json[] bookingSchedules = <json[]>bookingSchedulesJson;
    map<json> booking = <map<json>>bookingSchedules[0];
    test:assertEquals(booking["bookedFor"], "Reserved for the Engineering Department");
    test:assertEquals(booking["until"], "2026-04-01");

    // 10. Query Overdue Assets
    json[] overdue = check testClient->/assets/overdue(currentDate = "2026-06-01");
    test:assertTrue(overdue.length() >= 1);

    // 11. Remove Schedule sub-resource
    http:Response delSchedRes = check testClient->/assets/["TAG-TEST-001"]/schedules/["SCH-02"].delete();
    test:assertEquals(delSchedRes.statusCode, 200);

    // 12. Create Work Order sub-resource
    models:WorkOrder newWo = {
        orderId: "WO-101",
        status: "OPEN",
        description: "Replace worn gear motor assembly",
        tasks: [
            {
                taskId: "TSK-01",
                description: "Disassemble outer casing",
                completed: false
            }
        ]
    };
    http:Response createWoRes = check testClient->post(string `/assets/TAG-TEST-001/work-orders`, newWo.toJson());
    test:assertEquals(createWoRes.statusCode, 201);

    // 13. Update Work Order sub-resource
    models:WorkOrder woUpdate = {
        orderId: "WO-101",
        status: "CLOSED",
        description: "Replace worn gear motor assembly (Resolved)",
        tasks: [
            {
                taskId: "TSK-01",
                description: "Disassemble outer casing",
                completed: true
            }
        ]
    };
    json updatedWoJson = check testClient->put(string `/assets/TAG-TEST-001/work-orders/WO-101`, woUpdate.toJson());
    models:WorkOrder updatedWo = check updatedWoJson.cloneWithType(models:WorkOrder);
    test:assertEquals(updatedWo.status, "CLOSED");

    // 14. Delete Asset
    http:Response delRes = check testClient->/assets/["TAG-TEST-001"].delete();
    test:assertEquals(delRes.statusCode, 200);

    // 15. Verify 404 for deleted asset
    http:Response notFoundRes = check testClient->/assets/["TAG-TEST-001"];
    test:assertEquals(notFoundRes.statusCode, 404);

    // 16. Verify count restored
    json[] remaining = check testClient->/assets;
    test:assertEquals(remaining.length(), initialCount);
}

@test:Config {
    groups: ["service", "workorders", "tasks"]
}
function testAddTaskToWorkOrder() returns error? {
    models:Asset woAsset = {
        assetTag: "TAG-WO-TASK-001",
        name: "3D Printer Test Unit",
        description: "Scratch asset for work order task tests.",
        institution: "Ministry of Higher Education",
        site: "Main Campus Library",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: [
            {
                orderId: "WO-TASK-01",
                status: "OPEN",
                description: "Nozzle heat-bed failure",
                tasks: [
                    {
                        taskId: "T1",
                        description: "Check thermal sensor connectivity.",
                        completed: false
                    }
                ]
            }
        ]
    };
    http:Response createRes = check testClient->/assets.post(woAsset.toJson());
    test:assertEquals(createRes.statusCode, 201);

    models:Task newTask = {
        taskId: "T2",
        description: "Replace nozzle heater cartridge.",
        completed: false
    };
    http:Response addTaskRes = check testClient->post(
        string `/assets/TAG-WO-TASK-001/work-orders/WO-TASK-01/tasks`,
        newTask.toJson()
    );
    test:assertEquals(addTaskRes.statusCode, 201);

    json fetchedJson = check testClient->/assets/["TAG-WO-TASK-001"];
    models:Asset fetched = check fetchedJson.cloneWithType(models:Asset);
    models:WorkOrder wo = fetched.workOrders[0];
    test:assertEquals(wo.tasks.length(), 2);
    test:assertEquals(wo.tasks[1].taskId, "T2");

    http:Response cleanup = check testClient->/assets/["TAG-WO-TASK-001"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}

@test:Config {
    groups: ["service", "workorders", "tasks"]
}
function testMarkTaskCompleted() returns error? {
    models:Asset woAsset = {
        assetTag: "TAG-WO-TASK-002",
        name: "3D Printer Test Unit 2",
        description: "Scratch asset for task completion tests.",
        institution: "Ministry of Higher Education",
        site: "Main Campus Library",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: [
            {
                orderId: "WO-TASK-02",
                status: "OPEN",
                description: "Belt tension issue",
                tasks: [
                    {
                        taskId: "T1",
                        description: "Inspect X-axis belt.",
                        completed: false
                    }
                ]
            }
        ]
    };
    http:Response createRes = check testClient->/assets.post(woAsset.toJson());
    test:assertEquals(createRes.statusCode, 201);

    json patchRes = check testClient->patch(
        string `/assets/TAG-WO-TASK-002/work-orders/WO-TASK-02/tasks/T1`,
        {completed: true}
    );
    models:WorkOrder patchedWo = check patchRes.cloneWithType(models:WorkOrder);
    test:assertEquals(patchedWo.tasks[0].completed, true);

    http:Response cleanup = check testClient->/assets/["TAG-WO-TASK-002"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}

@test:Config {
    groups: ["service", "workorders", "tasks"]
}
function testCloseWorkOrderRequiresAllTasksComplete() returns error? {
    models:Asset woAsset = {
        assetTag: "TAG-WO-TASK-003",
        name: "3D Printer Test Unit 3",
        description: "Scratch asset for close-work-order tests.",
        institution: "Ministry of Higher Education",
        site: "Main Campus Library",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: [
            {
                orderId: "WO-TASK-03",
                status: "OPEN",
                description: "Extruder jam",
                tasks: [
                    {
                        taskId: "T1",
                        description: "Clear filament jam.",
                        completed: false
                    }
                ]
            }
        ]
    };
    http:Response createRes = check testClient->/assets.post(woAsset.toJson());
    test:assertEquals(createRes.statusCode, 201);

    // Attempt to close with an incomplete task — should fail
    http:Response closeFailRes = check testClient->post(
        string `/assets/TAG-WO-TASK-003/work-orders/WO-TASK-03/close`,
        ()
    );
    test:assertEquals(closeFailRes.statusCode, 400);

    // Mark the task complete
    json _ = check testClient->patch(
        string `/assets/TAG-WO-TASK-003/work-orders/WO-TASK-03/tasks/T1`,
        {completed: true}
    );

    // Close again — should succeed
    json closeOkJson = check testClient->post(
        string `/assets/TAG-WO-TASK-003/work-orders/WO-TASK-03/close`,
        ()
    );
    models:WorkOrder closedWo = check closeOkJson.cloneWithType(models:WorkOrder);
    test:assertEquals(closedWo.status, "CLOSED");

    http:Response cleanup = check testClient->/assets/["TAG-WO-TASK-003"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}
