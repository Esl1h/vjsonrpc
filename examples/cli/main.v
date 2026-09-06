// Reads one JSON-RPC message per line from stdin, decodes it, and prints
// what it parsed to. Meant to be piped a fixture file to see the library
// react to well-formed and malformed input side by side.
module main

import os
import vjsonrpc

fn main() {
	for line in os.get_lines() {
		if line.trim_space() == '' {
			continue
		}
		req := vjsonrpc.decode_request(line) or {
			println('invalid: ${err}')
			continue
		}
		kind := if req.is_notification { 'notification' } else { 'request' }
		println('${kind} method=${req.method} id=${req.id.str()}')
	}
}
