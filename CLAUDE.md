# CLAUDE.md

Instructions for Claude Code working in this repository.

## What this project is

`vjsonrpc` is a small, dependency-free V module implementing the JSON-RPC
2.0 message layer: request/notification/response types, the standard error
codes, and parsing with validation. It answers a request the V community
itself made (vlang/v#25706, closed without an implementation) and is meant
to become the wire-protocol layer under a future MCP server SDK, but it has
no MCP-specific code and no dependency on anything beyond `json2`.

## V is under-represented in your training data — verify, never guess

Same standing rule as every other V project here (`redact` included).
Compile after every meaningful change: `v test .` or `v run examples/cli`.
Check actual stdlib source before assuming a signature:

```sh
grep -n "pub fn" ~/GIT/v/vlib/json2/*.v
```

## Gotchas already found in this codebase — do not rediscover them

- `json2.Any` is a sum type. Its declared variant order puts `[]Any` first,
  so the *zero value* of a missing map key, if you skip `or {}`, is an
  empty array, not `Null` and not a crash. Always use `m[key] or { ... }`
  or check `key in m` first. `v vet` calls this out as a hard warning.
- Every bare JSON number decodes to `f64`, integer-looking or not. There is
  no separate int/i64 branch to match on. `json2` re-encodes a whole-number
  `f64` without a trailing `.0` (`f64(1.0)` -> `"1"`), so id round-tripping
  through `f64` is safe.
- An actual JSON `null` value decodes to the `Null` variant
  (`v is json2.Null`); this is different from a *missing* key, which is the
  `[]Any` zero value above. Don't conflate the two.
- `map[string]Any` has `.str()` directly (it serializes to JSON text); no
  need to wrap it as `json2.Any(m)` first.
- `v vet` requires a function's doc comment to start with `// fn_name ` —
  the function name followed by a space. `// fn_name: does X` (with a
  colon) reads as "incomplete" and still warns. A multi-line comment only
  needs its *first* line to match; vet walks upward through contiguous `//`
  lines looking for the one that starts the block.
- `?T` struct fields (e.g. `error ?RpcError` on `Response`) unwrap with the
  same `if v := field { ... } else { ... }` pattern used for map/array
  access.

## Design decisions worth knowing before changing scope

- `is_notification` is a bool, not inferred from `id`. A request with
  `"id": null` is legal (if discouraged) JSON-RPC and is *not* a
  notification; only the absence of the "id" key makes it one. Don't
  collapse this back into an id check.
- Structural validation (`request_from_value`, `response_from_value`)
  returns a plain V error, not an `RpcError`. Mapping that string to
  `code_parse_error` vs `code_invalid_request` is the caller's job, because
  only the caller knows whether a reply is even owed (a notification's
  parse failure is usually just dropped, not answered).
- `decode_request_batch` gives per-element tolerance (a `BatchItem` with
  `err` set, not a failed whole-batch call), because the spec requires a
  server to still answer the valid elements of an otherwise-mixed batch.
  `decode_response` and single `decode_request` are fail-fast on purpose;
  only the batch path needed the extra complexity.
- No batch support for responses. Batching responses is a client-side
  concern this module hasn't needed yet; add it the same way as the
  request batch if a caller needs it, don't guess ahead of that need.

## Build and test

```sh
make check   # fmt-check + vet + test
make test    # v test .
make fmt     # v fmt -w .
```

Always run `make check` before proposing a commit.

## Do not

- Add a dependency beyond `json2`. Any transport, method dispatch, or
  MCP-specific behavior belongs in a caller, not here.
- Add HTTP or stdio transport code to this module. It is deliberately
  transport-agnostic; that split is what lets it be reused outside MCP.
