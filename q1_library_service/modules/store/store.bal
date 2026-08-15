// Copyright (c) 2026 Peer Pressure Team. All Rights Reserved.
//
// Distributed under the MIT License.
// See LICENSE file in the project root for full license information.

import peerpressure/q1_library_service.models;

# Distinct error type raised when an asset is not found in the store.
public type AssetNotFoundError distinct error;

# Distinct error type raised when attempting to insert an asset with a duplicate assetTag.
public type DuplicateAssetError distinct error;

# Thread-safe in-memory data store for managing Asset records.
# Concurrency safety is guaranteed via `isolated` methods and `lock` protection.
public isolated class AssetStore {
    # Internal table keyed by `assetTag` ensuring O(1) primary key lookups.
    private final table<models:Asset> key(assetTag) assetTable = table [];

    # Initialises a new in-memory Asset store instance.
    public isolated function init() {
    }

    # Retrieves an asset by its primary `assetTag`.
    #
    # + assetTag - Unique primary key identifier
    # + return - The matching `Asset` record or `AssetNotFoundError` if not found
    public isolated function getAsset(string assetTag) returns models:Asset|AssetNotFoundError {
        lock {
            if self.assetTable.hasKey(assetTag) {
                return self.assetTable.get(assetTag).cloneReadOnly();
            }
            return error AssetNotFoundError(string `Asset with assetTag '${assetTag}' not found.`);
        }
    }

    # Inserts a new asset into the in-memory store.
    #
    # + asset - The `Asset` record to store
    # + return - `DuplicateAssetError` if the assetTag already exists, nil on success
    public isolated function addAsset(models:Asset asset) returns DuplicateAssetError? {
        lock {
            if self.assetTable.hasKey(asset.assetTag) {
                return error DuplicateAssetError(string `Asset with assetTag '${asset.assetTag}' already exists.`);
            }
            self.assetTable.put(asset.cloneReadOnly());
            return ();
        }
    }

    # Updates an existing asset in the store.
    #
    # + assetTag - Unique identifier of the asset to update
    # + asset - Updated `Asset` record
    # + return - `AssetNotFoundError` if the asset does not exist, nil on success
    public isolated function updateAsset(string assetTag, models:Asset asset) returns AssetNotFoundError? {
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error AssetNotFoundError(string `Asset with assetTag '${assetTag}' not found for update.`);
            }
            self.assetTable.put(asset.cloneReadOnly());
            return ();
        }
    }

    # Removes an asset from the store.
    #
    # + assetTag - Unique identifier of the asset to remove
    # + return - The deleted `Asset` record or `AssetNotFoundError` if not found
    public isolated function deleteAsset(string assetTag) returns models:Asset|AssetNotFoundError {
        lock {
            if !self.assetTable.hasKey(assetTag) {
                return error AssetNotFoundError(string `Asset with assetTag '${assetTag}' not found for removal.`);
            }
            return self.assetTable.remove(assetTag).cloneReadOnly();
        }
    }

    # Retrieves all assets currently stored across all institutions and sites.
    #
    # + return - Array of all `Asset` records
    public isolated function getAllAssets() returns models:Asset[] {
        lock {
            return self.assetTable.toArray().cloneReadOnly();
        }
    }
}

# Module-level isolated singleton instance.
final AssetStore storeInstance = new ();

# Module-level accessor to retrieve an asset by assetTag.
#
# + assetTag - Primary key
# + return - Asset record or AssetNotFoundError
public isolated function getAsset(string assetTag) returns models:Asset|AssetNotFoundError {
    return storeInstance.getAsset(assetTag);
}

# Module-level accessor to add a new asset.
#
# + asset - Asset to store
# + return - DuplicateAssetError if key exists, nil on success
public isolated function addAsset(models:Asset asset) returns DuplicateAssetError? {
    return storeInstance.addAsset(asset);
}

# Module-level accessor to update an asset.
#
# + assetTag - Primary key
# + asset - Updated record
# + return - AssetNotFoundError if missing, nil on success
public isolated function updateAsset(string assetTag, models:Asset asset) returns AssetNotFoundError? {
    return storeInstance.updateAsset(assetTag, asset);
}

# Module-level accessor to delete an asset.
#
# + assetTag - Primary key
# + return - Deleted asset or AssetNotFoundError
public isolated function deleteAsset(string assetTag) returns models:Asset|AssetNotFoundError {
    return storeInstance.deleteAsset(assetTag);
}

# Module-level accessor to get all assets.
#
# + return - Array of assets
public isolated function getAllAssets() returns models:Asset[] {
    return storeInstance.getAllAssets();
}
