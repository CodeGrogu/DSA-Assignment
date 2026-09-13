# Implementation Guide: gRPC Streaming for Users and Listings

This guide provides clear, comprehensive instructions for implementing GitHub Issue #40 and its two sub-issues: Issue #41 (Client-Streaming User Registration) and Issue #42 (Server-Streaming Property Browsing).

---

## 1. Overview and Objectives

The parent milestone and its two child issues represent the streaming communication requirements for Question 2 of the assignment:

* **Issue #40: [Q2] Server: Streaming (Users & Listings)**  
  This is the parent coordinating issue. It requires implementing both streaming handlers on the server: the client-streaming user registration handler and the server-streaming property browsing handler.

* **Issue #41: Implement create_users (client-streaming) handler**  
  This issue requires creating the server-side logic that allows a client to stream multiple user profiles (both Hosts and Guests) into the server over a single connection. The server must store each profile and return a single summary confirmation when the client closes the stream.

* **Issue #42: Implement list_available_properties (server-streaming) handler**  
  This issue requires creating the server-side logic that allows a client to request available properties. The server must stream matching listings back to the client one by one over the network, rather than bundling them into a single response.

---

## 2. Understanding gRPC Streaming in Plain English

Traditional network calls follow a simple question-and-answer structure: a client sends one question, and the server sends back one answer. Streaming introduces continuous data flow in one or both directions.

### What is Client Streaming?
Client streaming can be compared to inserting coins into a vending machine one by one. The client opens a single communication channel to the server. Across that open channel, the client pushes user profiles sequentially: first User 1, then User 2, then User 3. 

When the client has finished transmitting all profiles, it informs the server that it is done. The server accepts each user, stores each user in memory, and replies with exactly one summary confirmation receipt stating how many users were successfully saved. At no point does the server reply after each individual user; there is only one final response.

### What is Server Streaming?
Server streaming can be compared to items travelling on a conveyor belt. The client makes a single search request specifying what it is looking for, such as properties located in Swakopmund under a certain price. 

Instead of making the client wait while the server gathers all matching properties into one giant package, the server transmits each matching property individually across the open channel as soon as it is retrieved. The client receives Property 1, then Property 2, and so on. When the last property has been sent, the server signals that the stream has finished. This enables user interfaces to display results progressively without waiting for the entire dataset.

---

## 3. Architecture and Data Storage Requirements

Before any network handlers can be updated, the in-memory storage layer in the store file (`store.bal`) must be expanded to manage user accounts alongside property listings.

### Adding User Storage
Currently, the property store manages property records. It must be updated to include a private dictionary (or map) of user records, indexed by each user's unique identifier.

To follow the project concurrency standards:
* **Thread Safety**: All reads and writes to the user dictionary must take place inside synchronized lock blocks. This ensures that simultaneous requests from multiple clients cannot corrupt server memory.
* **Immutability**: When a user record is saved, it must be marked as read-only. Storing read-only records preserves thread isolation boundaries and avoids unnecessary memory copying.

### Required Helper Functions for Users
Three primary operations are required in the storage layer:
1. **Add User**: Accepts an incoming user record, marks it as read-only, saves it in the dictionary using the user's identifier as the key, and returns the stored record.
2. **Get User**: Accepts a user identifier and looks it up in the dictionary within a synchronized lock block, returning the user if found or an empty result if missing.
3. **Get All Users**: Returns an array of all currently registered user records, which is useful for verification and test assertions.

### Verifying Property Filter Logic for Server Streaming
The property filtering method in the storage layer is responsible for selecting which listings should be sent down the server stream. It must enforce the following business rules:
* **Availability Rule**: Only properties whose status is set to Available may be returned. Any property marked as rented, under maintenance, or deleted must be strictly excluded.
* **Location Filter**: If the guest specified a location, only listings whose location matches that text exactly must be returned. If the location was left blank, listings from all locations are included.
* **Property Type Filter**: If the guest specified a property type (such as Apartment, House, or Villa), only listings matching that type must be returned. If left blank, all types are included.
* **Price Bounds**: If a minimum price was specified, the nightly price must be greater than or equal to that figure. If a maximum price was specified, the nightly price must not exceed that figure.

---

## 4. Step-by-Step Instructions for Issue #41: Client-Streaming User Registration

### Objective
Implement the server-side handler for the `create_users` remote procedure call. It must accept an open stream of user profiles, store each one in memory, and return a single summary confirmation when the stream ends.

### Step 1: Initialize the Stream Handler
In the service file (`rentalservice_service.bal`), locate the `create_users` function. It receives an incoming client stream carrying user messages. At the start of the function:
* Log an informational message indicating that a client stream has been received.
* Initialise an integer counter set to zero to keep track of how many users are registered during this call.

### Step 2: Read Messages in a Loop
The incoming stream must be read message by message:
* Request the first item from the client stream.
* Enter a loop that continues as long as valid user messages keep arriving.
* Inside the loop, extract the user profile and pass it to the storage layer to be saved into memory.
* Increment the registration counter by one.
* Log an informational message detailing the user's role (Host or Guest), name, and user identifier.
* Request the next item from the stream before repeating the loop.

### Step 3: Handle Stream Errors and Completion
Once the loop finishes:
* Check whether the stream ended because of a transmission error. If an error occurred, log the error and return it to the caller.
* If the stream closed normally without errors, log that the stream has completed along with the final tally of registered users.
* Return exactly one confirmation response containing the total count of registered users, an informative message, and a boolean flag set to true indicating success.

---

## 5. Step-by-Step Instructions for Issue #42: Server-Streaming Property Browsing

### Objective
Implement the server-side handler for the `list_available_properties` remote procedure call. It must accept an optional search filter from a guest, query the store for available listings, and stream them back one by one.

