// NOTE: This file previously contained a standalone CLI client with a main() function.
// The project root package already contains the REST service. Having a second
// executable at q1_library_service/library_client.bal conflicts with the service
// (duplicate main / package root issues).
//
// The interactive CLI has been moved into the client module:
//   q1_library_service/modules/client/client.bal
//
// To avoid build conflicts, this placeholder file replaces the old CLI. If you
// prefer to remove this file entirely, delete it from the repository.

// Nothing executable in this file to avoid package root conflicts.
