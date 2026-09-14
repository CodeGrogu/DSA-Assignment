# Question 2: Rental Accommodation System Client (gRPC)

Interactive terminal client for the Vacation Property Rental Accommodation System built with **Ballerina Swan Lake (2201.13.5)** and **Protocol Buffers v3**.

---

## 1. Overview

`q2_rental_client` connects to the `q2_rental_service` gRPC microservice, allowing users, hosts, and administrators to interactively exercise all 8 gRPC operations across unary, client-streaming, and server-streaming interaction paradigms.

All property listings are tracked by the primary key: `assetTag`.

---

## 2. Configuration

The client connects to `http://localhost:9090` by default. To customise the service URL or RPC timeout, copy the example configuration:

```bash
cp Config.example.toml Config.toml
```

Edit `Config.toml`:
```toml
[peerpressure.q2_rental_client]
serviceUrl = "http://localhost:9090"
rpcTimeout = 15.0
```

---

## 3. Protocol Buffers & Client Stub Generation

Client stubs are generated from the shared proto definition located in `../q2_rental_service/proto/rental_service.proto`:

```bash
bal tool pull grpc
bal grpc --input ../q2_rental_service/proto/rental_service.proto --output . --mode client
```

---

## 4. Execution

Ensure the gRPC service is running in `q2_rental_service` before launching the client:

```bash
# Terminal 1: Start Service
cd ../q2_rental_service
bal run
```

In a second terminal:

```bash
# Terminal 2: Launch Interactive Client
cd q2_rental_client
bal run
```

---

## 5. Interactive Terminal Menu (All 8 Operations)

```text
======================================================
     Rental Accommodation System - gRPC Client        
======================================================
1.  Add Property (Host)
2.  Update Property (Host)
3.  Remove Property (Host)
4.  Search Property
5.  List Available Properties (Server Streaming)
6.  Register Users (Client Streaming)
7.  Book Property (Two-Phase Guest Reservation)
0.  Exit
```

### Walkthrough of Interactive Operations:

1. **Add Property (Option 1):**  
   Prompts for property title, location, property type (Apartment, House, Villa), and price per night. The server auto-generates and returns a unique `assetTag` (e.g. `PROP-1001`).

2. **Update Property (Option 2):**  
   Prompts for existing `assetTag` and updated fields. Empty entries preserve existing stored values.

3. **Remove Property (Option 3):**  
   Prompts for `assetTag`, host ID, and location. Verifies host ownership before deleting and returns the host's remaining regional listings.

4. **Search Property (Option 4):**  
   Queries a single property by `assetTag`. Displays name, location, price, and operational status, or "Not Available".

5. **List Available Properties (Option 5 - Server Streaming):**  
   Accepts optional filters (location, property type, min/max price). Streams matching listings from the server in real time without blocking.

6. **Register Users (Option 6 - Client Streaming):**  
   Opens a single streaming connection. Allows entering multiple user profiles (Hosts and Guests) sequentially. Upon closing the stream, the server responds with a summary confirmation of registered users.

7. **Book Property (Option 7 - Two-Phase Reservation):**  
   Prompts for `assetTag`, guest ID, check-in date, and check-out date. The server verifies availability, checks date conflicts, stages a temporary cart entry, and prompts for immediate confirmation to finalise the booking.

---

## 6. Build and Verification

Compile the executable JAR:
```bash
bal build
```

Verify formatting:
```bash
bal format --dry-run
```
