module vjsonrpc

import json2

fn test_request_encode_includes_id_and_params() {
	req := new_request('abc', 'ping', json2.Any({
		'n': json2.Any(1)
	}))
	assert req.encode() == '{"jsonrpc":"2.0","method":"ping","params":{"n":1},"id":"abc"}'
}

fn test_notification_encode_omits_id() {
	note := new_notification('log', json2.null)
	encoded := note.encode()
	assert !encoded.contains('"id"')
	assert encoded == '{"jsonrpc":"2.0","method":"log"}'
}

fn test_response_encode_success() {
	resp := new_response(1, 'pong')
	assert resp.encode() == '{"jsonrpc":"2.0","id":1,"result":"pong"}'
}

fn test_response_encode_error() {
	resp := new_error_response(2, err_method_not_found(json2.null))
	assert resp.encode() == '{"jsonrpc":"2.0","id":2,"error":{"code":-32601,"message":"Method not found"}}'
}

fn test_decode_request_roundtrip() {
	req := decode_request('{"jsonrpc":"2.0","method":"ping","id":1}') or {
		assert false, err.msg()
		return
	}
	assert req.method == 'ping'
	assert !req.is_notification
	assert req.id.f64() == 1.0
}

fn test_decode_notification_has_no_id() {
	req := decode_request('{"jsonrpc":"2.0","method":"log"}') or {
		assert false, err.msg()
		return
	}
	assert req.is_notification
}

fn test_decode_request_rejects_wrong_version() {
	if _ := decode_request('{"jsonrpc":"1.0","method":"ping","id":1}') {
		assert false, 'expected an error'
	}
}

fn test_decode_request_rejects_missing_method() {
	if _ := decode_request('{"jsonrpc":"2.0","id":1}') {
		assert false, 'expected an error'
	}
}

fn test_decode_request_rejects_bad_id_type() {
	if _ := decode_request('{"jsonrpc":"2.0","method":"ping","id":{}}') {
		assert false, 'expected an error'
	}
}

fn test_decode_request_rejects_invalid_json() {
	if _ := decode_request('not json') {
		assert false, 'expected an error'
	}
}

fn test_decode_response_success() {
	resp := decode_response('{"jsonrpc":"2.0","id":1,"result":42}') or {
		assert false, err.msg()
		return
	}
	assert resp.result.f64() == 42.0
	if _ := resp.error {
		assert false, 'expected no error field'
	}
}

fn test_decode_response_error() {
	resp := decode_response('{"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not found"}}') or {
		assert false, err.msg()
		return
	}
	rpc_err := resp.error or {
		assert false, 'expected an error field'
		return
	}
	assert rpc_err.code == code_method_not_found
}

fn test_decode_response_rejects_both_result_and_error() {
	raw := '{"jsonrpc":"2.0","id":1,"result":1,"error":{"code":-1,"message":"x"}}'
	if _ := decode_response(raw) {
		assert false, 'expected an error'
	}
}

fn test_decode_response_rejects_neither_result_nor_error() {
	if _ := decode_response('{"jsonrpc":"2.0","id":1}') {
		assert false, 'expected an error'
	}
}

fn test_decode_request_batch_mixed_validity() {
	raw := '[{"jsonrpc":"2.0","method":"a","id":1},{"jsonrpc":"2.0","id":2},{"jsonrpc":"2.0","method":"b"}]'
	items := decode_request_batch(raw) or {
		assert false, err.msg()
		return
	}
	assert items.len == 3
	assert items[0].err == ''
	assert items[0].request.method == 'a'
	assert items[1].err != ''
	assert items[1].id.f64() == 2.0
	assert items[2].err == ''
	assert items[2].request.is_notification
}

fn test_decode_request_batch_rejects_non_array() {
	if _ := decode_request_batch('{"jsonrpc":"2.0","method":"a","id":1}') {
		assert false, 'expected an error'
	}
}

fn test_string_id_roundtrips() {
	req := decode_request('{"jsonrpc":"2.0","method":"m","id":"abc-123"}') or {
		assert false, err.msg()
		return
	}
	assert req.id.str() == 'abc-123'
	assert req.encode().contains('"id":"abc-123"')
}

fn test_null_id_is_valid_and_not_a_notification() {
	req := decode_request('{"jsonrpc":"2.0","method":"m","id":null}') or {
		assert false, err.msg()
		return
	}
	assert !req.is_notification
	assert req.id is json2.Null
}
