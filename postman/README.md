# Postman Collections & Environments (v3 YAML Format)

This directory houses the version-controlled Postman collections and environment templates for the **PeerPressure** Postman workspace using the **Postman v3 YAML specification** required for Local Mode and Native Git workflows.

## Structure

```text
postman/
├── collections/                  # Postman v3 YAML collections (directory-based)
│   └── <collection-name>/
│       ├── definition.yaml       # Collection metadata & settings
│       ├── <request-name>.request.yaml  # Individual request definitions
│       └── .resources/           # Supporting scripts and examples
└── environments/
    └── peerpressure-dev.environment.yaml  # Base environment variables (v3 YAML)
```

## Running Tests Locally (Postman CLI)

Postman v3 YAML collections and environments in Local Mode are executed via the official **Postman CLI**:

```powershell
# Run collection with the peerpressure-dev environment
postman collection run postman/collections/<collection-folder> -e postman/environments/peerpressure-dev.environment.yaml
```

## Local Mode & Postman App Integration

1. Open Postman in **Local Mode** connected to this Git repository.
2. Collections and environments will automatically reflect as YAML files under `postman/`.
3. To migrate legacy v2.1 collections to v3 YAML:
   ```powershell
   postman collection migrate <path-to-v2.1-collection.json>
   ```
