module vjsonrpc

import json2

// encode serializes a request or notification to its JSON-RPC wire form.
pub fn (r Request) encode() string {
	mut m := map[string]json2.Any{}
	m['jsonrpc'] = version
	m['method'] = r.method
	if r.params !is json2.Null {
		m['params'] = r.params
	}
	if !r.is_notification {
		m['id'] = r.id
	}
	return m.str()
}

// encode serializes a response to its JSON-RPC wire form.
pub fn (r Response) encode() string {
	mut m := map[string]json2.Any{}
	m['jsonrpc'] = version
	m['id'] = r.id
	if err := r.error {
		mut e := map[string]json2.Any{}
		e['code'] = err.code
		e['message'] = err.message
		if err.data !is json2.Null {
			e['data'] = err.data
		}
		m['error'] = e
	} else {
		m['result'] = r.result
	}
	return m.str()
}
