import peerpressure/q1_library_service.models;

isolated class AssetStore {
    private final table<models:Asset> key(assetTag) assetTable = table [];

    isolated function getAsset(string assetTag) returns models:Asset? {
        lock {
            if self.assetTable.hasKey(assetTag) {
                return self.assetTable.get(assetTag);
            }
            return ();
        }
    }

    isolated function addAsset(models:Asset asset) returns error? {
        lock {
            if self.assetTable.hasKey(asset.assetTag) {
                return error(string `Asset with tag '${asset.assetTag}' already exists.`);
            }
            self.assetTable.put(asset);
        }
    }

    isolated function updateAsset(models:Asset asset) returns error? {
        lock {
            if !self.assetTable.hasKey(asset.assetTag) {
                return error(string `Asset with tag '${asset.assetTag}' does not exist.`);
            }
            self.assetTable.put(asset);
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
