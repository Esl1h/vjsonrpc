# vjsonrpc

A [V](https://vlang.io) module implementing the [JSON-RPC 2.0](https://www.jsonrpc.org/specification) message layer: request, notification, response, error codes, and batch parsing with per-element tolerance. No transport of its own, no dependencies beyond the V standard library.

This is meant to become the wire-protocol layer under a future Model Context Protocol server SDK, but it has no MCP-specific code and is useful to anything speaking JSON-RPC over stdio, a socket, or HTTP: LSP-style tools, blockchain RPC clients, whatever needs it.

## Install

```sh
v install https://github.com/Esl1h/vjsonrpc
```

## Usage

```v
import vjsonrpc

req := vjsonrpc.decode_request('{"jsonrpc":"2.0","method":"ping","id":1}') or {
	eprintln(err)
	return
}
if req.is_notification {
	// no reply expected, no "id" was sent
} else {
	resp := vjsonrpc.new_response(req.id, 'pong')
	println(resp.encode())
}
```

Building messages to send:

```v
req := vjsonrpc.new_request(1, 'initialize', params)
println(req.encode())

note := vjsonrpc.new_notification('log', params)
println(note.encode())
```

Standard errors:

```v
resp := vjsonrpc.new_error_response(req.id, vjsonrpc.err_method_not_found(req.method))
println(resp.encode())
```

Batches, with per-element tolerance for a malformed entry (an invalid item doesn't fail the whole batch; it comes back with `err` set instead):

```v
items := vjsonrpc.decode_request_batch(raw) or {
	eprintln(err)
	return
}
for item in items {
	if item.err != '' {
		println(vjsonrpc.new_error_response(item.id, vjsonrpc.err_invalid_request(item.err)).encode())
		continue
	}
	// handle item.request
}
```

## Example CLI

```sh
printf '{"jsonrpc":"2.0","method":"ping","id":1}\n' | v run examples/cli
```

Reads one JSON-RPC message per line from stdin and prints what it parsed to, so a fixture file makes it easy to see well-formed and malformed input handled side by side.

## Development

```sh
make check   # fmt-check + vet + test
make test
make fmt
```

## Scope

Message layer only: this module has no opinion on how bytes reach it (stdio, a socket, HTTP) and no method dispatch table. It decodes JSON-RPC ids as `f64` for numbers per how the underlying JSON decoder works, and re-encodes whole numbers without a trailing `.0`, so numeric ids round-trip correctly. Only string, number, and `null` ids are accepted, matching the spec; an object, array, or boolean id is rejected before it reaches the caller.

## License

MIT
