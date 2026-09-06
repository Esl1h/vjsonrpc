module vjsonrpc

import json2

// new_request builds a request that expects a reply.
pub fn new_request(id json2.Any, method string, params json2.Any) Request {
	return Request{
		id: id
		method: method
		params: params
	}
}

// new_notification builds a request that gets no reply: no "id" is sent.
pub fn new_notification(method string, params json2.Any) Request {
	return Request{
		method: method
		params: params
		is_notification: true
	}
}

// new_response builds a successful reply.
pub fn new_response(id json2.Any, result json2.Any) Response {
	return Response{
		id: id
		result: result
	}
}

// new_error_response builds a failed reply.
pub fn new_error_response(id json2.Any, err RpcError) Response {
	return Response{
		id: id
		error: err
	}
}

// err_parse builds the error for request text that was not valid JSON.
pub fn err_parse(data json2.Any) RpcError {
	return RpcError{
		code: code_parse_error
		message: 'Parse error'
		data: data
	}
}

// err_invalid_request builds the error for JSON that is not a valid
// JSON-RPC envelope.
pub fn err_invalid_request(data json2.Any) RpcError {
	return RpcError{
		code: code_invalid_request
		message: 'Invalid Request'
		data: data
	}
}

// err_method_not_found builds the error for a valid envelope whose
// "method" is unknown to the caller's own dispatch table.
pub fn err_method_not_found(data json2.Any) RpcError {
	return RpcError{
		code: code_method_not_found
		message: 'Method not found'
		data: data
	}
}

// err_invalid_params builds the error for a known "method" whose "params"
// doesn't match what that method expects.
pub fn err_invalid_params(data json2.Any) RpcError {
	return RpcError{
		code: code_invalid_params
		message: 'Invalid params'
		data: data
	}
}

// err_internal builds the error for when the caller's own handler failed
// for a reason unrelated to the request's shape.
pub fn err_internal(data json2.Any) RpcError {
	return RpcError{
		code: code_internal_error
		message: 'Internal error'
		data: data
	}
}