### Step 1: Log the Request and Criteria
In the service file (`rentalservice_service.bal`), locate the `list_available_properties` function. It receives a request record containing optional filter values (location, property type, minimum price, maximum price):
* Log an informational message recording that a search request was received, including the requested filter parameters.

### Step 2: Query the Storage Layer
Call the property store's filtering method, passing the search request payload:
* The store applies all business criteria: it keeps only listings marked as Available and narrows them based on any location, type, or price limits supplied.
* The store returns a collection of matching property records.
* Log the number of matching properties found.

### Step 3: Stream the Results to the Client
Convert the collection of matching properties into an outgoing stream and return it:
* The runtime framework takes each property in the stream and serialises it as an independent protocol buffer message over the open connection.
* The client receives each property individually as it is emitted, satisfying the requirement that items must not be batched into a single response payload.
* Once all matching properties have been emitted, the runtime automatically sends a completion packet to signal the end of the stream.

---

## 6. Automated Testing Strategy

To satisfy the definition of done for both sub-issues, automated unit tests must be added to the test suite (`property_service_test.bal`).

### Test Case 1: Verifying Client-Streaming User Registration
This test validates that multiple user profiles can be registered in a single stream and that the server persists them accurately:
1. **Preparation**: Set up an instance of the property store. Prepare at least three distinct user profiles, ensuring that both Host and Guest roles are represented.
2. **Execution**: Simulate the stream consumption process by iterating through the prepared user profiles and passing each one to the store's user registration function, tracking the iteration count.
3. **Assertions**:
   * Verify that the processed count is exactly three.
   * Query the store to confirm that all three users now reside in the in-memory collection.
   * Retrieve each user individually by their identifier and assert that their saved name, role, email, and phone number match the submitted data without corruption.
   * Confirm that Host profiles and Guest profiles retain their distinct role values.

### Test Case 2: Verifying Server-Streaming Property Browsing
This test validates that available listings are emitted as a sequential stream and that unavailable properties are excluded:
1. **Preparation**: Populate the property store with several listings across different locations and price ranges. Include at least one listing marked with an unavailable status, such as Rented or Maintenance.
2. **Execution (Unfiltered)**:
   * Perform an unfiltered search query (all filter fields left blank or zero).
   * Convert the resulting collection to a stream.
   * Read the stream item by item using a loop.
3. **Assertions (Unfiltered)**:
   * Assert that every single item emitted by the stream has its status set to Available.
   * Assert that the unavailable listing is never emitted.
   * Count the number of emitted items and verify that it equals the exact number of available listings.
4. **Execution and Assertions (Filtered)**:
   * Perform a second query specifying a specific location (such as Swakopmund) and a maximum price.
   * Verify that only properties satisfying both the location criterion and the price ceiling are returned.

---

## 7. Manual Verification and Practical Testing

Workspace guidelines require manual verification against a live running server to confirm real network behaviour.

### Starting the Live Server
1. Open PowerShell and navigate to the `q2_rental_service` package folder.
2. Start the service using the Ballerina run tool.
3. Observe the console logs confirming that the gRPC listener is running on port 9090 (or the port defined in the configuration file).

### Verification with a Client Script
A standalone client script can be used to execute end-to-end network calls against the running server:
1. Instantiate the gRPC client pointing to the local server address.
2. Call the client-streaming registration procedure. Across the returned streaming client, send three distinct user profiles, close the stream, and await the confirmation response. Print the response message and verify that the count equals three.
3. Call the server-streaming property browsing procedure with sample filter criteria. Iterate through the returned property stream, printing each listing's unique asset tag, name, and price as it arrives over the network.

### Verification with Postman
1. Open Postman and switch to the shared PeerPressure workspace.
2. Create a new gRPC request pointing to `http://localhost:9090`.
3. Import the shared contract file (`rental_service.proto`).
4. **Testing User Registration**:
   * Select the `create_users` method.
   * Start the streaming session.
   * Send three individual user messages sequentially.
   * End the stream from the client interface.
   * Confirm that the server returns a single response showing a count of three and a success message.
5. **Testing Property Browsing**:
   * Select the `list_available_properties` method.
   * Provide optional filter criteria.
   * Invoke the call.
   * Observe the response stream timeline, verifying that each matching property appears as an individual message card rather than a single aggregated list.

---

## 8. Step-by-Step Implementation Checklist

When executing this work, follow this structured checklist:

1. **Git Branching**:
   * Create an isolated feature branch named according to the issue conventions, such as `feat/issue-40-streaming-users-and-listings`.

2. **Data Layer Updates**:
   * In `store.bal`, add the private user dictionary to `PropertyStore`.
   * Implement thread-safe functions for adding a user, looking up a user by identifier, and retrieving all users, using synchronized lock blocks and read-only cloning.
   * Review `listAvailableProperties` in `store.bal` to ensure strict filtering on the Available status alongside location, type, and price criteria.

3. **Service Layer Updates**:
   * In `rentalservice_service.bal`, update `create_users` to store each incoming user from the client stream and return a single final confirmation.
   * In `rentalservice_service.bal`, verify that `list_available_properties` queries the store and returns an outgoing stream.

4. **Automated Quality Gates**:
   * Run the test suite using `bal test` and ensure all tests pass cleanly.
   * Run the format verification tool to ensure code style adheres to conventions.
   * Build the package using `bal build` to ensure error-free compilation.

5. **Manual Verification**:
   * Start the service and verify streaming behaviour using a client script or Postman.

6. **Pull Request and Review**:
   * Commit changes using conventional commit messages that reference issues #40, #41, and #42.
   * Push the branch and open a Pull Request.
   * Request peer review and human sign-off before merging into the main branch.
