var avif_decoder = null;

function avifDecoderLoad(workerPath) {
    avif_decoder = { worker: new Worker(workerPath), callbacks: {} };
    avif_decoder.worker.onmessage = function(ev) {
        var message = ev.data;

        if(avif_decoder.callbacks[message.callbackId]) {
            avif_decoder.callbacks[message.callbackId](message.data);
            delete avif_decoder.callbacks[message.callbackId];
        }
    }

    avif_decoder.decodeSingleFrameImage = function(data) {
        return avif_decoder.postMessageAsync({ method: 'decodeSingleFrameImage', data: data }, [data.buffer]);
    }

    avif_decoder.initMemoryDecoder = function(key, data) {
        return avif_decoder.postMessageAsync({ method: 'initMemoryDecoder', data: [key, data] }, [data.buffer]);
    }

    avif_decoder.getNextFrame = function(key) {
        return avif_decoder.postMessageAsync({ method: 'getNextFrame', data: key });
    }

    avif_decoder.resetDecoder = function(key) {
        return avif_decoder.postMessageAsync({ method: 'resetDecoder', data: key });
    }

    avif_decoder.disposeDecoder = function(key) {
        return avif_decoder.postMessageAsync({ method: 'disposeDecoder', data: key });
    }

    avif_decoder.makeId = function() {
        return Math.random().toString(36).slice(2, 10);
    }

    avif_decoder.postMessageAsync = function(message) {
        var promise = new Promise(function(resolve, reject) {
            var id = avif_decoder.makeId();
            message.callbackId= id;
            avif_decoder.callbacks[id] = resolve;
            avif_decoder.worker.postMessage(message);
        });

        return promise;
    }

    return avif_decoder.postMessageAsync({ method: 'load', data: null });
}