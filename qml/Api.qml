import QtQuick 2.0
import Qt.labs.settings 1.0
import "descriptions.js" as Descriptions

Item {
  id: api
  property ListModel people: ListModel { }
  property ListModel values: ListModel {
    onDataChanged: api.build()
  }
  property string name
  property string pronoun
  property string token
  property string message
  property string messagePeople
  property string altName: altPrefix + " " + token.slice(0, 12)
  property var jsonPeople: []
  property bool haveApi: typeof Native !== 'undefined'
  property bool isTv: window.width > window.height // TODO: detect touch points instead
  property int addHop: isTv ? 0 : 1 // TV doesn't add hops, just relays messages
  onNameChanged: build()
  property string altPrefix: qsTr("Guest")
  property string tvHeader: qsTr("Seen recently:")
  property bool enabled: isTv
  property bool monochrome: false
  property bool backgroundMode: true
  property bool autoDisableNotify: true
  property bool newPeopleNotify: false
  property bool statusChangesNotify: false

  property string keys: 'tosc'
  property string letters: qsTr("TOSC")
  property var descriptions: Descriptions.descriptions
  property var pronouns: Descriptions.pronouns

  property var ttls: [0, 6 * 60 * 60, 60 * 60, 15 * 60, 10 * 60, 5 * 60] // 6h, 1h, 15m, 10m, 5m

  property ApiNearby nearby: ApiNearby {
    enabled: api.enabled
    onEmit: {
      people.forEach(function(entry) {
        entry.hops += api.addHop;
        jsonPeople.push(entry);
      });
      processPeople();
    }
    onRequest: api.publish()
  }

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

    publish();

    // UI demo
    if (!haveApi && people.count === 0) {
      for (var j = 0; j < 10; j++) {
        people.append({
          name: qsTr("Example") + " " + j,
          pronoun: pronouns[Math.floor(Math.random() * (pronouns.length + 1))] || '',
          altName: "",
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
    property alias pronoun: api.pronoun
    property alias token: api.token
    property alias message: api.message
    property alias messagePeople: api.messagePeople
    property alias tvHeader: api.tvHeader
    property alias enabled: api.enabled
    property alias monochrome: api.monochrome
    property alias backgroundMode: api.backgroundMode
    property alias autoDisableNotify: api.autoDisableNotify
    property alias newPeopleNotify: api.newPeopleNotify
    property alias statusChangesNotify: api.statusChangesNotify
  }

  function build() {
    var msg = {
      token: token,
      name: name,
      pronoun: pronoun,
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
      publishSelfTimer.restart();
    }
  }

  function publish() {
    publishSelfTimer.restart();
    publishPeopleTimer.restart();
  }
  Timer {
    id: publishPeopleTimer
    interval: 500
    running: false
    onTriggered: nearby.publish(messagePeople, 'others')
  }
  Timer {
    id: publishSelfTimer
    interval: 500
    running: false
    onTriggered: {
      if (isTv) return; // TV does not publish self
      nearby.publish(message, 'self');
    }
  }
  Timer {
    running: api.haveApi && api.enabled
    repeat: true
    interval: 60 * 1000
    onTriggered: {
      processPeople() // update the list to exclude outdated, re-publishes on changes
      publishSelfTimer.restart() // re-publish self every minute
    }
  }

  function processPeople() {
    // Filter out invalid entries
    jsonPeople = jsonPeople.filter(function(entry) {
      if (!entry.valid || !('hops' in entry) || !entry.token) return false;
      return entry.valid && ('hops' in entry) && entry.token && ttls[entry.hops || 1];
    });

    // Entries whose tokens are observed in given ttls are valid,
    // even if the message itself was many hops away
    var now = Date.now();
    var valid = []; // TODO: should be a Set once supported
    jsonPeople.forEach(function(entry) {
      if (now > entry.valid + ttls[entry.hops || 1] * 1000) return;
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
      people.append({
        name: entry.name,
        pronoun: entry.pronoun || '',
        altName: altPrefix + " " + entry.token.slice(0, 12),
        token: entry.token,
        valid: entry.valid,
        letters: getLetters(entry)
      });
    });

    var json = JSON.stringify(jsonPeople);
    if (messagePeople !== json) {
      messagePeople = json;
      publishPeopleTimer.restart();
    }
  }
}
