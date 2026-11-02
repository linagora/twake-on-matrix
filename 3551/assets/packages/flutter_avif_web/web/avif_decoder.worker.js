self.AvifInfo = class AvifInfo { constructor(width, height, imageCount, duration) { this.width = width; this.height = height; this.imageCount = imageCount; this.duration = duration; } };
self.AvifFrame = class AvifFrame { constructor(data, width, height, duration) { this.data = data; this.width = width; this.height = height; this.duration = duration; } };

self.onmessage = function(ev) {
    var message = ev.data;

    switch(message.method) {
        case 'load':
            load(message);
            break;
        case 'decodeSingleFrameImage':
            decodeSingleFrameImage(message);
            break;
        case 'initMemoryDecoder':
            initMemoryDecoder(message);
            break;
        case 'getNextFrame':
            getNextFrame(message);
            break;
        case 'resetDecoder':
            resetDecoder(message);
            break;
        case 'disposeDecoder':
            disposeDecoder(message);
            break;
        default:
            break;
    }
}

function load(message) {
    importScripts("./avif_decoder.js");
    avif_decoder_wasm().then(function(_module) {
        self.wasm_bindgen = _module;
        self.postMessage({
            method: message.method,
            callbackId: message.callbackId,
            data: null
        });
    });
}

function decodeSingleFrameImage(message) {
    var decoded = wasm_bindgen.decodeSingleFrameImage(message.data);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: { data: decoded.data, duration: decoded.duration, width: decoded.width, height: decoded.height }
    }, [decoded.data.buffer]);
}

function initMemoryDecoder(message) {
    var decoded = wasm_bindgen.initMemoryDecoder(message.data[0], message.data[1]);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: { width: decoded.width, height: decoded.height, imageCount: decoded.imageCount, duration: decoded.duration }
    });
}

function getNextFrame(message) {
    var decoded = wasm_bindgen.getNextFrame(message.data);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: { data: decoded.data, duration: decoded.duration, width: decoded.width, height: decoded.height }
    }, [decoded.data.buffer]);
}

function resetDecoder(message) {
    wasm_bindgen.resetDecoder(message.data);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: { }
    });
}

function disposeDecoder(message) {
    wasm_bindgen.disposeDecoder(message.data);
    self.postMessage({
        method: message.method,
        callbackId: message.callbackId,
        data: { }
    });
}