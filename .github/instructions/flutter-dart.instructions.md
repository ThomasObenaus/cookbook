---
description: "Use when developing Flutter applications or writing, reviewing, and refactoring Dart code. Covers code structure, widgets, state management, async safety, and validation."
applyTo: "**/*.dart,**/pubspec.yaml,**/analysis_options.yaml"
---

# Flutter and Dart Development

## Project Conventions

- Follow the project's SDK constraints, analyzer configuration, and existing conventions. Do not change lint rules to silence problems.
- Keep changes scoped to the requested behavior. Do not reorganize unrelated code or edit generated files and build output manually.
- Reuse existing dependencies and helpers. Explain the need and obtain agreement before adding a dependency or changing architecture.

## Structure and Responsibilities

- Keep widgets focused on presentation and user interaction. Move nontrivial business logic and data access out of widget build methods into testable components.
- Group related code by feature as the application grows, following the existing layout. Do not introduce empty layers or a large folder hierarchy for a small feature.
- Extract a widget or class when it has a distinct responsibility, is reused, or materially improves readability or testing. Avoid arbitrary file-length limits and single-use abstractions without a clear benefit.
- Keep app startup focused on configuration and composition; place substantial feature implementations in their owning files.
- Inject external dependencies through constructors or the established dependency-injection mechanism so logic can be tested without real network or platform services.

## State Management

- Follow the project's existing state-management approach. Do not introduce or migrate to Riverpod, Bloc/Cubit, or another framework without explicit user agreement.
- This project currently uses StatefulWidget and setState. Keep simple widget-local state local; do not add a framework solely for consistency with a personal preference.
- Scope shared state to the narrowest owner that needs it. Do not use mutable global variables as a substitute for deliberate state ownership.
- Keep one source of truth and derive values where practical instead of maintaining duplicate state.
- If a new approach is needed, explain the concrete requirement, tradeoffs, and migration impact before proposing a choice.

## Dart Code Quality

- Use sound null safety and precise types. Avoid dynamic, unchecked casts, and null assertions unless a verified boundary requires them.
- Prefer final for values that are not reassigned, const for compile-time constants and eligible widget constructors, and immutable models for shared state.
- Use lower_snake_case for files, UpperCamelCase for types, and lowerCamelCase for members and variables. Name values by their domain meaning and keep implementation details private.
- Use required named parameters for required configuration where that improves call-site clarity. Keep functions focused and prefer straightforward control flow.
- Convert external data into typed models at the boundary and validate missing or malformed values. Use enums or sealed types when they clarify a finite set of states.
- Handle specific exceptions at an appropriate boundary. Preserve useful error context and never swallow failures silently or log secrets.
- Document public contracts and non-obvious decisions when necessary; avoid comments that merely repeat the code.

## Widgets and Async Safety

- Keep build methods free of side effects. Do not start requests, mutate state, or create persistent controllers during build.
- Keep State.setState callbacks synchronous; perform asynchronous work outside them. After an async gap, check mounted or context.mounted as appropriate before touching widget state or using that BuildContext.
- Dispose owned controllers, focus nodes, subscriptions, and other resources at the correct lifecycle boundary. Do not dispose resources owned elsewhere.
- Account for overlapping requests and stale responses where relevant. Represent loading, empty, success, and error states explicitly when the feature needs them.
- Use small composable widgets and stable keys where identity matters. Do not introduce keys, caching, or rebuild optimizations without a concrete need.
- Follow the existing theme and component patterns. Support constrained layouts, large text, keyboard and screen-reader access; avoid fixed dimensions that clip content.

## Verification

- Add or update focused tests for changed behavior: unit tests for pure logic, widget tests for UI interactions, and integration tests for critical cross-component flows.
- Reuse existing test helpers. Keep tests deterministic by controlling time and external dependencies rather than relying on arbitrary delays or live services.
- Format changed Dart files with dart format and run flutter analyze --fatal-infos --fatal-warnings. Run the affected tests first, then broader checks when shared behavior changes.
- After Flutter code changes, hot reload or restart a connected development app when available and check for runtime errors. This supplements rather than replaces automated tests.
- Report which checks ran and any failures or unavailable checks. Do not claim successful validation without observing the result.
