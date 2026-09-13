# Question 2: Rental Accommodation Client (gRPC)

Interactive command-line client application for the Vacation Property Rental Accommodation System built with **Ballerina Swan Lake (2201.13.x)** and **Protocol Buffers v3**.

---

## 1. Overview

`q2_rental_client` provides an interactive terminal console interface to interact with the gRPC `q2_rental_service` microservice, supporting unary RPCs, client-streaming user registration, and server-streaming property browsing.

All property listings are tracked by the primary key: `assetTag`.

---

## 2. Configuration

Copy the example configuration file:
```bash
cp Config.example.toml Config.toml
```

Modify `Config.toml` to customize the gRPC service endpoint and timeout:
```toml
[peerpressure.q2_rental_client]
serviceUrl = "http://localhost:9090"
rpcTimeout = 10.0
```

---

## 3. Execution

Ensure the gRPC service is running in `q2_rental_service` first:
```bash
cd ../q2_rental_service
bal run
```

In a second terminal, execute the client:
```bash
cd q2_rental_client
bal run
```

### Interactive Menu Options
1. **Add Property**: Register a new property listing (auto-generates `assetTag`).
2. **Update Property**: Modify title, pricing, location, or status.
3. **Remove Property**: Remove a property and list remaining regional properties.
4. **Search Property**: Lookup property by `assetTag`.
5. **List Available Properties**: Server-streaming filtered property query.
6. **Register Users**: Client-streaming bulk registration of Host and Guest profiles.
7. **Book Property**: Stage booking in temporary cart and confirm reservation.
0. **Exit**: Gracefully terminate the client.

---

## 4. Automated Tests
```bash
bal test
```
