.pragma library

Qt.include("sha1.js")

function loadToken(tokenFunc, errorFunc, tokenData)
{
    var baseUrl;
    if (!tokenData) {
        baseUrl = "https://api.dropbox.com/1/oauth/request_token";
    } else {
        baseUrl = "https://api.dropbox.com/1/oauth/access_token";
    }

    var consumerKey = "<enter-key>";
    var consumerSecret = "<enter-secret>";
    var timestamp = Math.floor((new Date()).getTime() / 1000).toString();
    var nonce = Math.floor(Math.random() * 10000000).toString();

    var signedParams = "oauth_consumer_key=" + consumerKey
        + "&oauth_nonce=" + nonce
        + "&oauth_signature_method=HMAC-SHA1"
        + "&oauth_timestamp=" + timestamp
        + (!tokenData ? "" : "&oauth_token=" + tokenData.token)
        + "&oauth_version=1.0";

    var signKey = encodeURIComponent(consumerSecret) + "&" + (!tokenData ? "" : encodeURIComponent(tokenData.secret));
    var urlToSign = "GET&" + encodeURIComponent(baseUrl) + "&" + encodeURIComponent(signedParams);
    var signature = encodeURIComponent(b64_hmac_sha1(signKey, urlToSign));

//    console.log("INPUT: " + urlToSign);
//    console.log("SIGNATURE: " + signature);

    var authorizationHeader = "OAuth oauth_version=\"1.0\""
        + ", oauth_consumer_key=\"" + consumerKey + "\""
        + ", oauth_nonce=\"" + nonce + "\""
        + ", oauth_signature_method=\"HMAC-SHA1\""
        + ", oauth_timestamp=\"" + timestamp + "\""
        + (!tokenData ? "" : ", oauth_token=\"" + tokenData.token + "\"")
        + ", oauth_signature=\"" + signature + "\"";

    var xhr = new XMLHttpRequest;
    xhr.onreadystatechange = function() {
        if (xhr.readyState == XMLHttpRequest.DONE) {
            if (xhr.status == 200) {
                var list = xhr.responseText.split("&");
                var token;
                var secret;
                for (var index in list) {
                    var nameval = list[index].split("=");
                    if (nameval.length == 2) {
                        if (nameval[0] == "oauth_token") { token = nameval[1]; }
                        else if (nameval[0] == "oauth_token_secret") { secret = nameval[1]; }
                    }
                }
                if (token && secret) {
                    tokenFunc(token, secret);
                }
            } else {
//                console.log("FAILED: " + xhr.status + " " + xhr.statusText);
                if (errorFunc) {
                    errorFunc(xhr.status);
                }
            }
        } else if (xhr.readyState == XMLHttpRequest.OPENED) {
            xhr.setRequestHeader("Authorization", authorizationHeader);
        }
    }
    xhr.open("GET", baseUrl, true);
    xhr.send();
//    console.log(baseUrl + "?" + signedParams + "&oauth_signature=" + signature);
}
