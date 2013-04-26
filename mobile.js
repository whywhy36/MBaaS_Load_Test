if (process.argv.length != 3) {
  console.log("Help: " + process.argv[0] + " " + process.argv[1] + " <config file>");
  process.exit();
}

var async = require("async");
var http = require("http");
var config = require(process.argv[2]);

var regIds = [];
var regidAppkeyMap = {};
var uidRegidMap = {};

connectPN = function() {

  var WebSocketClient = require("websocket").client;
  var client = new WebSocketClient();

  client.on("connectFailed", function(error) {
    console.log("Connect Error: " + error.toString());
  });

  client.on("connect", function(connection) {
    console.log("WebSocket client connected");

    connection.on("error", function(error) {
      console.log("Connection Error: " + error.toString());
    });

    connection.on("close", function() {
      console.log("Connection Closed");
    });

    connection.on("message", function(message) {
      if (message.type != "utf8") {
        return;
      }

      var pushInfo = JSON.parse(message.utf8Data);
      if ( pushInfo.event === "push" ) {
        var res = {"event": "pushAck", "seq": "12345", "info": []};
        for (var i = 0; i < pushInfo.info.length; i++) {
          var msg = pushInfo.info[i];
          var acceptMsgIds = [];
          console.log("Received messages for app", regidAppkeyMap[msg.regId]);
          for (var j = 0; j < msg.messages.length; j++) {
            console.log("-- " + msg.messages[j].content);
            acceptMsgIds.push(msg.messages[j].id);
          }
          res.info.push({"regId": msg.regId, "messageIds": acceptMsgIds});
        }
        connection.sendUTF(JSON.stringify(res));
      }
    });

    connection.sendUTF(JSON.stringify({"event": "addRegId", "seq":"12345", "regIds":regIds}));

  });

  client.connect("ws://" + config.pushNetworkHost + ":" + config.pushNetworkPort + "/", "msg-json");

}

subscribePE = function() {
  var options = {
    host: config.pushEngineHost,
    port: config.pushEnginePort,
    method: "POST"
  };

  var keys = Object.keys(uidRegidMap);
  async.forEachSeries(keys, function(key, callback) {
    var appKey = regidAppkeyMap[uidRegidMap[key]];
    var topics = config.topics[appKey];
    async.forEachSeries(topics, function(topic, cb) {
      options.path = "/subscriber/" + key + "/subscriptions/" + topic;
      var req = http.request(options, function(response) { 
        if ( response.statusCode >= 200 && response.statusCode <= 204 ) {
          console.log("Successfully subscribe topic, subscriber id: " + key + " , topic: " + topic);
        }
        cb();
      });
      req.end();
    }, function(err) { 
      callback();
    });
  }, function(err) { });
}

connectPE = function() {
  var options = {
    host: config.pushEngineHost,
    path: "/subscribers",
    port: config.pushEnginePort,
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    }
  };

  async.forEachSeries(regIds, function(regId, callback) {
    var req = http.request(options, function(response) {
      var str = ""
      response.on("data", function (data) {
        str += data;
      });

      response.on("end", function () {
        var data = JSON.parse(str);
        uidRegidMap[data.id] = regId;
        console.log("Successfully subscribe on push engine, reg id: " + regId + " , subscriber id: " + data.id);
        callback();
      });
    });
    req.write(JSON.stringify({ "proto": "vns", "token": regId }));
    req.end();
  }, function(err) {
    if (!err) {
      subscribePE();
    }
  });
}

async.forEachSeries(config.appKeys, function(appKey, callback) {
  var regOptions = {
    host: config.regServerHost,
    path: "/register",
    port: config.regServerPort,
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    }
  };

  var req = http.request(regOptions, function(response) {
    var str = ""
    response.on("data", function (data) {
      str += data;
    });

    response.on("end", function () {
      var data = JSON.parse(str);
      regIds.push(data.regId);
      regidAppkeyMap[data.regId] = appKey;
      console.log("Successfully register to regserver, app key:", appKey, ", reg id:", data.regId);
      callback();
    });
  });
  req.write(JSON.stringify({ "appKey": appKey, "deviceFingerPrint": config.deviceFingerprint }));
  req.end();
}, function(err) {
  if (!err) {
    connectPN();
    connectPE();
  }
});

