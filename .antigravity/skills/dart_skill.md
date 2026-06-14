# Dart Skill

## Null-Safety Discipline
- **Avoid Null Assertion Operators (`!`):** Avoid using the null assertion operator (`!`) unless checking for null explicitly before. Prefer using null-aware operators (`?.`, `??`, `??=`) or conditional checks (`if (value != null)`).
- **Explicit Types:** State type definitions explicitly for public API declarations instead of relying solely on `var` or `dynamic`.
- **Constructor Parameters:** Use `required` markers for parameters that should never be null, and mark optional parameters with `?`.

## Immutable Model Handling
- **Immutable Types:** Declare domain classes using the `const` constructor when possible. All model fields should be marked `final`.
- **Modify State Safely:** Implement a `copyWith` method on domain structures to generate modified instances without altering the original values directly.
- **Equality Checks:** Override `operator ==` and `hashCode` or use packages to ensure value-based equality rather than reference equality for structures.

## Async/Await & Error Handling
- **Handle Futures Safely:** Never leave a `Future` un-awaited without proper handling. Use `try-catch` structures around asynchronous boundaries.
- **Avoid Empty Catch Blocks:** Always log or handle exceptions. Provide fallback values if an operation fails to prevent runtime crashes.
- **Streams Management:** Cancel subscriptions to `Stream` instances inside widget `dispose()` methods or use Riverpod providers that handle resource cleanup automatically.

## Sorting and Filtering Conventions
- **Case-Insensitive Sorting:** Standardize alphabetical sorting using string comparison helpers (e.g., `name.toLowerCase().compareTo(...)` or database-level collators like `COLLATE NOCASE`).
- **Date Handling:** Standardize dates using UTC ISO-8601 strings (`yyyy-MM-dd` or `yyyy-MM-ddTHH:mm:ss.SSSZ`) to simplify storage comparison and timezone conversions.
