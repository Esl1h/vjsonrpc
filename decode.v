module vjsonrpc

import json2

// is_valid_id reports whether v is a legal JSON-RPC id: a string, a number,
// or null. json2 decodes every bare JSON number as f64, integer-looking or
// not, so there is no separate integer case to check here.
fn is_valid_id(v json2.Any) bool {
	return v is string || v is f64 || v is json2.Null
}

// try_extract_id best-efforts an id out of an otherwise-invalid message, so
// a caller can still build a spec-correct error Response for it. Per the
// spec, an id that cannot be determined must be reported as null.
fn try_extract_id(v json2.Any) json2.Any {
	if v !is map[string]json2.Any {
		return json2.null
	}
	obj := v.as_map()
	id := obj['id'] or { return json2.null }
	if !is_valid_id(id) {
		return json2.null
	}
	return id
}

// request_from_value validates a decoded JSON value as a JSON-RPC request
// or notification. The returned error is a plain V error describing what
// is wrong with the envelope; mapping that to code_invalid_request is left
// to the caller, since only the caller knows whether it can even reply
// (e.g. a notification's errors are usually silently dropped).
pub fn request_from_value(v json2.Any) !Request {
	if v !is map[string]json2.Any {
		return error('expected a JSON object')
	}
	obj := v.as_map()

	jv := obj['jsonrpc'] or { return error('missing "jsonrpc"') }
	if jv !is string || jv.str() != version {
		return error('"jsonrpc" must be "2.0"')
	}

	mv := obj['method'] or { return error('missing "method"') }
	if mv !is string {
		return error('"method" must be a string')
	}

	params := obj['params'] or { json2.Any(json2.null) }
	if !(params is map[string]json2.Any || params is []json2.Any || params is json2.Null) {
		return error('"params" must be an object, an array, or omitted')
	}

	has_id := 'id' in obj
	id := if has_id { obj['id'] or { json2.Any(json2.null) } } else { json2.Any(json2.null) }
	if has_id && !is_valid_id(id) {
		return error('"id" must be a string, a number, or null')
	}

	return Request{
		id: id
		method: mv.str()
		params: params
		is_notification: !has_id
	}
}

// response_from_value validates a decoded JSON value as a JSON-RPC
// response: exactly one of "result" or "error" must be present.
pub fn response_from_value(v json2.Any) !Response {
	if v !is map[string]json2.Any {
		return error('expected a JSON object')
	}
	obj := v.as_map()

	jv := obj['jsonrpc'] or { return error('missing "jsonrpc"') }
	if jv !is string || jv.str() != version {
		return error('"jsonrpc" must be "2.0"')
	}

	id := obj['id'] or { return error('missing "id"') }
	if !is_valid_id(id) {
		return error('"id" must be a string, a number, or null')
	}

	has_result := 'result' in obj
	has_error := 'error' in obj
	if has_result == has_error {
		return error('response must have exactly one of "result" or "error"')
	}

	if has_error {
		ev := obj['error'] or { json2.Any(json2.null) }
		if ev !is map[string]json2.Any {
			return error('"error" must be an object')
		}
		eobj := ev.as_map()
		codev := eobj['code'] or { return error('"error.code" is required') }
		msgv := eobj['message'] or { return error('"error.message" is required') }
		if codev !is f64 {
			return error('"error.code" must be a number')
		}
		if msgv !is string {
			return error('"error.message" must be a string')
		}
		data := eobj['data'] or { json2.Any(json2.null) }
		return Response{
			id: id
			error: RpcError{
				code: int(codev.f64())
				message: msgv.str()
				data: data
			}
		}
	}

	result := obj['result'] or { json2.Any(json2.null) }
	return Response{
		id: id
		result: result
	}
}

// decode_request parses and validates a single request or notification.
pub fn decode_request(raw string) !Request {
	val := json2.decode[json2.Any](raw)!
	return request_from_value(val)
}

// decode_response parses and validates a single response.
pub fn decode_response(raw string) !Response {
	val := json2.decode[json2.Any](raw)!
	return response_from_value(val)
}

// BatchItem is one element of a decoded request batch. err is empty when
// request is valid; when it is not, id is a best-effort extraction so the
// caller can still build a spec-correct error Response for that element
// without failing the whole batch.
pub struct BatchItem {
pub:
	request Request
	id      json2.Any = json2.null
	err     string
}

// decode_request_batch parses a batch (a JSON array of requests). An
// individual malformed element does not fail the whole batch; it comes
// back as a BatchItem with err set, per the spec's per-element tolerance.
pub fn decode_request_batch(raw string) ![]BatchItem {
	val := json2.decode[json2.Any](raw)!
	if val !is []json2.Any {
		return error('expected a JSON array for a batch')
	}
	items := val.as_array()
	if items.len == 0 {
		return error('batch array must not be empty')
	}

	mut out := []BatchItem{}
	for item in items {
		req := request_from_value(item) or {
			out << BatchItem{
				id: try_extract_id(item)
				err: err.msg()
			}
			continue
		}
		out << BatchItem{
			request: req
		}
	}
	return out
}
