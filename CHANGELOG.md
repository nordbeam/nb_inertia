# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- `inertia_shared do ... end` macro now correctly registers inline shared props
  (was silently discarding them due to macro clause ordering)
- Props with `from: :assigns` are no longer incorrectly flagged as "missing required props"
  in compile-time validation
- Prop collision detection between shared props and page props now works correctly

### Added
- Comprehensive compile-time validation test suite (`test/nb_inertia/compile_time_validation_test.exs`)
