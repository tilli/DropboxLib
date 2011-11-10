import QtQuick 1.0

Rectangle {

    width: 360
    height: 640
    id: root

    property alias accessToken: login.accessToken
    property alias userUid: login.userUid

    // --------------------------

    // Example login page usage
    //  - start() / stop() / running property to control login process
    //  - running turns to false when login process is over
    //  - accessToken property is available if login succeeds
    //  - interactive property determines when user needs to input something
    DropboxLogin {
        id: login
        anchors.fill: parent
        opacity: 0
        Component.onCompleted: running = true

        // Hide when there's access token available
        states: State {
            when: login.interactive
            PropertyChanges { target: login; opacity: 1 }
        }
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }

    onAccessTokenChanged: console.debug("Got token: " + accessToken);
    onUserUidChanged: console.log("Got UID: " + userUid);
}
