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
   * Architecture: Protocol Buffers v3 + Ballerina gRPC Service and Client
   * Streaming: Unary, Client-streaming (`create_users`), and Server-streaming (`list_available_properties`)

---

## 2. Repository Layout

```text
.
├── q1_library_service/        # Question 1: REST Service, Models, Store, CLI Client
├── postman/                   # Postman Collections and Environments (Local Mode v3 YAML)
├── docs/                      # Team collaboration, architecture, and Postman guides
├── .agents/                   # Coding standards, workspace rules, and agent skills
├── AGENTS.md                  # Comprehensive developer and agent workflow guidelines
└── README.md                  # Root project documentation
```

---

## 3. Quick Start (Question 1)

```bash
# Navigate to Question 1 service
cd q1_library_service

# Build package
bal build

# Run automated test suite
bal test

# Start the REST Service
bal run
```

---

## 4. Development Workflow & Contribution Rules

* **Branching Model**: All work is tracked in Linear (`PEE` team) on dedicated branches (`boiihertz/<issue-id>-<desc>` or `feat/<issue-id>-<desc>`).
* **Quality Gates**: Every pull request must pass `bal test`, `bal format`, and `bal build` before merging.
* **Naming Standards**: Primary entity keys across both questions must use `assetTag` in camelCase.
