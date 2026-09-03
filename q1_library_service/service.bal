import ballerina/http;
import ballerina/log;
import ballerina/time;

import peerpressure/q1_library_service.models;
import peerpressure/q1_library_service.store;

configurable int servicePort = 9090;

listener http:Listener httpListener = new (servicePort);

# REST API Service for Library & Resource Management System.
service / on httpListener {

    # Service lifecycle initializer.
    function init() {
        log:printInfo(string `Library & Resource Management System REST Service started on port ${servicePort}`);
    }

    # Health check endpoint.
    # + return - Current operational status and timestamp.
    resource function get health() returns json {
        [int, decimal] [currentTime, _] = time:utcNow();
        return {
            status: "UP",
            timestamp: currentTime,
            'service: "q1_library_service"
        };
    }

    # API catalog root discovery endpoint.
    # + return - Service catalog metadata and route list.
    resource function get .() returns json {
        return {
            'service: "Library & Resource Management System",
            version: "0.1.0",
            endpoints: [
                "/health",
                "/assets",
                "/assets/{assetTag}",
                "/assets/{assetTag}/status",
                "/assets/overdue",
                "/assets/{assetTag}/components",
                "/assets/{assetTag}/components/{compId}",
                "/assets/{assetTag}/schedules",
                "/assets/{assetTag}/schedules/{scheduleId}",
                "/assets/{assetTag}/work-orders",
                "/assets/{assetTag}/work-orders/{orderId}",
                "/assets/{assetTag}/work-orders/{orderId}/tasks",
                "/assets/{assetTag}/work-orders/{orderId}/tasks/{taskId}",
                "/assets/{assetTag}/work-orders/{orderId}/close"
            ]
        };
    }

    # Retrieves all assets with optional filtering by institution and site.
    # + institution - Optional filter by owning institution
    # + site - Optional filter by campus site
    # + return - JSON array of matching asset records
    @http:ResourceConfig {
        produces: ["application/json"]
    }
    resource function get assets(string? institution, string? site) returns json {
        if institution is string || site is string {
            return store:filterAssets(institution, site).toJson();
        }
        return store:getAllAssets().toJson();
    }

    # Registers a new asset in the system.
    # + payload - Complete asset record payload
    # + return - Created asset record (201),Bad request (400) or Conflict(409)
  resource function post assets(@http:Payload models:Asset payload) returns http:Created|http:BadRequest|http:Conflict {
    error? result = store:addAsset(payload);

    if result is error {
        string msg = result.message();

        if msg.includes("already exists") {
            return <http:Conflict>{
                body: {
                    timestamp: time:utcToString(time:utcNow()),
                    status: 409,
                    reason: "Conflict",
                    message: msg,
                    path: "/assets"
                }
            };
        }

        return <http:BadRequest>{
            body: {
                timestamp: time:utcToString(time:utcNow()),
                status: 400,
                reason: "Bad Request",
                message: msg,
                path: "/assets"
            }
        };
    }

    return <http:Created>{body: payload.toJson()};
}
    # Retrieves a single asset by unique asset tag.
    # + assetTag - Unique asset tag
    # + return - Asset record (200) or 404 Not Found
    resource function get assets/[string assetTag]() returns json|http:NotFound {
        models:Asset? asset = store:getAsset(assetTag);
        if asset is () {
            return <http:NotFound>{
                body: {
                    message: string `Asset with tag '${assetTag}' not found.`
                }
            };
        }
        return asset.toJson();
    }

    # Updates an existing asset.
    # + assetTag - Unique asset tag
    # + payload - Updated asset record
    # + return - Updated asset record (200) or error response
    resource function put assets/[string assetTag](@http:Payload models:Asset payload) returns json|http:NotFound|http:BadRequest {
        models:Asset updatedAsset = payload;
        if updatedAsset.assetTag != assetTag {
            updatedAsset = {
                assetTag: assetTag,
                name: payload.name,
                description: payload.description,
                institution: payload.institution,
                site: payload.site,
                status: payload.status,
                dateAcquired: payload.dateAcquired,
                components: payload.components,
                schedules: payload.schedules,
                workOrders: payload.workOrders
            };
        }
        error? result = store:updateAsset(updatedAsset);
        if result is error {
            return <http:NotFound>{
                body: {
                    message: result.message()
                }
            };
        }
        return updatedAsset.toJson();
    }

    # Deletes an asset by unique asset tag.
    # + assetTag - Unique asset tag
    # + return - Confirmation message (200) or 404 Not Found
    resource function delete assets/[string assetTag]() returns json|http:NotFound {
        boolean deleted = store:deleteAsset(assetTag);
        if !deleted {
            return <http:NotFound>{
                body: {
                    message: string `Asset with tag '${assetTag}' not found.`
                }
            };
        }
        return {
            message: string `Asset '${assetTag}' deleted successfully.`,
            assetTag: assetTag
        };
    }

    # Retrieves operational status and active work orders for an asset.
    # + assetTag - Unique asset tag
    # + return - Status summary (200) or 404 Not Found
    resource function get assets/[string assetTag]/status() returns json|http:NotFound {
        models:Asset? asset = store:getAsset(assetTag);
        if asset is () {
            return <http:NotFound>{
                body: {
                    message: string `Asset with tag '${assetTag}' not found.`
                }
            };
        }
        models:WorkOrder[] active = [];
        foreach models:WorkOrder wo in asset.workOrders {
            if wo.status != "CLOSED" {
                active.push(wo);
            }
        }
        return {
            assetTag: asset.assetTag,
            name: asset.name,
            status: asset.status,
            schedules: asset.schedules.toJson(),
            activeWorkOrders: active.toJson()
        };
    }

    # Retrieves all assets with overdue maintenance or booking schedules.
    # + currentDate - Optional ISO comparison date (defaults to current UTC date)
    # + return - Array of assets with overdue schedules
    resource function get assets/overdue(string? currentDate) returns json {
        string dateToCompare = currentDate ?: "2026-12-31";
        return store:getOverdueAssets(dateToCompare).toJson();
    }

    # Attaches a new component sub-resource to an asset.
    # + assetTag - Unique asset tag
    # + component - Component payload
    # + return - Created component (201) or error response
    resource function post assets/[string assetTag]/components(@http:Payload models:Component component) returns http:Created|http:NotFound|http:BadRequest {
        error? result = store:addComponent(assetTag, component);
        if result is error {
            string msg = result.message();
            if msg.includes("does not exist") {
                return <http:NotFound>{body: {message: msg}};
            }
            return <http:BadRequest>{body: {message: msg}};
        }
        return <http:Created>{body: component.toJson()};
    }

    # Removes a component sub-resource from an asset.
    # + assetTag - Unique asset tag
    # + compId - Unique component identifier
    # + return - Confirmation message (200) or error response
    resource function delete assets/[string assetTag]/components/[string compId]() returns json|http:NotFound {
        error? result = store:removeComponent(assetTag, compId);
        if result is error {
            return <http:NotFound>{body: {message: result.message()}};
        }
        return {
            message: string `Component '${compId}' removed successfully from asset '${assetTag}'.`
        };
    }

    # Attaches a maintenance/booking schedule to an asset.
    # + assetTag - Unique asset tag
    # + schedule - Schedule payload
    # + return - Created schedule (201) or error response
    resource function post assets/[string assetTag]/schedules(@http:Payload models:Schedule schedule) returns http:Created|http:NotFound|http:BadRequest {
        error? result = store:addSchedule(assetTag, schedule);
        if result is error {
            string msg = result.message();
            if msg.includes("does not exist") {
                return <http:NotFound>{body: {message: msg}};
            }
            return <http:BadRequest>{body: {message: msg}};
        }
        return <http:Created>{body: schedule.toJson()};
    }

    # Removes a schedule sub-resource from an asset.
    # + assetTag - Unique asset tag
    # + scheduleId - Unique schedule identifier
    # + return - Confirmation message (200) or error response
    resource function delete assets/[string assetTag]/schedules/[string scheduleId]() returns json|http:NotFound {
        error? result = store:removeSchedule(assetTag, scheduleId);
        if result is error {
            return <http:NotFound>{body: {message: result.message()}};
        }
        return {
            message: string `Schedule '${scheduleId}' removed successfully from asset '${assetTag}'.`
        };
    }

    # Creates a new maintenance work order for an asset.
    # + assetTag - Unique asset tag
    # + workOrder - Work order payload
    # + return - Created work order (201) or error response
    resource function post assets/[string assetTag]/work\-orders(@http:Payload models:WorkOrder workOrder) returns http:Created|http:NotFound|http:BadRequest {
        error? result = store:createWorkOrder(assetTag, workOrder);
        if result is error {
            string msg = result.message();
            if msg.includes("does not exist") {
                return <http:NotFound>{body: {message: msg}};
            }
            return <http:BadRequest>{body: {message: msg}};
        }
        return <http:Created>{body: workOrder.toJson()};
    }

    # Updates an existing work order on an asset.
    # + assetTag - Unique asset tag
    # + orderId - Unique work order identifier
    # + workOrder - Updated work order payload
    # + return - Updated work order (200) or error response
    resource function put assets/[string assetTag]/work\-orders/[string orderId](@http:Payload models:WorkOrder workOrder) returns json|http:NotFound|http:BadRequest {
        models:WorkOrder woToUpdate = workOrder;
        if woToUpdate.orderId != orderId {
            woToUpdate = {
                orderId: orderId,
                status: workOrder.status,
                description: workOrder.description,
                compId: workOrder.compId,
                tasks: workOrder.tasks
            };
        }
        error? result = store:updateWorkOrder(assetTag, woToUpdate);
        if result is error {
            return <http:NotFound>{body: {message: result.message()}};
        }
        return woToUpdate.toJson();
    }

    # Adds a sub-task to an existing work order.
    # + assetTag - Unique asset tag
    # + orderId - Unique work order identifier
    # + task - New task payload
    # + return - Created task (201) or error response
    resource function post assets/[string assetTag]/work\-orders/[string orderId]/tasks(@http:Payload models:Task task) returns http:Created|http:NotFound|http:BadRequest {
        models:Asset? asset = store:getAsset(assetTag);
        if asset is () {
            return <http:NotFound>{body: {message: string `Asset with tag '${assetTag}' not found.`}};
        }
        int? idx = ();
        foreach int i in 0 ..< asset.workOrders.length() {
            if asset.workOrders[i].orderId == orderId {
                idx = i;
                break;
            }
        }
        if idx is () {
            return <http:NotFound>{body: {message: string `Work order '${orderId}' not found on asset '${assetTag}'.`}};
        }
        models:WorkOrder wo = asset.workOrders[idx];
        foreach models:Task t in wo.tasks {
            if t.taskId == task.taskId {
                return <http:BadRequest>{body: {message: string `Task '${task.taskId}' already exists on work order '${orderId}'.`}};
            }
        }
        models:Task[] updatedTasks = [];
        foreach models:Task t in wo.tasks {
            updatedTasks.push(t);
        }
        updatedTasks.push(task);

        models:WorkOrder updatedWo = {
            orderId: wo.orderId,
            status: wo.status,
            description: wo.description,
            compId: wo.compId,
            tasks: updatedTasks
        };
        error? result = store:updateWorkOrder(assetTag, updatedWo);
        if result is error {
            return <http:BadRequest>{body: {message: result.message()}};
        }
        return <http:Created>{body: task.toJson()};
    }

    # Updates a sub-task's completion status within a work order.
    # + assetTag - Unique asset tag
    # + orderId - Unique work order identifier
    # + taskId - Unique task identifier
    # + payload - New completion state
    # + return - Updated work order (200) or error response
    resource function patch assets/[string assetTag]/work\-orders/[string orderId]/tasks/[string taskId](@http:Payload record {|boolean completed;|} payload) returns json|http:NotFound {
        models:Asset? asset = store:getAsset(assetTag);
        if asset is () {
            return <http:NotFound>{body: {message: string `Asset with tag '${assetTag}' not found.`}};
        }
        int? woIdx = ();
        foreach int i in 0 ..< asset.workOrders.length() {
            if asset.workOrders[i].orderId == orderId {
                woIdx = i;
                break;
            }
        }
        if woIdx is () {
            return <http:NotFound>{body: {message: string `Work order '${orderId}' not found on asset '${assetTag}'.`}};
        }
        models:WorkOrder wo = asset.workOrders[woIdx];
        models:Task[] updatedTasks = [];
        boolean found = false;
        foreach models:Task t in wo.tasks {
            if t.taskId == taskId {
                updatedTasks.push({taskId: t.taskId, description: t.description, completed: payload.completed});
                found = true;
            } else {
                updatedTasks.push(t);
            }
        }
        if !found {
            return <http:NotFound>{body: {message: string `Task '${taskId}' not found on work order '${orderId}'.`}};
        }
        models:WorkOrder updatedWo = {
            orderId: wo.orderId,
            status: wo.status,
            description: wo.description,
            compId: wo.compId,
            tasks: updatedTasks
        };
        error? result = store:updateWorkOrder(assetTag, updatedWo);
        if result is error {
            return <http:NotFound>{body: {message: result.message()}};
        }
        return updatedWo.toJson();
    }

    # Closes a work order once all its tasks are completed.
    # + assetTag - Unique asset tag
    # + orderId - Unique work order identifier
    # + return - Closed work order (200) or error response
    resource function post assets/[string assetTag]/work\-orders/[string orderId]/close() returns json|http:NotFound|http:BadRequest {
        models:Asset? asset = store:getAsset(assetTag);
        if asset is () {
            return <http:NotFound>{body: {message: string `Asset with tag '${assetTag}' not found.`}};
        }
        int? idx = ();
        foreach int i in 0 ..< asset.workOrders.length() {
            if asset.workOrders[i].orderId == orderId {
                idx = i;
                break;
            }
        }
        if idx is () {
            return <http:NotFound>{body: {message: string `Work order '${orderId}' not found on asset '${assetTag}'.`}};
        }
        models:WorkOrder wo = asset.workOrders[idx];
        foreach models:Task t in wo.tasks {
            if !t.completed {
                return <http:BadRequest>{body: {message: string `Cannot close work order '${orderId}': task '${t.taskId}' is not completed.`}};
            }
        }
        models:WorkOrder closedWo = {
            orderId: wo.orderId,
            status: "CLOSED",
            description: wo.description,
            compId: wo.compId,
            tasks: wo.tasks
        };
        error? result = store:updateWorkOrder(assetTag, closedWo);
        if result is error {
            return <http:BadRequest>{body: {message: result.message()}};
        }
        return closedWo.toJson();
    }
}