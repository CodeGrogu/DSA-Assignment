# Question 1: Library & Resource Management System Client (REST)

CLI and interactive console application for the Library & Resource Management System built with **Ballerina Swan Lake (2201.13.x)**.

---

## 1. Overview

`q1_library_client` provides both direct command-line execution and an interactive terminal menu interface to interact with the RESTful `q1_library_service` microservice.

All entity records are identified using the canonical camelCase primary key: `assetTag`.

---

## 2. Configuration

Copy the example configuration file:
```bash
cp Config.example.toml Config.toml
```

Modify `Config.toml` to customize the REST service endpoint and timeout:
```toml
[peerpressure.q1_library_client]
serviceUrl = "http://localhost:9090"
clientTimeout = 10.0
```

---

## 3. Execution

Ensure the REST service is running in `q1_library_service` first:
```bash
cd ../q1_library_service
bal run
```

In a second terminal, execute the client:

### Interactive Menu Mode
```bash
bal run
```

### Direct Command-Line Mode
```bash
# Check service health
bal run -- health

# List all assets (supports optional institution and site filters)
bal run -- list
bal run -- list NUST "Main Campus"

# Inspect asset by unique assetTag
bal run -- get AST-101

# View overdue maintenance assets
bal run -- overdue

# View operational status and active work orders
bal run -- status AST-101

# Delete an asset
bal run -- delete AST-101

# Display usage help
bal run -- help
```

---

## 4. Automated Tests
```bash
bal test
```
