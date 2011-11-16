import QtQuick 1.0
import QtWebKit 1.0
import "js/DropboxAuth.js" as DropboxAuth

Item {

    // Access token if login succeeds
    property string accessToken

    // UID of the user
    property string userUid

    // Cannot bind directly to loginTimer.running, since timer will be
    // stopped in intermediate stage, while waiting for user feedback
    property bool running

    // Flag to determine required user interaction
    // This item can be kept invisible until this flag turns to true
    property bool interactive

    // Timeout for login
    property alias timeout: loginTimer.interval

    function start() {
        if (!running) {
            privObj.start();
        }
    }

    function stop() {
        if (running) {
            privObj.stop();
        }
    }

    onRunningChanged: if (running) { privObj.start(); } else { privObj.stop(); }

    id: rootItem

    QtObject {
        id: privObj
        property string requestToken
        property string requestTokenSecret
        property string accessToken
        property string accessTokenSecret
        function start() {
            DropboxAuth.loadToken(
                        function(token, secret) {
                            privObj.requestToken = token;
                            privObj.requestTokenSecret = secret;
                            webView.url = "https://www.dropbox.com/1/oauth/authorize?oauth_token=" + token + "&oauth_callback=http://localhost"
                        },
                        function(errorCode) {
                            console.log("REQUEST TOKEN FAILED: " + errorCode);
                            Qt.quit();
                        });
            rootItem.running = true;
            loginTimer.start();
        }

        function stop() {
            webView.url = "";
            rootItem.running = false;
            rootItem.interactive = false;
            loginTimer.stop();
        }
    }

    WebView {

        id: webView
        anchors.fill: parent

        onLoadFailed: {
            console.debug("Fail: " + html);
        }

        onLoadFinished: {
            console.debug(url);
            var processed = false;
            var urlStr = url.toString();
            var tokenIndex = urlStr.indexOf("oauth_token=");
            var uidIndex = urlStr.indexOf("uid=");
            if (tokenIndex > 0 && uidIndex > 0) {
                tokenIndex += 12;
                uidIndex += 4;
                var tokenEnd = urlStr.indexOf("&", tokenIndex);
                if (tokenEnd == -1) { tokenEnd = urlStr.length; }
                var uidEnd = urlStr.indexOf("&", uidIndex);
                if (uidEnd == -1) { uidEnd = urlStr.length; }
                rootItem.userUid = urlStr.substring(uidIndex, uidEnd);
                DropboxAuth.loadToken(function(token, secret) {
                                          privObj.accessToken = token;
                                          privObj.accessTokenSecret = secret;
                                          rootItem.accessToken = token;
                                      },
                                      function(errorCode) {
                                          console.log("ACCESS TOKEN FAILED: " + errorCode);
                                          Qt.quit();
                                      }, {
                                          token: privObj.requestToken,
                                          secret: privObj.requestTokenSecret
                                      });
                rootItem.stop();
                processed = true;
            }

            // Waiting for user, so stop timer
            if (!processed) {
                loginTimer.stop();
                rootItem.interactive = true
            }
        }

        Timer {
            id: loginTimer
            interval: 30000
            repeat: false
            onTriggered: {
                rootItem.stop();
            }
        }

    }
}
