import QtQuick 2.0
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Page {
  header: Item {
    height: 50
    Rectangle {
      anchors.fill: parent
      color: palette.alternateBase
    }
    Row {
      width: parent.width - 10
      anchors.centerIn: parent
      spacing: 3
      Item {
        height: parent.height
        width: parent.width - (24 + 3) * 4
        Text {
          text: (api.name || api.altName) + (api.pronoun ? '<br><font size="2" color="#777">(' + api.pronoun + ')</font>' : '')
          font.pixelSize: 18
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
          wrapMode: Text.Wrap
          width: parent.width * 1.5
          height: parent.height
          scale: Math.min(1, (parent.width - 3) / paintedWidth)
          transformOrigin: Item.Left
        }
      }
      Repeater {
        model: api.values
        delegate: Item {
          width: 24
          height: 50
          Letter {
            anchors.centerIn: parent
            size: 24
            letter: model.letter
            value: model.value
            circled: model.circled
          }
        }
      }
    }
    MouseArea {
      anchors.fill: parent
      onClicked: swipeView.currentIndex = 0
    }
  }
  ListView {
    model: api.people
    anchors.fill: parent
    spacing: 5
    header: Item {
      height: 10
    }
    footer: Item {
      height: 10
    }
    delegate: Item {
      width: parent.width
      height: 28
      RowLayout {
        height: parent.height
        width: parent.width - 10
        anchors.centerIn: parent
        spacing: 3
        Item {
          height: parent.height
          Layout.fillWidth: true
          Text {
            text: (model.name || model.altName) + (model.pronoun ? ' <font size="2" color="#777">(' + model.pronoun + ')</font>' : '')
            font.pixelSize: 18
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            width: parent.width * 1.5
            height: parent.height
            scale: Math.min(1, (parent.width - 3) / paintedWidth)
            transformOrigin: Item.Left
          }
        }
        Repeater {
          model: letters
          delegate: Letter {
            size: 24
            letter: model.letter
            value: model.value
            circled: model.circled
          }
        }
      }
    }
  }
  Item {
    anchors.fill: parent
    opacity: api.enabled ? 0 : 1
    Behavior on opacity {
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Rectangle {
      anchors.fill: parent
      color: palette.alternateBase
    }
    Column {
      anchors.centerIn: parent
      width: parent.width * 0.8
      spacing: 20
      Text {
        width: parent.width
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("Enable TOSC to see statuses nearby.")
        font.pixelSize: 18
      }
      Button {
        text: qsTr("Enable")
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: api.enabled = true
      }
    }
  }
  footer: Item {
    height: 60
    Rectangle {
      anchors.fill: parent
      color: palette.alternateBase
    }
    Switch {
      height: 50
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 10
      checked: api.enabled
      onCheckedChanged: api.enabled = checked
    }
    Button {
      height: 50
      anchors.centerIn: parent
      text: qsTr("Edit")
      onClicked: swipeView.currentIndex = 0
    }
  }
}
