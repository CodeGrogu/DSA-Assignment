import ballerina/time;

import peerpressure/q1_library_service.models;

isolated function parseIsoDateToSeconds(string dateStr) returns int? {
    string normalized = dateStr;
    if !normalized.includes("T") {
        normalized = normalized + "T00:00:00Z";
    } else if !normalized.endsWith("Z") && !normalized.includes("+") && !normalized.includes("-") {
        normalized = normalized + "Z";
    }
    time:Civil|error civil = time:civilFromString(normalized);
    if civil is time:Civil {
        if civil.utcOffset is () {
            civil.utcOffset = {hours: 0, minutes: 0};
        }
        time:Utc|error utc = time:utcFromCivil(civil);
        if utc is time:Utc {
            return utc[0];
        }
    }
    return ();
}

isolated function hasOverdueSchedule(models:Asset asset, string currentDate) returns boolean {
    int? currentSecs = parseIsoDateToSeconds(currentDate);
    if currentSecs is () {
        return false;
    }
    foreach models:Schedule schedule in asset.schedules {
        int? dueSecs = parseIsoDateToSeconds(schedule.dueDate);
        if dueSecs is int && dueSecs < currentSecs {
            return true;
        }
    }
    return false;
}

isolated class AssetStore {
    private table<models:Asset> key(assetTag) assetTable = table [];

    isolated function getAsset(string assetTag) returns models:Asset? {
        lock {
            if self.assetTable.hasKey(assetTag) {
                return self.assetTable.get(assetTag).cloneReadOnly();
            }
            return ();
        }
    }

    isolated function addAsset(models:Asset asset) returns error? {
        models:Asset & readonly assetVal = asset.cloneReadOnly();
        lock {
            if self.assetTable.hasKey(assetVal.assetTag) {
                return error(string `Asset with tag '${assetVal.assetTag}' already exists.`);
            }
            self.assetTable.put(assetVal);
        }
    }

    isolated function updateAsset(models:Asset asset) returns error? {
        models:Asset & readonly assetVal = asset.cloneReadOnly();
        lock {
            if !self.assetTable.hasKey(assetVal.assetTag) {
                return error(string `Asset with tag '${assetVal.assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetVal.assetTag);
            models:Component[] comps = assetVal.components.length() > 0 ? assetVal.components : existing.components;
            models:Schedule[] scheds = assetVal.schedules.length() > 0 ? assetVal.schedules : existing.schedules;
            models:WorkOrder[] orders = assetVal.workOrders.length() > 0 ? assetVal.workOrders : existing.workOrders;

            models:Asset updated = {
                assetTag: assetVal.assetTag,
                name: assetVal.name.trim().length() > 0 ? assetVal.name : existing.name,
                description: assetVal.description.trim().length() > 0 ? assetVal.description : existing.description,
                institution: assetVal.institution.trim().length() > 0 ? assetVal.institution : existing.institution,
                site: assetVal.site.trim().length() > 0 ? assetVal.site : existing.site,
                status: assetVal.status,
                dateAcquired: assetVal.dateAcquired.trim().length() > 0 ? assetVal.dateAcquired : existing.dateAcquired,
                components: comps,
                schedules: scheds,
                workOrders: orders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function deleteAsset(string assetTag) returns boolean {
        lock {
            if self.assetTable.hasKey(assetTag) {
                _ = self.assetTable.remove(assetTag);
                return true;
            }
            return false;
        }
    }

    isolated function getAllAssets() returns models:Asset[] {
        lock {
            return self.assetTable.toArray().cloneReadOnly();
        }
    }

    isolated function filterAssets(string? institution, string? site) returns models:Asset[] {
        lock {
            models:Asset[] matched = [];
            foreach models:Asset asset in self.assetTable {
                boolean matchesInstitution = institution is () || asset.institution == institution;
                boolean matchesSite = site is () || asset.site == site;
                if matchesInstitution && matchesSite {
                    matched.push(asset.cloneReadOnly());
                }
            }
            return matched.cloneReadOnly();
        }
    }

    isolated function getOverdueAssets(string currentDate) returns models:Asset[] {
        lock {
            models:Asset[] overdue = [];
            foreach models:Asset asset in self.assetTable {
                if hasOverdueSchedule(asset, currentDate) {
                    overdue.push(asset.cloneReadOnly());
                }
            }
            return overdue.cloneReadOnly();
        }
    }

    isolated function addComponent(string assetTag, models:Component component) returns error? {
        models:Component & readonly compVal = component.cloneReadOnly();
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:Component[] comps = [];
            foreach models:Component c in existing.components {
                if c.compId == compVal.compId {
                    return error(string `Component with id '${compVal.compId}' already exists on asset '${assetTag}'.`);
                }
                comps.push(c);
            }
            comps.push(compVal);

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: comps,
                schedules: existing.schedules,
                workOrders: existing.workOrders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function removeComponent(string assetTag, string compId) returns error? {
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:Component[] comps = [];
            boolean found = false;
            foreach models:Component c in existing.components {
                if c.compId == compId {
                    found = true;
                } else {
                    comps.push(c);
                }
            }
            if !found {
                return error(string `Component with id '${compId}' not found on asset '${assetTag}'.`);
            }

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: comps,
                schedules: existing.schedules,
                workOrders: existing.workOrders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function addSchedule(string assetTag, models:Schedule schedule) returns error? {
        models:Schedule & readonly schedVal = schedule.cloneReadOnly();
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:Schedule[] scheds = [];
            foreach models:Schedule s in existing.schedules {
                if s.scheduleId == schedVal.scheduleId {
                    return error(string `Schedule with id '${schedVal.scheduleId}' already exists on asset '${assetTag}'.`);
                }
                scheds.push(s);
            }
            scheds.push(schedVal);

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: scheds,
                workOrders: existing.workOrders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function removeSchedule(string assetTag, string scheduleId) returns error? {
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:Schedule[] scheds = [];
            boolean found = false;
            foreach models:Schedule s in existing.schedules {
                if s.scheduleId == scheduleId {
                    found = true;
                } else {
                    scheds.push(s);
                }
            }
            if !found {
                return error(string `Schedule with id '${scheduleId}' not found on asset '${assetTag}'.`);
            }

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: scheds,
                workOrders: existing.workOrders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function createWorkOrder(string assetTag, models:WorkOrder workOrder) returns error? {
        models:WorkOrder & readonly woVal = workOrder.cloneReadOnly();
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:WorkOrder[] orders = [];
            foreach models:WorkOrder wo in existing.workOrders {
                if wo.orderId == woVal.orderId {
                    return error(string `Work order with id '${woVal.orderId}' already exists on asset '${assetTag}'.`);
                }
                orders.push(wo);
            }
            orders.push(woVal);

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: existing.schedules,
                workOrders: orders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function updateWorkOrder(string assetTag, models:WorkOrder workOrder) returns models:WorkOrder|error {
        models:WorkOrder & readonly woVal = workOrder.cloneReadOnly();
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:WorkOrder[] orders = [];
            models:WorkOrder? resultWo = ();
            boolean found = false;
            foreach models:WorkOrder wo in existing.workOrders {
                if wo.orderId == woVal.orderId {
                    found = true;
                    // Preserve existing tasks if woVal.tasks is empty
                    models:Task[] effectiveTasks = woVal.tasks.length() > 0 ? woVal.tasks : wo.tasks;

                    if woVal.status == "CLOSED" {
                        foreach models:Task t in effectiveTasks {
                            if !t.completed {
                                return error(string `Cannot close work order '${woVal.orderId}': task '${t.taskId}' is not completed.`);
                            }
                        }
                    }

                    models:WorkOrder updatedWo = {
                        orderId: woVal.orderId,
                        status: woVal.status,
                        description: woVal.description.trim().length() > 0 ? woVal.description : wo.description,
                        compId: woVal.compId is string && (<string>woVal.compId).trim().length() > 0 ? woVal.compId : wo.compId,
                        tasks: effectiveTasks
                    };
                    orders.push(updatedWo);
                    resultWo = updatedWo;
                } else {
                    orders.push(wo);
                }
            }
            if !found || resultWo is () {
                return error(string `Work order with id '${woVal.orderId}' not found on asset '${assetTag}'.`);
            }

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: existing.schedules,
                workOrders: orders
            };
            self.assetTable.put(updated.cloneReadOnly());
            return resultWo.cloneReadOnly();
        }
    }

    isolated function addTask(string assetTag, string orderId, models:Task task) returns error? {
        models:Task & readonly taskVal = task.cloneReadOnly();
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:WorkOrder[] orders = [];
            boolean foundWo = false;

            foreach models:WorkOrder wo in existing.workOrders {
                if wo.orderId == orderId {
                    foundWo = true;
                    if wo.status == "CLOSED" {
                        return error(string `Cannot add task to closed work order '${orderId}'.`);
                    }
                    models:Task[] updatedTasks = [];
                    foreach models:Task t in wo.tasks {
                        if t.taskId == taskVal.taskId {
                            return error(string `Task '${taskVal.taskId}' already exists on work order '${orderId}'.`);
                        }
                        updatedTasks.push(t);
                    }
                    updatedTasks.push(taskVal);

                    models:WorkOrder updatedWo = {
                        orderId: wo.orderId,
                        status: wo.status,
                        description: wo.description,
                        compId: wo.compId,
                        tasks: updatedTasks
                    };
                    orders.push(updatedWo);
                } else {
                    orders.push(wo);
                }
            }

            if !foundWo {
                return error(string `Work order '${orderId}' not found on asset '${assetTag}'.`);
            }

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: existing.schedules,
                workOrders: orders
            };
            self.assetTable.put(updated.cloneReadOnly());
        }
    }

    isolated function updateTaskStatus(string assetTag, string orderId, string taskId, boolean completed) returns models:WorkOrder|error {
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:WorkOrder[] orders = [];
            models:WorkOrder? resultWo = ();
            boolean foundWo = false;

            foreach models:WorkOrder wo in existing.workOrders {
                if wo.orderId == orderId {
                    foundWo = true;
                    if wo.status == "CLOSED" {
                        return error(string `Cannot modify tasks on closed work order '${orderId}'.`);
                    }
                    models:Task[] updatedTasks = [];
                    boolean foundTask = false;

                    foreach models:Task t in wo.tasks {
                        if t.taskId == taskId {
                            updatedTasks.push({
                                taskId: t.taskId,
                                description: t.description,
                                completed: completed
                            });
                            foundTask = true;
                        } else {
                            updatedTasks.push(t);
                        }
                    }

                    if !foundTask {
                        return error(string `Task '${taskId}' not found on work order '${orderId}'.`);
                    }

                    models:WorkOrder updatedWo = {
                        orderId: wo.orderId,
                        status: wo.status,
                        description: wo.description,
                        compId: wo.compId,
                        tasks: updatedTasks
                    };
                    orders.push(updatedWo);
                    resultWo = updatedWo;
                } else {
                    orders.push(wo);
                }
            }

            if !foundWo || resultWo is () {
                return error(string `Work order '${orderId}' not found on asset '${assetTag}'.`);
            }

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: existing.schedules,
                workOrders: orders
            };
            self.assetTable.put(updated.cloneReadOnly());
            return resultWo.cloneReadOnly();
        }
    }

    isolated function closeWorkOrder(string assetTag, string orderId) returns models:WorkOrder|error {
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error(string `Asset with tag '${assetTag}' does not exist.`);
            }
            models:Asset existing = self.assetTable.get(assetTag);
            models:WorkOrder[] orders = [];
            models:WorkOrder? resultWo = ();
            boolean foundWo = false;

            foreach models:WorkOrder wo in existing.workOrders {
                if wo.orderId == orderId {
                    foundWo = true;
                    if wo.status == "CLOSED" {
                        return error(string `Work order '${orderId}' is already closed.`);
                    }
                    foreach models:Task t in wo.tasks {
                        if !t.completed {
                            return error(string `Cannot close work order '${orderId}': task '${t.taskId}' is not completed.`);
                        }
                    }

                    models:WorkOrder closedWo = {
                        orderId: wo.orderId,
                        status: "CLOSED",
                        description: wo.description,
                        compId: wo.compId,
                        tasks: wo.tasks
                    };
                    orders.push(closedWo);
                    resultWo = closedWo;
                } else {
                    orders.push(wo);
                }
            }

            if !foundWo || resultWo is () {
                return error(string `Work order '${orderId}' not found on asset '${assetTag}'.`);
            }

            models:Asset updated = {
                assetTag: existing.assetTag,
                name: existing.name,
                description: existing.description,
                institution: existing.institution,
                site: existing.site,
                status: existing.status,
                dateAcquired: existing.dateAcquired,
                components: existing.components,
                schedules: existing.schedules,
                workOrders: orders
            };
            self.assetTable.put(updated.cloneReadOnly());
            return resultWo.cloneReadOnly();
        }
    }

    isolated function resetStore() {
        lock {
            self.assetTable = table [];
        }
    }
}

final AssetStore storeInstance = new ();

public isolated function getAsset(string assetTag) returns models:Asset? {
    return storeInstance.getAsset(assetTag);
}

public isolated function addAsset(models:Asset asset) returns error? {
    return storeInstance.addAsset(asset);
}

public isolated function updateAsset(models:Asset asset) returns error? {
    return storeInstance.updateAsset(asset);
}

public isolated function deleteAsset(string assetTag) returns boolean {
    return storeInstance.deleteAsset(assetTag);
}

public isolated function getAllAssets() returns models:Asset[] {
    return storeInstance.getAllAssets();
}

public isolated function filterAssets(string? institution, string? site) returns models:Asset[] {
    return storeInstance.filterAssets(institution, site);
}

public isolated function getOverdueAssets(string currentDate) returns models:Asset[] {
    return storeInstance.getOverdueAssets(currentDate);
}

public isolated function addComponent(string assetTag, models:Component component) returns error? {
    return storeInstance.addComponent(assetTag, component);
}

public isolated function removeComponent(string assetTag, string compId) returns error? {
    return storeInstance.removeComponent(assetTag, compId);
}

public isolated function addSchedule(string assetTag, models:Schedule schedule) returns error? {
    return storeInstance.addSchedule(assetTag, schedule);
}

public isolated function removeSchedule(string assetTag, string scheduleId) returns error? {
    return storeInstance.removeSchedule(assetTag, scheduleId);
}

public isolated function createWorkOrder(string assetTag, models:WorkOrder workOrder) returns error? {
    return storeInstance.createWorkOrder(assetTag, workOrder);
}

public isolated function updateWorkOrder(string assetTag, models:WorkOrder workOrder) returns models:WorkOrder|error {
    return storeInstance.updateWorkOrder(assetTag, workOrder);
}

public isolated function addTask(string assetTag, string orderId, models:Task task) returns error? {
    return storeInstance.addTask(assetTag, orderId, task);
}

public isolated function updateTaskStatus(string assetTag, string orderId, string taskId, boolean completed) returns models:WorkOrder|error {
    return storeInstance.updateTaskStatus(assetTag, orderId, taskId, completed);
}

public isolated function closeWorkOrder(string assetTag, string orderId) returns models:WorkOrder|error {
    return storeInstance.closeWorkOrder(assetTag, orderId);
}

public isolated function resetStore() {
    storeInstance.resetStore();
}

// ==========================================================================
// INSTITUTION DATA STORE
// ==========================================================================

isolated table<models:Institution> key(id) institutionTable = table [];

public isolated function getAllInstitutions() returns models:Institution[] {
    lock {
        return institutionTable.toArray().cloneReadOnly();
    }
}

public isolated function addInstitution(models:Institution inst) returns error? {
    models:Institution & readonly instVal = inst.cloneReadOnly();
    lock {
        if institutionTable.hasKey(instVal.id) {
            return error(string `Institution with ID '${instVal.id}' already exists.`);
        }
        institutionTable.put(instVal);
    }
}

public isolated function deleteInstitution(string id) returns boolean {
    lock {
        if institutionTable.hasKey(id) {
            _ = institutionTable.remove(id);
            return true;
        }
        return false;
    }
}
