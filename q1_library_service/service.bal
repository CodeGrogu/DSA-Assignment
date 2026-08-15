import ballerina/http;
import ballerina/log;

import peerpressure/q1_library_service.models;
import peerpressure/q1_library_service.store;

configurable int servicePort = 9090;

listener http:Listener httpListener = new (servicePort);

service / on httpListener {

    function init() {
        log:printInfo(string `Library & Resource Management System REST Service started on port ${servicePort}`);
    }

    resource function get health() returns json {
        return {
            status: "UP",
            timestamp: 1723758000000,
            'service: "q1_library_service"
        };
    }

    resource function get .() returns json {
        return {
            'service: "Library & Resource Management System",
            version: "0.1.0",
            endpoints: [
                "/health",
                "/assets",
                "/assets/{assetTag}",
                "/assets/overdue"
            ]
        };
    }

    @http:ResourceConfig {
        produces: ["application/json"]
    }
    resource function get assets() returns json {
        models:Asset[] allAssets = store:getAllAssets();
        return allAssets.toJson();
    }
}
