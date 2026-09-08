# Distributed Systems & Applications (DSA612S) Assignment 1

**Team**: Peer Pressure (`PEE`)  
**Lead**: Jaden Awaseb  
**Runtime**: Ballerina Swan Lake 2201.13.5  

---

## 1. Project Overview

This repository contains the implementation of Assignment 1 for DSA612S, structured into two core distributed systems:

1. **Question 1: Library & Resource Management System (REST)**
   * Located at [`q1_library_service/`](./q1_library_service)
   * Architecture: RESTful HTTP API + CLI Client Interface
   * Data Layer: In-memory table keyed by `assetTag` with isolated lock concurrency
2. **Question 2: Rental Accommodation System (gRPC)**
   * Located at [`q2_rental_service/`](./q2_rental_service)
   * Architecture: Protocol Buffers v3 + Ballerina gRPC Service and Client
   * Streaming: Unary, Client-streaming (`create_users`), and Server-streaming (`list_available_properties`)

---

## 2. Repository Layout

```text
.
├── q1_library_service/        # Question 1: REST Service, Models, Store, CLI Client
├── q2_rental_service/         # Question 2: gRPC Service, Proto Contract, In-Memory Store
├── postman/                   # Postman Collections and Environments (Local Mode v3 YAML)
├── docs/                      # Technical architecture and feature documentation
├── .agents/                   # Coding standards, workspace rules, and agent skills
├── AGENTS.md                  # Comprehensive developer and agent workflow guidelines
└── README.md                  # Root project documentation
```

---

## 3. Quick Start

### 3.1 Question 1: REST Service
```bash
cd q1_library_service

# Build package
bal build

# Run automated test suite
bal test

# Start the REST Service
bal run
```

### 3.2 Question 2: gRPC Service
```bash
cd q2_rental_service

# Build package
bal build

# Run automated test suite
bal test

# Start the gRPC Service (port 9090)
bal run
```

To regenerate stubs from the Protobuf contract:
```bash
bal grpc --input proto/rental_service.proto --output . --mode service
```

---

## 4. Technical Documentation

* [PEE-37: Q2 Proto Contract & Property Management](docs/pee-37-q2-proto-contract-and-property-management.md)
* [PEE-10: Thread-Safe In-Memory Asset Store](docs/pee-10-thread-safe-in-memory-store.md)
* [PEE-9: Canonical Asset Data Models](docs/pee-9-canonical-asset-data-models.md)
* [PEE-8: Project Skeleton & Postman Test Suite](docs/pee-8-project-skeleton-and-postman-suite.md)
* [PEE-7: Library & Resource Management Overview](docs/pee-7-library-and-resource-management-system.md)
* [Postman Team Collaboration Guide](docs/postman-team-collaboration-guide.md)

---

## 5. Development Workflow & Contribution Rules

* **Branching Model**: All work is tracked in Linear (`PEE` team) on dedicated branches (`feat/<issue-id>-<desc>` or `boiihertz/<issue-id>-<desc>`).
* **Quality Gates**: Every pull request must pass `bal test`, `bal format`, and `bal build` before merging.
* **Naming Standards**: Primary entity keys across both questions must use `assetTag` in camelCase.
