// Package vjsonrpc implements the JSON-RPC 2.0 message layer: framing,
// validation, and the standard error codes. It carries no transport of its
// own (stdio, socket, HTTP are all up to the caller) and no dependency
// beyond the V standard library.
module vjsonrpc

import json2

pub const version = '2.0'

pub const code_parse_error = -32700
pub const code_invalid_request = -32600
pub const code_method_not_found = -32601
pub const code_invalid_params = -32602
pub const code_internal_error = -32603

pub struct RpcError {
pub:
	code    int
	message string
	data    json2.Any = json2.null
}

pub struct Request {
pub:
	id     json2.Any = json2.null
	method string
	params json2.Any = json2.null
	// is_notification is true when the message carried no "id" field at
	// all. A request with id: null is legal (if discouraged) JSON-RPC and
	// is not a notification, so this can't be inferred from id alone.
	is_notification bool
}

pub struct Response {
pub:
	id     json2.Any = json2.null
	result json2.Any = json2.null
	error  ?RpcError
}
