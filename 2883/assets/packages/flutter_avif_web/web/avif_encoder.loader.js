var avif_encoder = null;

function avifEncoderLoad(workerPath) {
    avif_encoder = { worker: new Worker(workerPath), callbacks: {} };
    avif_encoder.worker.onmessage = function(ev) {
        var message = ev.data;

        if(avif_encoder.callbacks[message.callbackId]) {
            avif_encoder.callbacks[message.callbackId](message.data);
            delete avif_encoder.callbacks[message.callbackId];
        }
    }

    avif_encoder.encode = function(pixels, durations, options, exifData) {
        return avif_encoder.postMessageAsync({ method: 'encode', data: [pixels, durations, options, exifData] }, [pixels.buffer, durations.buffer, exifData.buffer]);
    }

    avif_encoder.decode = function(data, orientation) {
        return avif_encoder.postMessageAsync({ method: 'decode', data: data, orientation: orientation }, [data.buffer]);
    }

    avif_encoder.makeId = function() {
        return Math.random().toString(36).slice(2, 10);
    }

    avif_encoder.postMessageAsync = function(message) {
        var promise = new Promise(function(resolve, reject) {
            var id = avif_encoder.makeId();
            message.callbackId= id;
            avif_encoder.callbacks[id] = resolve;
            avif_encoder.worker.postMessage(message);
        });

        return promise;
    }

    return avif_encoder.postMessageAsync({ method: 'load', data: null });
}