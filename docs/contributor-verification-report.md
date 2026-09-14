# Contributor Verification and Code Ownership Report

**Project:** Distributed Systems & Applications (DSA612S) Assignment 1  
**Team Name:** Peer Pressure (`PEE`)  
**Lead:** Jaden Awaseb  
**Date of Audit:** 14 September 2026  
**Repository:** [CodeGrogu/DSA-Assignment](https://github.com/CodeGrogu/DSA-Assignment)

---

## 1. Executive Summary and Purpose

In accordance with the academic integrity and group-work requirements stipulated in the DSA612S assignment specification, this report documents the git provenance, individual contribution spread, and module ownership for all eight members of the Peer Pressure team.

Every team member has made direct, verifiable git commits to the codebase, spanning the development of Question 1 (REST Library Management System), Question 2 (gRPC Rental Accommodation System), automated testing suites, Postman API collections, and technical documentation.

---

## 2. Git Commit Audit (`git shortlog -sne --all`)

The authoritative git log across all branches was extracted and verified using `git shortlog -sne --all`:

```text
    13  Jaden <acehood3556@gmail.com>
     7  Henchoz <henryheita0@gmail.com>
     6  Jaden <73761054+CodeGrogu@users.noreply.github.com>
     5  Kataliina <kataliinamassipa@gmail.com>
     4  Nangu.Tjizoo <knangukuii@gmail.com>
     3  Jerganov <klvntapiwa3@gmail.com>
     2  Florriinnddaa <florinda.funya@gmail.com>
     2  Kondwani112206 <kondwanikunkwenzu@gmail.com>
     2  Liina Massipa <162906488+LiinaMassipa@users.noreply.github.com>
     1  May-Lee Mulundu <117192151+itsyagirlmay@users.noreply.github.com>
     1  kondwani11220 <kondwanikunkwenzu@gmail.com>
```

### Key Observations:
- **Total Commit Distribution:** A genuine, collaborative spread across all 8 students.
- **No Single-Author Monopoly:** Contributions are shared across core services, data models, streaming handlers, booking systems, testing, and documentation.
- **Email Identity Consolidation:** Team members committing from multiple devices or GitHub web interfaces are mapped in the ownership matrix below.

---

## 3. Team Member Attribution and Module Ownership Matrix

| # | Student Name | Git Author Identifiers | Primary Module Ownership & Architectural Contributions |
| :- | :--- | :--- | :--- |
| 1 | **Jaden Awaseb** (Lead) | `Jaden <acehood3556@gmail.com>`<br>`Jaden <73761054+CodeGrogu@users.noreply.github.com>` | Project architecture, Q1 REST service scaffolding, Q1 thread-safe `AssetStore` with mutex locks, Q2 gRPC client implementation (PEE-51), test harnesses, and quality gate automation. |
| 2 | **Henry Heita** | `Henchoz <henryheita0@gmail.com>` | Q1 REST resource methods, query filtering by institution and site, asset modification handlers, and endpoint unit tests. |
| 3 | **Kataliina (Liina) Massipa** | `Kataliina <kataliinamassipa@gmail.com>`<br>`Liina Massipa <162906488+LiinaMassipa@users.noreply.github.com>` | Q1 canonical asset records, data validation, CRUD test suite design, and endpoint validation testing (PEE-11). |
| 4 | **Nangu Tjizoo** | `Nangu.Tjizoo <knangukuii@gmail.com>` | Q2 gRPC streaming RPCs: client-streaming user registration (`create_users`), server-streaming property browsing (`list_available_properties`), and stream unit tests (Issues #40, #41, #42). |
| 5 | **Tapiwa Kelvin Jerganov** | `Jerganov <klvntapiwa3@gmail.com>` | Postman Local Mode v3 YAML test suites, shared environment templates (`peerpressure-local`), and API contract testing (PEE-8). |
| 6 | **Kondwani Kunkwenzu** | `Kondwani112206 <kondwanikunkwenzu@gmail.com>`<br>`kondwani11220 <kondwanikunkwenzu@gmail.com>` | Q1 schedule management, overdue item detection, asset status checking, and Q2 property store CRUD operations. |
| 7 | **Florinda Funya** | `Florriinnddaa <florinda.funya@gmail.com>` | Repository onboarding documentation, setup and execution guides, client terminal workflow walkthroughs, and contributor verification documentation. |
| 8 | **May-Lee Mulundu** | `May-Lee Mulundu <117192151+itsyagirlmay@users.noreply.github.com>` | Q2 booking business logic: two-phase reservation flow (`book_property` + `confirm_booking`), temporary cart management, and date overlap calculations. |

---

## 4. Academic Integrity and Group Work Declaration

The Peer Pressure team hereby declares:

1. **Genuine Group Collaboration:** The code, test harnesses, documentation, and configuration files in this repository represent the collaborative, original work of the eight team members listed above.
2. **Individual Comprehension:** Each team member understands the architectural principles, code paths, and test scenarios within their assigned modules, and is fully prepared to explain and defend the implementation during project evaluations and viva sessions.
3. **Responsible Tool Usage:** Where development tools, IDE linters, or AI coding assistants were utilised to support development, all outputs were independently reviewed, refactored, tested, and verified by human team members to ensure correctness, adherence to course constraints, and code quality. The submission is not an unverified or automated AI dump.
4. **Course Compliance:** The project strictly complies with the Namibia University of Science and Technology (NUST) academic integrity policy and the specific requirements of the Distributed Systems & Applications (DSA612S) course.
