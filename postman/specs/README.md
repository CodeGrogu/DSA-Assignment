# Postman API Specifications (`specs/`)

This directory houses official API schema definitions and contracts for the **PeerPressure** workspace in Postman Local Mode.

## Specifications Catalog

### 1. `rental_service.proto` (Question 2: Rental Accommodation System)
* **Format**: Protocol Buffers v3 (`proto3`)
* **Package**: `rental`
* **Service**: `RentalService`
* **Operations**:
  1. `add_property` (Unary)
  2. `update_property` (Unary)
  3. `remove_property` (Unary)
  4. `search_property` (Unary)
  5. `create_users` (Client Streaming)
  6. `list_available_properties` (Server Streaming)
  7. `book_property` (Unary)
  8. `confirm_booking` (Unary)

## How to Import in Postman Local Mode

1. Open Postman desktop app with the repository in Local Mode.
2. Under **APIs** or **gRPC Requests**, select **New** > **gRPC Request**.
3. Select **Import a .proto file** and choose `postman/specs/rental_service.proto`.
4. Set the server URL using the environment variable `{{grpc_host}}:{{grpc_port}}` (e.g. `localhost:9090`).
5. Select any of the 8 RPC methods from the dropdown to invoke unary, client-streaming, or server-streaming requests.
