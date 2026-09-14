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

@test:Config {
    groups: ["service", "validation", "edge_cases"]
}
function testEmptyAssetTagAndDateValidationRejected() returns error? {
    // 1. Empty assetTag rejected
    json emptyTagAsset = {
        assetTag: "   ",
        name: "Blank Tag Asset",
        description: "Should fail validation",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: []
    };
    http:Response res1 = check testClient->/assets.post(emptyTagAsset);
    test:assertEquals(res1.statusCode, 400);

    // 2. Invalid dateAcquired rejected (both bad syntax and calendar impossible)
    json invalidDateAsset = {
        assetTag: "TAG-DATE-BAD",
        name: "Bad Date Asset",
        description: "Should fail validation",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "15/01/2026",
        components: [],
        schedules: [],
        workOrders: []
    };
    http:Response res2 = check testClient->/assets.post(invalidDateAsset);
    test:assertEquals(res2.statusCode, 400);

    json impossibleDateAsset = {
        assetTag: "TAG-DATE-IMPOSSIBLE",
        name: "Impossible Date Asset",
        description: "February 31st does not exist",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-02-31",
        components: [],
        schedules: [],
        workOrders: []
    };
    http:Response res2b = check testClient->/assets.post(impossibleDateAsset);
    test:assertEquals(res2b.statusCode, 400);

    // Empty sub-resource ID validations on asset creation
    json blankCompAsset = {
        assetTag: "TAG-BLANK-SUB-1",
        name: "Blank Comp Asset",
        description: "Testing blank compId",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [{compId: "   ", name: "Bad Comp", description: "Empty id"}],
        schedules: [],
        workOrders: []
    };
    http:Response resBlankComp = check testClient->/assets.post(blankCompAsset);
    test:assertEquals(resBlankComp.statusCode, 400);

    json blankSchedAsset = {
        assetTag: "TAG-BLANK-SUB-2",
        name: "Blank Sched Asset",
        description: "Testing blank scheduleId",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [{scheduleId: "   ", dueDate: "2026-10-01", scheduleType: "INSPECTION", details: "Check"}],
        workOrders: []
    };
    http:Response resBlankSched = check testClient->/assets.post(blankSchedAsset);
    test:assertEquals(resBlankSched.statusCode, 400);

    json blankWoAsset = {
        assetTag: "TAG-BLANK-SUB-3",
        name: "Blank Wo Asset",
        description: "Testing blank orderId",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: [{orderId: "   ", status: "OPEN", description: "Blank WO", tasks: []}]
    };
    http:Response resBlankWo = check testClient->/assets.post(blankWoAsset);
    test:assertEquals(resBlankWo.statusCode, 400);

    json blankTaskAsset = {
        assetTag: "TAG-BLANK-SUB-4",
        name: "Blank Task Asset",
        description: "Testing blank taskId",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: [{orderId: "WO-BLANK-T", status: "OPEN", description: "Blank Task WO", tasks: [{taskId: "  ", description: "Blank", completed: false}]}]
    };
    http:Response resBlankTask = check testClient->/assets.post(blankTaskAsset);
    test:assertEquals(resBlankTask.statusCode, 400);

    // 3. Valid asset creation
    models:Asset validAsset = {
        assetTag: "TAG-VAL-01",
        name: "Valid Asset",
        description: "Proper asset",
        institution: "NUST",
        site: "Main",
        status: "AVAILABLE",
        dateAcquired: "2026-01-15",
        components: [],
        schedules: [],
        workOrders: [
            {
                orderId: "WO-VAL-01",
                status: "OPEN",
                description: "Test order",
                tasks: []
            }
        ]
    };
    http:Response res3 = check testClient->/assets.post(validAsset.toJson());
    test:assertEquals(res3.statusCode, 201);

    // 4. Empty taskId rejected
    json emptyTask = {taskId: "  ", description: "Empty task ID", completed: false};
    http:Response res4 = check testClient->post(string `/assets/TAG-VAL-01/work-orders/WO-VAL-01/tasks`, emptyTask);
    test:assertEquals(res4.statusCode, 400);

    // 5. Invalid currentDate in overdue endpoint rejected
    http:Response res5 = check testClient->get("/assets/overdue?currentDate=invalid-iso-date");
    test:assertEquals(res5.statusCode, 400);

    http:Response cleanup = check testClient->/assets/["TAG-VAL-01"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}

@test:Config {
    groups: ["service", "preservation", "subresources"]
}
function testSubResourcesPreservedOnPutAsset() returns error? {
    models:Asset assetWithSubs = {
        assetTag: "TAG-PRESERVE-01",
        name: "Oscilloscope 5000",
        description: "Dual channel scope",
        institution: "Engineering Faculty",
        site: "Lab 3",
        status: "AVAILABLE",
        dateAcquired: "2026-02-01",
        components: [
            {compId: "PROBE-01", name: "10x Probe", description: "Passive voltage probe"}
        ],
        schedules: [
            {scheduleId: "SCH-CAL-01", dueDate: "2026-08-01", scheduleType: "CALIBRATION", details: "Yearly cal"}
        ],
        workOrders: [
            {orderId: "WO-PRE-01", status: "OPEN", description: "Probe recalibration", tasks: []}
        ]
    };
    http:Response createRes = check testClient->/assets.post(assetWithSubs.toJson());
    test:assertEquals(createRes.statusCode, 201);

    // Update only name and status with empty sub-resource arrays (simulating omitted fields)
    json updatePayload = {
        assetTag: "TAG-PRESERVE-01",
        name: "Oscilloscope 5000 (Calibrated)",
        description: "Dual channel scope",
        institution: "Engineering Faculty",
        site: "Lab 3",
        status: "UNDER_MAINTENANCE",
        dateAcquired: "2026-02-01",
        components: [],
        schedules: [],
        workOrders: []
    };
    json putRes = check testClient->/assets/["TAG-PRESERVE-01"].put(updatePayload);
    models:Asset updated = check putRes.cloneWithType(models:Asset);
    test:assertEquals(updated.name, "Oscilloscope 5000 (Calibrated)");
    test:assertEquals(updated.status, "UNDER_MAINTENANCE");
    // Verify sub-resources were preserved!
    test:assertEquals(updated.components.length(), 1);
    test:assertEquals(updated.components[0].compId, "PROBE-01");
    test:assertEquals(updated.schedules.length(), 1);
    test:assertEquals(updated.schedules[0].scheduleId, "SCH-CAL-01");
    test:assertEquals(updated.workOrders.length(), 1);
    test:assertEquals(updated.workOrders[0].orderId, "WO-PRE-01");

    http:Response cleanup = check testClient->/assets/["TAG-PRESERVE-01"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}

@test:Config {
    groups: ["service", "workorders", "guards"]
}
function testClosedWorkOrderGuards() returns error? {
    models:Asset asset = {
        assetTag: "TAG-GUARD-01",
        name: "Server Rack PSU",
        description: "Redundant power unit",
        institution: "IT Center",
        site: "Data Center",
        status: "AVAILABLE",
        dateAcquired: "2026-01-10",
        components: [],
        schedules: [],
        workOrders: [
            {
                orderId: "WO-GUARD-01",
                status: "OPEN",
                description: "Fan replacement",
                tasks: [
                    {taskId: "T-GUARD-1", description: "Unscrew fan bracket", completed: true}
                ]
            }
        ]
    };
    http:Response createRes = check testClient->/assets.post(asset.toJson());
    test:assertEquals(createRes.statusCode, 201);

    // 1. Close the work order
    json closeRes = check testClient->post("/assets/TAG-GUARD-01/work-orders/WO-GUARD-01/close", ());
    models:WorkOrder closedWo = check closeRes.cloneWithType(models:WorkOrder);
    test:assertEquals(closedWo.status, "CLOSED");

    // 2. Attempt to add a new task to closed work order -> should fail 400
    json newTask = {taskId: "T-GUARD-2", description: "Install new fan", completed: false};
    http:Response addTaskRes = check testClient->post("/assets/TAG-GUARD-01/work-orders/WO-GUARD-01/tasks", newTask);
    test:assertEquals(addTaskRes.statusCode, 400);

    // 3. Attempt to bypass and force CLOSED via PUT work-orders with incomplete tasks -> should fail 400
    models:WorkOrder bypassAttempt = {
        orderId: "WO-GUARD-02",
        status: "CLOSED",
        description: "Bypass test",
        tasks: [
            {taskId: "T-BYPASS", description: "Still active", completed: false}
        ]
    };
    // First create WO-GUARD-02 as OPEN
    models:WorkOrder openWo = {
        orderId: "WO-GUARD-02",
        status: "OPEN",
        description: "Bypass test",
        tasks: [
            {taskId: "T-BYPASS", description: "Still active", completed: false}
        ]
    };
    http:Response createWo2 = check testClient->post("/assets/TAG-GUARD-01/work-orders", openWo.toJson());
    test:assertEquals(createWo2.statusCode, 201);

    // Now attempt to PUT status CLOSED while T-BYPASS is incomplete -> must fail 400
    http:Response putClosedRes = check testClient->put("/assets/TAG-GUARD-01/work-orders/WO-GUARD-02", bypassAttempt.toJson());
    test:assertEquals(putClosedRes.statusCode, 400);

    // 4. Attempt to bypass incomplete task by omitting tasks (tasks: []) in PUT -> must fail 400 and preserve tasks!
    models:WorkOrder emptyTasksBypass = {
        orderId: "WO-GUARD-02",
        status: "CLOSED",
        description: "Bypass test with empty tasks",
        tasks: []
    };
    http:Response putEmptyClosedRes = check testClient->put("/assets/TAG-GUARD-01/work-orders/WO-GUARD-02", emptyTasksBypass.toJson());
    test:assertEquals(putEmptyClosedRes.statusCode, 400);

    // 5. Attempt to modify task on already CLOSED work order (WO-GUARD-01) -> must fail 400
    json modifyTaskPayload = {completed: false};
    http:Response modifyClosedTaskRes = check testClient->patch("/assets/TAG-GUARD-01/work-orders/WO-GUARD-01/tasks/T-GUARD-1", modifyTaskPayload);
    test:assertEquals(modifyClosedTaskRes.statusCode, 400);

    // 6. Attempt to close WO-GUARD-01 a second time -> must fail 400 (already closed)
    http:Response closeAgainRes = check testClient->post("/assets/TAG-GUARD-01/work-orders/WO-GUARD-01/close", ());
    test:assertEquals(closeAgainRes.statusCode, 400);

    // 7. Complete task on WO-GUARD-02 and successfully close via PUT with empty tasks array (preserving completed task)
    http:Response completeTaskRes = check testClient->patch("/assets/TAG-GUARD-01/work-orders/WO-GUARD-02/tasks/T-BYPASS", {completed: true});
    test:assertEquals(completeTaskRes.statusCode, 200);

    json closeWithEmptyTasksRes = check testClient->put("/assets/TAG-GUARD-01/work-orders/WO-GUARD-02", emptyTasksBypass.toJson());
    models:WorkOrder closedWithPreserved = check closeWithEmptyTasksRes.cloneWithType(models:WorkOrder);
    test:assertEquals(closedWithPreserved.status, "CLOSED");
    test:assertEquals(closedWithPreserved.tasks.length(), 1);
    test:assertEquals(closedWithPreserved.tasks[0].taskId, "T-BYPASS");
    test:assertTrue(closedWithPreserved.tasks[0].completed);

    http:Response cleanup = check testClient->/assets/["TAG-GUARD-01"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}

@test:Config {
    groups: ["service", "concurrency", "preservation"]
}
function testConcurrentAssetPutAndSubResourceMutations() returns error? {
    models:Asset baseAsset = {
        assetTag: "TAG-CONCUR-PUT",
        name: "High Precision Balance",
        description: "Analytical balance 0.01mg",
        institution: "Science Faculty",
        site: "Chemistry Lab",
        status: "AVAILABLE",
        dateAcquired: "2026-03-01",
        components: [
            {compId: "PAN-01", name: "Weighing Pan", description: "Stainless steel pan"}
        ],
        schedules: [],
        workOrders: [
            {
                orderId: "WO-CONCUR-1",
                status: "OPEN",
                description: "Calibration order",
                tasks: []
            }
        ]
    };
    http:Response createRes = check testClient->/assets.post(baseAsset.toJson());
    test:assertEquals(createRes.statusCode, 201);

    // 10 concurrent workers: half updating asset status/name, half adding tasks/components
    worker w1 returns error? {
        foreach int i in 1 ... 5 {
            json updatePayload = {
                assetTag: "TAG-CONCUR-PUT",
                name: string `High Precision Balance v${i}`,
                description: "Analytical balance 0.01mg",
                institution: "Science Faculty",
                site: "Chemistry Lab",
                status: "AVAILABLE",
                dateAcquired: "2026-03-01",
                components: [],
                schedules: [],
                workOrders: []
            };
            json _ = check testClient->put("/assets/TAG-CONCUR-PUT", updatePayload);
        }
    }

    worker w2 returns error? {
        foreach int i in 1 ... 5 {
            json task = {taskId: string `TSK-CON-${i}`, description: string `Cal step ${i}`, completed: false};
            http:Response res = check testClient->post("/assets/TAG-CONCUR-PUT/work-orders/WO-CONCUR-1/tasks", task);
            test:assertEquals(res.statusCode, 201);
        }
    }

    worker w3 returns error? {
        foreach int i in 1 ... 5 {
            json comp = {compId: string `DRAFT-SHIELD-${i}`, name: string `Shield ${i}`, description: "Glass draft shield"};
            http:Response res = check testClient->post("/assets/TAG-CONCUR-PUT/components", comp);
            test:assertEquals(res.statusCode, 201);
        }
    }

    check wait w1;
    check wait w2;
    check wait w3;

    // Verify after all concurrency that none of the sub-resources were lost or wiped out!
    json getRes = check testClient->get("/assets/TAG-CONCUR-PUT");
    models:Asset finalAsset = check getRes.cloneWithType(models:Asset);

    // Initial 1 component + 5 added components = 6 components
    test:assertEquals(finalAsset.components.length(), 6, "All 6 components must be preserved under concurrency");
    // Work order should have all 5 tasks intact
    test:assertEquals(finalAsset.workOrders[0].tasks.length(), 5, "All 5 concurrently added tasks must be preserved");

    http:Response cleanup = check testClient->/assets/["TAG-CONCUR-PUT"].delete();
    test:assertEquals(cleanup.statusCode, 200);
}

