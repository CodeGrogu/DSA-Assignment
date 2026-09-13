# Thread-safe in-memory store for managing property listings in the Rental Accommodation System.
#
# Follows Swan Lake isolated concurrency principles:
# - Encapsulates in-memory `map<Property & readonly>` storage keyed by `assetTag`.
# - Protects all state mutations and reads within `lock` blocks.
# - Stores immutable read-only records to preserve thread isolation boundaries without excess cloning.
public isolated class PropertyStore {
    // In-memory map keyed by unique assetTag
    private map<Property & readonly> properties = {};
    // Monotonically increasing counter for unique assetTag generation
    private int counter = 1001;

    # Adds a new property listing to the store.
    #
    # + req - The AddPropertyRequest payload containing listing details
    # + return - The newly created and stored Property record
    public isolated function addProperty(AddPropertyRequest req) returns Property {
        lock {
            string tag = string `PROP-${self.counter}`;
            self.counter += 1;

            Property & readonly prop = {
                assetTag: tag,
                name: req.name.trim(),
                location: req.location.trim(),
                propertyType: req.propertyType.trim(),
                pricePerNight: req.pricePerNight,
                status: "AVAILABLE",
                hostId: req.hostId.trim()
            }.cloneReadOnly();

            self.properties[tag] = prop;
            return prop;
        }
    }

    # Retrieves a single property listing by its unique assetTag.
    #
    # + assetTag - The unique identifier of the property
    # + return - The Property record if found, or nil `()` if not found
    public isolated function getProperty(string assetTag) returns Property? {
        lock {
            return self.properties[assetTag];
        }
    }

    # Updates an existing property listing. Only provided non-empty fields are updated,
    # preserving untouched metadata without clobbering. Validates status domains and price bounds.
    #
    # + req - The UpdatePropertyRequest containing updated field values
    # + return - The updated Property record, or an error if the listing does not exist or validation fails
    public isolated function updateProperty(UpdatePropertyRequest req) returns Property|error {
        lock {
            Property? current = self.properties[req.assetTag];
            if current is () {
                return error(string `Property with assetTag '${req.assetTag}' not found`);
            }

            // Validate price per night if supplied (proto3 defaults to 0.0 when unset)
            float newPrice = current.pricePerNight;
            if req.pricePerNight != 0.0 {
                if !req.pricePerNight.isFinite() || req.pricePerNight < 0.0 {
                    return error("Price per night must be a non-negative finite number.");
                }
                newPrice = req.pricePerNight;
            }

            // Validate domain status if supplied
            string newStatus = current.status;
            if req.status.trim().length() > 0 {
                string statusUpper = req.status.trim().toUpperAscii();
                if statusUpper != "AVAILABLE" && statusUpper != "RENTED" && statusUpper != "MAINTENANCE" {
                    return error(string `Invalid status '${req.status}'. Allowed values are AVAILABLE, RENTED, or MAINTENANCE.`);
                }
                newStatus = statusUpper;
            }

            Property & readonly updated = {
                assetTag: current.assetTag,
                name: req.name.trim().length() > 0 ? req.name.trim() : current.name,
                location: req.location.trim().length() > 0 ? req.location.trim() : current.location,
                propertyType: req.propertyType.trim().length() > 0 ? req.propertyType.trim() : current.propertyType,
                pricePerNight: newPrice,
                status: newStatus,
                hostId: current.hostId
            }.cloneReadOnly();

            self.properties[req.assetTag] = updated;
            return updated;
        }
    }

    # Removes a property listing by its assetTag and returns the host's remaining listings
    # in that region/location using a declarative query.
    # Enforces host ownership and location verification before performing the deletion.
    #
    # + assetTag - The unique identifier of the property to remove
    # + hostId - The identifier of the Host owning the listing
    # + location - The geographical location/region
    # + return - Array of remaining Property records owned by the host in that location, or error
    public isolated function removeProperty(string assetTag, string hostId, string location) returns Property[]|error {
        lock {
            Property? existing = self.properties[assetTag];
            if existing is () {
                return error(string `Property with assetTag '${assetTag}' does not exist`);
            }
            // Enforce caller authorization: only the owning host can remove their listing
            if existing.hostId != hostId {
                return error(string `Unauthorized: Property with assetTag '${assetTag}' does not belong to host '${hostId}'`);
            }
            // Enforce region consistency: verify the listing is in the requested location
            if existing.location != location {
                return error(string `Location mismatch: Property '${assetTag}' is located in '${existing.location}', not '${location}'`);
            }

            _ = self.properties.remove(assetTag);

            Property[] remaining = from Property p in self.properties.toArray()
                where p.hostId == hostId && p.location == location
                select p;
            return remaining.cloneReadOnly();
        }
    }

    # Searches for a property by its assetTag.
    #
    # + assetTag - The unique identifier of the property
    # + return - The Property record if found, or nil `()` if not found
    public isolated function searchProperty(string assetTag) returns Property? {
        lock {
            return self.properties[assetTag];
        }
    }

    # Filters and returns all listings matching the provided criteria using a declarative query.
    #
    # + filter - The search filters (location, price bounds, propertyType)
    # + return - Array of matching available properties
    public isolated function listAvailableProperties(ListAvailablePropertiesRequest filter) returns Property[] {
        lock {
            Property[] matched = from Property p in self.properties.toArray()
                where p.status == "AVAILABLE"
                    && (filter.location == "" || p.location == filter.location)
                    && (filter.propertyType == "" || p.propertyType == filter.propertyType)
                    && (filter.minPrice <= 0.0 || p.pricePerNight >= filter.minPrice)
                    && (filter.maxPrice <= 0.0 || p.pricePerNight <= filter.maxPrice)
                select p;
            return matched.cloneReadOnly();
        }
    }

    # Returns all properties currently in the store.
    #
    # + return - Array of all Property records
    public isolated function getAllProperties() returns Property[] {
        lock {
            return self.properties.toArray().cloneReadOnly();
        }
    }
}
