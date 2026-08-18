import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.mcole.sonos"
  ipcTarget: "sonos"
  manageIpc: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Service {
    id: sonos
    settings: root.settings
    active: root.opened
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { sonos.refresh(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "S"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) sonos.togglePlayback()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(420))

    ColumnLayout {
      id: content
      width: panel.contentWidth
      spacing: Style.space(12)

      Text {
        Layout.fillWidth: true
        text: sonos.room !== "" ? sonos.room : "Sonos"
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        text: sonos.title
        color: root.bar ? root.bar.foreground : Color.foreground
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: sonos.artist !== "" || sonos.album !== ""
        text: [sonos.artist, sonos.album].filter(function(value) { return value !== "" }).join(" - ")
        color: root.bar ? root.bar.foreground : Color.foreground
        opacity: 0.65
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        text: Model.transportLabel(sonos.transport) + (sonos.muted ? " - Muted" : "")
        color: root.bar ? root.bar.foreground : Color.foreground
        opacity: 0.65
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Button { text: "Previous"; enabled: !sonos.busy; onClicked: sonos.run(["prev"]) }
        Button { text: Model.isPlaying(sonos.transport) ? "Pause" : "Play"; enabled: !sonos.busy; onClicked: sonos.togglePlayback() }
        Button { text: "Next"; enabled: !sonos.busy; onClicked: sonos.run(["next"]) }
        Button { text: "Refresh"; enabled: !sonos.busy; onClicked: sonos.refresh() }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Button { text: "-"; enabled: !sonos.busy; onClicked: sonos.changeVolume(-5) }
        Text {
          Layout.fillWidth: true
          text: "Volume " + sonos.volume + "%"
          color: root.bar ? root.bar.foreground : Color.foreground
          horizontalAlignment: Text.AlignHCenter
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Button { text: "+"; enabled: !sonos.busy; onClicked: sonos.changeVolume(5) }
      }

      Text {
        Layout.fillWidth: true
        visible: sonos.lastError !== ""
        text: sonos.lastError
        color: root.bar ? root.bar.urgent : Color.urgent
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }
    }
  }
}
