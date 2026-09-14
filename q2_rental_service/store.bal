import ballerina/time;

# Thread-safe in-memory store for managing property listings in the Rental Accommodation System.
#
# Follows Swan Lake isolated concurrency principles:
# - Encapsulates in-memory `map<Property & readonly>` storage keyed by `assetTag`.
# - Protects all state mutations and reads within `lock` blocks.
# - Stores immutable read-only records to preserve thread isolation boundaries without excess cloning.

# Internal temporary cart entry. Not part of the gRPC contract.
# Lives only inside PropertyStore until confirm_booking promotes it.
public type BookingCartEntry record {|
    string bookingId;
    string assetTag;
    string guestId;
    time:Civil checkIn;
    time:Civil checkOut;
    float pricePerNightSnapshot;
    int nights;
    float estimatedCost;
|};

public isolated class PropertyStore {
    private map<Property & readonly> properties = {};
    private map<User & readonly> users = {};
    private int counter = 1001;

    // Temporary booking cart: keyed by bookingId.
    private map<BookingCartEntry> bookingCart = {};
    // Confirmed bookings: keyed by bookingId.
    private map<Booking & readonly> bookings = {};
    // Monotonic counter for unique bookingId generation.
    private int bookingCounter = 1;

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
    public isolated function getProperty(string assetTag) returns Property? {
        lock {
            return self.properties[assetTag];
        }
    }

    # Updates an existing property listing.
    public isolated function updateProperty(UpdatePropertyRequest req) returns Property|error {
        lock {
            Property? current = self.properties[req.assetTag];
            if current is () {
                return error(string `Property with assetTag '${req.assetTag}' not found`);
            }

            float newPrice = current.pricePerNight;
            if req.pricePerNight != 0.0 {
                if !req.pricePerNight.isFinite() || req.pricePerNight < 0.0 {
                    return error("Price per night must be a non-negative finite number.");
                }
                newPrice = req.pricePerNight;
            }

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

    # Removes a property listing by its assetTag.
    public isolated function removeProperty(string assetTag, string hostId, string location) returns Property[]|error {
        lock {
            Property? existing = self.properties[assetTag];
            if existing is () {
                return error(string `Property with assetTag '${assetTag}' does not exist`);
            }
            if existing.hostId != hostId {
                return error(string `Unauthorized: Property with assetTag '${assetTag}' does not belong to host '${hostId}'`);
            }
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
    public isolated function searchProperty(string assetTag) returns Property? {
        lock {
            return self.properties[assetTag];
        }
    }

    # Filters and returns all listings matching the provided criteria.
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

    # Registers a new user profile in the in-memory store.
    public isolated function addUser(User user) returns User {
        lock {
            User & readonly savedUser = {
                userId: user.userId,
                name: user.name,
                role: user.role,
                email: user.email,
                phoneNumber: user.phoneNumber
            }.cloneReadOnly();

            self.users[user.userId] = savedUser;
            return savedUser;
        }
    }

    # Retrieves a single user by their unique userId.
    public isolated function getUser(string userId) returns User? {
        lock {
            return self.users[userId];
        }
    }

    # Returns all users currently in the store.
    public isolated function getAllUsers() returns User[] {
        lock {
            return self.users.toArray().cloneReadOnly();
        }
    }

    # Returns all properties currently in the store.
    public isolated function getAllProperties() returns Property[] {
        lock {
            return self.properties.toArray().cloneReadOnly();
        }
    }

    # Adds or replaces a cart entry for a guest.
    # One-cart-per-guest rule: any prior entry for this guest is removed first.
    public isolated function addToCart(BookingCartEntry entry) returns error? {
        lock {
            string[] toRemove = [];
            foreach string key in self.bookingCart.keys() {
                BookingCartEntry? existing = self.bookingCart[key];
                if existing is () {
                    continue;
                }
                if existing.guestId == entry.guestId {
                    toRemove.push(key);
                }
            }
            foreach string key in toRemove {
                _ = self.bookingCart.remove(key);
            }
            self.bookingCart[entry.bookingId] = entry.clone();
        }
    }

    # Looks up a cart entry by bookingId.
    public isolated function getCart(string bookingId) returns BookingCartEntry? {
    lock {
        BookingCartEntry? entry = self.bookingCart[bookingId];
        if entry is () {
            return ();
        }
        return entry.clone();
    }
}

    # Generates a unique bookingId.
    public isolated function nextBookingId() returns string {
        lock {
            string id = string `BOOK-${self.bookingCounter}`;
            self.bookingCounter += 1;
            return id;
        }
    }

    # Atomic confirm: overlap check, promote cart entry, clear cart.
    public isolated function confirmBooking(string bookingId, string guestId, string assetTag) returns Booking|error {
        lock {
            BookingCartEntry? cart = self.bookingCart[bookingId];
            if cart is () {
                return error("Booking request not found or already confirmed.");
            }
            if cart.guestId != guestId {
                return error("Guest mismatch for booking request.");
            }
            if cart.assetTag != assetTag {
                return error("Asset mismatch for booking request.");
            }

            Property? prop = self.properties[assetTag];
            if prop is () {
                return error("Property no longer exists.");
            }
            if prop.status != "AVAILABLE" {
                return error("Property is no longer available.");
            }

            foreach Booking existing in self.bookings.toArray() {
                if existing.assetTag != assetTag {
                    continue;
                }
                time:Civil existingIn = check parseDate(existing.checkInDate);
                time:Civil existingOut = check parseDate(existing.checkOutDate);
                boolean clash = check overlaps(cart.checkIn, cart.checkOut, existingIn, existingOut);
                if clash {
                    return error(string `Dates overlap with existing booking '${existing.bookingId}'.`);
                }
            }

           Booking & readonly confirmed = {
            bookingId: cart.bookingId,
            assetTag: cart.assetTag,
            guestId: cart.guestId,
            checkInDate: string `${cart.checkIn.year}-${padZero(cart.checkIn.month)}-${padZero(cart.checkIn.day)}`,
            checkOutDate: string `${cart.checkOut.year}-${padZero(cart.checkOut.month)}-${padZero(cart.checkOut.day)}`,
            totalCost: cart.estimatedCost,
            status: "CONFIRMED"
            }.cloneReadOnly();
            self.bookings[cart.bookingId] = confirmed;
            _ = self.bookingCart.remove(bookingId);
            return confirmed; 
        }
    }
}

# ============================================================
# Module-level helper functions
# ============================================================

# Parses a yyyy-MM-dd string into a time:Civil at midnight UTC.
isolated function parseDate(string dateStr) returns time:Civil|error {
    return time:civilFromString(dateStr + "T00:00:00Z");
}

# Returns the number of nights between two dates.
isolated function nightsBetween(time:Civil checkIn, time:Civil checkOut) returns int|error {
    time:Utc u1 = check time:utcFromCivil(checkIn);
    time:Utc u2 = check time:utcFromCivil(checkOut);
    time:Seconds diff = time:utcDiffSeconds(u2, u1);
    return <int>(diff / 86400);
}

# Returns true if two half-open date ranges overlap.
isolated function overlaps(time:Civil aStart, time:Civil aEnd, time:Civil bStart, time:Civil bEnd) returns boolean|error {
    time:Utc aS = check time:utcFromCivil(aStart);
    time:Utc aE = check time:utcFromCivil(aEnd);
    time:Utc bS = check time:utcFromCivil(bStart);
    time:Utc bE = check time:utcFromCivil(bEnd);
    return aS[0] < bE[0] && aE[0] > bS[0];
}

# Zero-pads a number to two digits for date formatting.
isolated function padZero(int n) returns string {
    return n < 10 ? string `0${n}` : n.toString();
}