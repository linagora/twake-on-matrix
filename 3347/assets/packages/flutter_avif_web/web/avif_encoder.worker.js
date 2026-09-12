self.onmessage = function(ev) {
    var message = ev.data;

    switch(message.method) {
        case 'load':
            load(message);
            break;
        case 'encode':
            encode(message);
            break;
        case 'decode':
            decode(message);
            break;
        default:
            break;
    }
}

function load(message) {
    importScripts("./avif_encoder.js");
    wasm_bindgen("./avif_encoder_bg.wasm").then(function() {
        self.postMessage({
            method: message.method,
            callbackId: message.callbackId,
            data: null
        });
    });
}

function encode(message) {
    var encoded = wasm_bindgen.encode(message.data[0], message.data[1], message.data[2], message.data[3]);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: encoded
    }, [encoded.buffer]);
}

function decode(message) {
    var decoded = wasm_bindgen.decode(message.data, message.orientation);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: {
            data: decoded.data,
            durations: decoded.durations,
            width: decoded.width,
            height: decoded.height
        }
    });
}