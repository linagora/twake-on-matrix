function handleNotifications(title, body, icon, roomid, eventId) {
    if ('Notification' in window) {
        if (Notification.permission !== 'granted') {
            console.log('Notifications not granted');
            return;
        }
        var notification = new Notification(title, {
            body: body,
            icon: icon,
        });

        notification.onclick = function() {
            console.log('JsFunction::handleNotifications(): On click notification');
            var hrefSplit = window.location.href.split('/');
            var indexRooms = hrefSplit.indexOf('rooms');
            var redirectURL = hrefSplit.splice(0, indexRooms + 1).join('/') + '/' + roomid + (eventId ? '?event=' + eventId : '')
            window.parent.parent.focus();
            window.location.href = redirectURL;
            notification.close();
        };
    } else {
        console.log('Notifications not supported in this browser');
    }
}
