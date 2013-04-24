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
  var socket = require("socket.io-client").connect(config.pushNetworkHost, {port: config.pushNetworkPort});
  socket.on("connect", function(){

    socket.emit("addRegId", JSON.stringify({"seq":"12345", "regIds":regIds}));

    socket.on("push", function(data){
      var pushInfo = JSON.parse(data);
      var res = {};
      res.seq = "12345";
      res.info = [];
      for (var i = 0; i < pushInfo.info.length; i++) {
        var msg = pushInfo.info[i];
        var acceptMsgIds = [];
        console.log("");
        console.log("Messages for ", regidAppkeyMap[msg.regId]);
        for (var j = 0; j < msg.messages.length; j++) {
          console.log(msg.messages[j].content);
          acceptMsgIds.push(msg.messages[j].id);
        }
        res.info.push({"regId": msg.regId, "messageIds": acceptMsgIds});
      }
      socket.emit("pushAck", JSON.stringify(res));
    });

  });
}

subscribePE = function() {
  var options = {
    host: config.pushEngineHost,
    port: config.pushEnginePort,
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    }
  };

  var keys = Object.keys(uidRegidMap);
  for (var i = 0; i < keys.length; i++) {
    var appKey = regidAppkeyMap[uidRegidMap[keys[i]]];
    var topics = config.topics[appKey]
    for (var j = 0; j < topics.length; j++) {
      options.path = "/usrs/" + keys[i] + "/subscriptions/" + topics[j]
      var req = http.request(options, function(response) { });
      req.end();
    }
  }
}

connectPE = function() {
  var options = {
    host: config.pushEngineHost,
    path: "/users",
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
      console.log("Successfull register to regserver, app key:", appKey, ", reg id:", data.regId);
      callback();
    });
  });
  req.write(JSON.stringify({ "appKey": appKey, "deviceFingerprint": config.deviceFingerprint }));
  req.end();
}, function(err) {
  if (!err) {
    connectPN();
    connectPE();
  }
});

