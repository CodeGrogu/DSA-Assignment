// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import ballerina/http;
import ballerina/log;

import peerpressure/q1_library_service.models;
import peerpressure/q1_library_service.store;

# Configurable port for the REST HTTP API service.
configurable int servicePort = 9090;

# HTTP Listener attached to the configured service port.
listener http:Listener libraryListener = new (servicePort);

# RESTful HTTP Service for the Library & Resource Management System (Q1).
service / on libraryListener {

    function init() {
        log:printInfo(string `Library & Resource Management System REST Service started on port ${servicePort}`);
    }

    # Health check endpoint confirming service status and operational metadata.
    #
    # + return - JSON status response
    @http:ResourceConfig {
        produces: ["application/json"]
    }
    resource function get health() returns @http:Payload json {
        return {
            status: "UP",
            serviceName: "Library & Resource Management System (REST)",
            version: "0.1.0",
            port: servicePort
        };
    }

    # Root endpoint returning API metadata and endpoint links.
    #
    # + return - JSON welcome response
    @http:ResourceConfig {
        produces: ["application/json"]
    }
    resource function get .() returns @http:Payload json {
        return {
            name: "Library & Resource Management System API",
            description: "Distributed asset management system across ministry institutions and campuses.",
            version: "0.1.0",
            endpoints: [
                "GET /health",
                "GET /assets",
                "POST /assets",
                "GET /assets/{assetTag}",
                "PUT /assets/{assetTag}",
                "DELETE /assets/{assetTag}"
            ]
        };
    }

    # Returns all assets currently registered in the system.
    #
    # + return - JSON Array of all assets
    @http:ResourceConfig {
        produces: ["application/json"]
    }
    resource function get assets() returns @http:Payload json {
        return store:getAllAssets().toJson();
    }

    # Looks up a specific asset by its unique assetTag.
    #
    # + assetTag - Unique asset identifier
    # + return - Matching Asset record or 404 Not Found response
    @http:ResourceConfig {
        produces: ["application/json"]
    }
    resource function get assets/[string assetTag]() returns models:Asset|http:NotFound {
        models:Asset|store:AssetNotFoundError result = store:getAsset(assetTag);
        if result is store:AssetNotFoundError {
            return <http:NotFound>{
                body: {
                    "error": "Asset Not Found",
                    "message": result.message(),
                    "assetTag": assetTag
                }
            };
        }
        return result;
    }
}
