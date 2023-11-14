function handleNotifications(title, body, icon, roomid) {
    if ('Notification' in window) {
        Notification.requestPermission().then(function(permission) {
            if (permission === 'granted') {
                var notification = new Notification(title, {
                    body: body,
                    icon: icon,
                });

                notification.onclick = function() {
                    console.log('JsFunction::handleNotifications(): On click notification');
                    var hrefSplit = window.location.href.split('/');
                    var indexRooms = hrefSplit.indexOf('rooms');
                    var redirectURL = hrefSplit.splice(0, indexRooms + 1).join('/') + '/' + roomid;
                    window.parent.parent.focus();
                    window.location.href = redirectURL;
                    notification.close();
                };
            } else {
                console.log('Permission for notifications denied');
            }
        }).catch(function(err) {
            console.error('Error requesting permission:', err);
        });
    } else {
        console.log('Notifications not supported in this browser');
    }
}