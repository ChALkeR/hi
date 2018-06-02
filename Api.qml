import QtQuick 2.0
import Qt.labs.settings 1.0

Item {
  id: api
  property ListModel people: ListModel { }
  property ListModel values: ListModel {
    onDataChanged: api.build()
  }
  property string name
  property string token
  property string message
  property string messagePeople
  property var jsonPeople: []
  property bool haveApi: typeof Native !== 'undefined'
  property int apiStatus: Native.apiStatus
  property bool isTv: window.width > window.height // TODO: detect touch points instead
  onNameChanged: build()

  property string keys: 'tosc'
  property string letters: 'ФОРК'

  property var ttls: [0, 6 * 60 * 60, 60 * 60, 15 * 60, 10 * 60, 5 * 60] // 6h, 1h, 15m, 10m, 5m

  function getLetters(msg) {
    var raw = msg.data || {};
    var data = [];
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      var entry = raw[key] || [1, 0];
      data.push({
        key: key,
        letter: letters[i],
        value: entry[0] || 0,
        circled: entry[1] ? true : false
      });
    }
    return data;
  }

  Component.onCompleted: {
    if (!token) {
      token = Math.random().toString(36).slice(2);
    }

    var parsed = message ? JSON.parse(message) : {};
    getLetters(parsed).forEach(function(entry) {
      values.append(entry);
    });
    build();

    jsonPeople = messagePeople ? JSON.parse(messagePeople) : [];
    processPeople();

    publishTimer.restart();
    publishPeopleTimer.restart();

    if (haveApi) {
      Native.apiConnect();
    }

    // UI demo
    if (!haveApi && people.count === 0) {
      for (var j = 0; j < 10; j++) {
        people.append({
          name: "Пример " + j,
          token: Math.random().toString(36).slice(2),
          letters: keys.split('').map(function(key, i) {
            return {
              key: key,
              letter: letters[i],
              value: Math.floor(Math.random() * 3),
              circled: Math.random() > 0.5
            }
          })
        });
      }
    }
  }
  Settings {
    property alias name: api.name
    property alias token: api.token
    property alias message: api.message
    property alias messagePeople: api.messagePeople
  }

  function build() {
    var msg = {
      token: token,
      name: name,
      valid: Date.now(),
      data: {}
    };
    for (var i = 0; i < values.count; i++) {
      msg.data[values.get(i).key] = [
        values.get(i).value,
        values.get(i).circled ? 1 : 0
      ];
    }
    var json = JSON.stringify(msg);
    if (message !== json) {
      message = json;
      publishTimer.restart();
    }
  }

  Timer {
    id: publishTimer
    interval: 500
    running: false
    property int messageId: -1
    onTriggered: {
      if (Native.apiStatus !== 1) return;
      if (isTv) return;
      if (messageId >= 0) Native.unpublishMessage(messageId);
      console.log("Publishing:", message, "fork.self");
      var id = Native.publishMessage(message, "fork.self");
      console.log("Publish id:", id);
      messageId = id;
    }
  }
  Timer {
    running: typeof Native !== 'undefined'
    repeat: true
    interval: 60 * 1000
    onTriggered: {
      processPeople() // update the list to exclude outdated
      publishTimer.restart() // re-publish self every minute
    }
  }

  function processPeople() {
    // Filter out invalid entries
    jsonPeople = jsonPeople.filter(function(entry) {
      if (!entry.valid || !entry.hops || !entry.token) return false;
      return entry.valid && entry.hops && entry.token && ttls[entry.hops];
    });

    // Entries whose tokens are observed in given ttls are valid,
    // even if the message itself was many hops away
    var now = Date.now();
    var valid = []; // TODO: should be a Set once supported
    jsonPeople.forEach(function(entry) {
      if (now > entry.valid + ttls[entry.hops] * 1000) return;
      if (valid.indexOf(entry.token) !== -1) return;
      valid.push(entry.token);
    });
    jsonPeople = jsonPeople.filter(function(entry) {
      return valid.indexOf(entry.token) !== -1;
    });

    // Filter out duplicate and overriden entries
    jsonPeople.sort(function(a, b) {
      // token: asc, hops: asc, valid: desc
      if (a.token < b.token) return -1;
      if (a.token > b.token) return 1;
      if (a.hops < b.hops) return -1;
      if (a.hops > b.hops) return 1;
      if (a.valid < b.valid) return 1;
      if (a.valid > b.valid) return -1;
      return 0;
    });
    jsonPeople = jsonPeople.filter(function(entry, index, arr) {
      if (index === 0) return true;
      var prev = arr[index - 1];
      return entry.token !== prev.token || entry.hops !== prev.hops && entry.valid > prev.valid;
    });

    // Create the list of most up-to-date data to display
    var recent = jsonPeople.slice();
    var shown = []; // TODO: should be a Set once supported
    recent.sort(function(a, b) {
      // valid: desc
      if (a.valid < b.valid) return 1;
      if (a.valid > b.valid) return -1;
      return 0;
    });
    people.clear();
    recent.forEach(function(entry) {
      if (entry.token === token) return;
      if (shown.indexOf(entry.token) !== -1) return;
      shown.push(entry.token);
      var element = {
        name: entry.name,
        token: entry.token,
        valid: entry.valid,
        letters: getLetters(entry)
      };
      people.append(element);
    });

    var json = JSON.stringify(jsonPeople);
    if (messagePeople !== json) {
      messagePeople = json;
      publishPeopleTimer.restart();
    }
  }

  Timer {
    id: publishPeopleTimer
    interval: 500
    running: false
    property int messageId: -1
    onTriggered: {
      if (Native.apiStatus !== 1) return;
      if (messageId >= 0) Native.unpublishMessage(messageId);
      console.log("Publishing:", messagePeople, "fork.others");
      var id = Native.publishMessage(messagePeople, "fork.others");
      console.log("Publish id:", id);
      messageId = id;
    }
  }

  Connections {
    target: Native
    onPing: console.log("Ping:", value)
    onNearbyMessage: {
      console.log("NearbyMessage:", status, message, type)
      var msg = JSON.parse(message);
      switch (type) {
      case "fork.self":
        msg.hops = 1;
        jsonPeople.push(msg);
        break;
      case "fork.others":
        msg.forEach(function(entry) {
          entry.hops += 1;
          jsonPeople.push(entry);
        });
        break;
      default:
        return;
      }
      processPeople();
    }
    onNearbyOwnMessage: console.log("NearbyOwnMessage:", status, id, message, type)
    onApiStatusChanged: {
      console.log('apiStatus', Native.apiStatus);
      if (Native.apiStatus <= 0) return;
      publishTimer.restart();
      publishPeopleTimer.restart();
    }
  }

  Timer {
    interval: 100
    running: Native.nearbySubscriptionStatus <= 0 && Native.apiStatus > 0
    onTriggered: Native.nearbySubscribe()
  }
}
