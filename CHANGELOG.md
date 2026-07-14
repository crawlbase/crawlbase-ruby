# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-07-15

### Added

- `cb_status` as the preferred public attribute for Crawlbase status on `Crawlbase::API` (and subclasses) and `Crawlbase::StorageAPI`.
- Status resolution prefers the `cb_status` response header or JSON field, then falls back to `pc_status` when `cb_status` is absent.

### Deprecated

- `pc_status` is deprecated but still supported and returns the same resolved value as `cb_status`. A one-time deprecation warning is emitted when `pc_status` is accessed. Prefer `cb_status`. Removal is planned for a future major release.

### Migration

```ruby
# Before (deprecated)
response.pc_status

# After (preferred)
response.cb_status
```
