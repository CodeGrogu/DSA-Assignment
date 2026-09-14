# Distributed Systems & Applications (DSA612S) Assignment 1

**Team:** Peer Pressure (`PEE`)
**Lead:** Jaden Awaseb
**Runtime:** Ballerina Swan Lake 2201.13.5

---

## 1. Project Overview

This repository contains the implementation of Assignment 1 for DSA612S, structured into two distributed systems:

1. **Question 1: Library & Resource Management System (REST)**

   * Located in `q1_library_service/` and `q1_library_client/`
   * Architecture: RESTful HTTP API + CLI Client
   * Data Layer: In-memory asset store with isolated lock concurrency

2. **Question 2: Rental Accommodation System (gRPC)**

   * Located in `q2_rental_service/` and `q2_rental_client/`
   * Architecture: Protocol Buffers v3 + Ballerina gRPC Service and Client
   * Streaming: Unary, client-streaming (`create_users`), and server-streaming (`list_available_properties`)

---

## 2. Prerequisites

Before running the project, make sure the following are installed:

* **Ballerina Swan Lake 2201.13.5**
* **Git**
* **Visual Studio Code** or another suitable code editor
* A terminal such as PowerShell, Command Prompt, or Bash

Verify Ballerina is installed:

```bash
bal version
```

The displayed version should be compatible with the project runtime:

```text
2201.13.5
```

---

## 3. Clone and Set Up the Repository

Clone the repository from GitHub:

```bash
git clone https://github.com/CodeGrogu/DSA-Assignment.git
cd DSA-Assignment
```

The repository contains the following main directories:

```text
.
├── q1_library_service/        # Question 1: REST Service, Models, Store
├── q1_library_client/         # Question 1: REST CLI & Interactive Client
├── q2_rental_service/         # Question 2: gRPC Service, Proto Contract, Store
├── q2_rental_client/          # Question 2: gRPC Interactive CLI Client
├── postman/                   # Postman Collections and Environments
├── docs/                      # Technical documentation
├── .agents/                   # Workspace rules and agent skills
├── AGENTS.md                  # Developer and agent workflow guidelines
└── README.md                  # Project documentation
```

---

## 4. Quick Start

### 4.1 Question 1: REST Service & Client

The REST service must be running before starting the client.

### Terminal 1 — Start the REST Service

```bash
cd q1_library_service
bal build
bal test
bal run
```

`bal test` runs the automated tests. It does not keep the service running after the tests finish. Use `bal run` to start the service.

The REST service runs on:

```text
http://localhost:9090
```

### Terminal 2 — Run the CLI Client

Open a second terminal:

```bash
cd q1_library_client
bal build
bal run
```

The client provides an interactive menu for:

1. Check Service Health
2. List All Assets
3. Get Asset by `assetTag`
4. Register New Asset
5. Update Asset Status / Metadata
6. Delete Asset
7. View Asset Status & Work Orders
8. View Overdue Maintenance Assets
9. Attach Component to Asset
10. Attach Schedule to Asset

The client also supports direct commands:

```bash
bal run -- health
bal run -- list
```

Example health response:

```text
Service Health: {"status":"UP", ...}
```

---

### 4.2 Question 2: gRPC Service & Client

### Terminal 1 — Start the gRPC Service

```bash
cd q2_rental_service
bal build
bal test
bal run
```

### Terminal 2 — Run the gRPC Client

```bash
cd q2_rental_client
bal build
bal run
```

To regenerate gRPC stubs from the Protocol Buffers contract:

```bash
bal grpc --input proto/rental_service.proto --output . --mode service
```

---

## 5. Testing

Automated tests can be run from each service directory:

```bash
bal test
```

Build verification can be performed with:

```bash
bal build
```

Code formatting can be checked/applied with:

```bash
bal format
```

For Question 1, the REST service and CLI were tested through an end-to-end session covering the available client operations, including:

* Service health check
* Asset listing
* Asset retrieval
* Asset registration
* Asset update
* Asset status and work-order view
* Overdue maintenance view
* Component attachment
* Schedule attachment
* Asset deletion

---

## 6. Technical Documentation

* [PEE-37: Q2 Proto Contract & Property Management](docs/pee-37-q2-proto-contract-and-property-management.md)
* [PEE-10: Thread-Safe In-Memory Asset Store](docs/pee-10-thread-safe-in-memory-store.md)
* [PEE-9: Canonical Asset Data Models](docs/pee-9-canonical-asset-data-models.md)
* [PEE-8: Project Skeleton & Postman Test Suite](docs/pee-8-project-skeleton-and-postman-suite.md)
* [PEE-7: Library & Resource Management Overview](docs/pee-7-library-and-resource-management-system.md)
* [Postman Team Collaboration Guide](docs/postman-team-collaboration-guide.md)

---

## 7. Development Workflow & Contribution Rules

* **Branching Model:** Work is tracked in Linear under the `PEE` team using dedicated branches such as `feat/<issue-id>-<description>`.
* **Quality Gates:** Pull requests should pass `bal test`, `bal format`, and `bal build` before merging.
* **Naming Standards:** Primary entity keys across the project use `assetTag` in camelCase.

---

## 8. Contributor Verification

The Git repository history was reviewed using:

```bash
git shortlog -sne --all
```

The Git history was checked to confirm that the project contains contributions from the team's members. Some members appear under more than one Git identity because different email addresses were used for commits.


The project reflects genuine collaborative work by the team, with members responsible for understanding and contributing to the submitted implementation.

--- 

## 9. Academic Integrity

This project represents genuine collaborative work by the Peer Pressure team. Each team member is responsible for understanding the work they contributed and being able to explain the submitted implementation.

Where development tools or AI-assisted tools were used for support, the resulting work was reviewed, tested, and understood by the team. The submitted solution is not presented as entirely AI-generated work.

---

## 10. Team

**Peer Pressure (PEE)**

The repository history provides the record of individual contributions made by team members throughout development.
