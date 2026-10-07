// Audio panel: opening and closing, its place among the top-right panels, the
// empty states (the sandbox has no PipeWire), and AudioData's label and icon
// helpers. Saves a screenshot to $OUT when set.
import QtQuick
import Quickshell
import qs
import qs.config
import qs.services
import qs.modules.audio

ShellRoot {
  id: root

  property int step: 0
  property int waited: 0

  function fail(what) {
    console.error(`FAIL ${what}`);
    Qt.exit(1);
  }

  function shot(name) {
    if (Quickshell.env("OUT")) panel.grabToImage(r => r.saveToFile(`${Quickshell.env("OUT")}/${name}.png`));
  }

  function checkHelpers() {
    // Stand-ins for PwNode: only the fields the helpers read.
    const device = { isStream: false, name: "alsa_output.usb", description: "USB Headset", nickname: "Headset" };
    const bare = { isStream: false, name: "alsa_output.raw", description: "", nickname: "" };
    const stream = { isStream: true, name: "Firefox", description: "AudioStream", properties: { "application.name": "Firefox" } };
    const unbound = { isStream: true, name: "spotify", description: "", nickname: "", properties: {} };
    if (AudioData.nodeLabel(device) !== "USB Headset") root.fail("device label");
    if (AudioData.nodeLabel(bare) !== "alsa_output.raw") root.fail("label falls back to the node name");
    if (AudioData.nodeLabel(stream) !== "Firefox") root.fail("stream label is the application");
    if (AudioData.nodeLabel(unbound) !== "spotify") root.fail("unbound stream label");
    if (AudioData.nodeLabel(null) !== "") root.fail("null label");

    if (AudioData.sinkIcon(null) !== AudioData.fallbackSinkIcon) root.fail("null sink icon");
    if (AudioData.sinkIcon(bare) !== AudioData.fallbackSinkIcon) root.fail("unknown sink icon");
    if (AudioData.fallbackSinkIcon === "") root.fail("fallback icon is never empty");
    const known = Config.outputs.find(o => o.sink && o.icon);
    if (known && AudioData.sinkIcon({ name: known.sink }) !== known.icon) root.fail("configured sink icon");
  }

  readonly property var steps: [
    { what: "start", ready: () => true,
      act: () => {
        root.checkHelpers();
        if (panel.visible) root.fail("hidden while closed");
        GlobalState.openAudio("TEST");
      } },
    { what: "slid in", settle: 5, ready: () => panel.visible && panel.slideY === 0,
      act: () => {
        if (!panel.noOutputs.visible) root.fail("no outputs hint");
        if (!panel.noInputs.visible) root.fail("no inputs hint");
        if (!panel.nothingPlaying.visible) root.fail("nothing playing hint");
        if (!GlobalState.overlayOpen) root.fail("counts as an overlay");
        root.shot("audio-panel");
        GlobalState.openSys("TEST");
      } },
    { what: "system panel closes it", ready: () => !GlobalState.audioOpen,
      act: () => {
        if (!GlobalState.sysOpen) root.fail("system panel opened");
        GlobalState.openAudio("TEST");
        if (GlobalState.sysOpen) root.fail("audio closes the system panel");
        GlobalState.openWifi("TEST");
        if (GlobalState.audioOpen) root.fail("wifi closes audio");
        GlobalState.openAudio("TEST");
        if (GlobalState.wifiOpen) root.fail("audio closes wifi");
        GlobalState.openCalendar("TEST");
        if (GlobalState.audioOpen) root.fail("calendar closes audio");
        GlobalState.openAudio("TEST");
        if (GlobalState.calendarOpen) root.fail("audio closes the calendar");
        GlobalState.toggleAudio("OTHER");
        if (!GlobalState.audioOpen || GlobalState.audioMonitorId !== "OTHER") root.fail("toggle moves it to another monitor");
        GlobalState.toggleAudio("OTHER");
        if (GlobalState.audioOpen) root.fail("toggle closes it");
        GlobalState.openAudio("TEST");
        GlobalState.closeAll();
      } },
    { what: "closed", ready: () => !panel.visible && !GlobalState.overlayOpen,
      act: () => { console.log("PASS"); Qt.exit(0); } }
  ]

  FloatingWindow {
    implicitWidth: 800
    implicitHeight: 600
    color: "black"

    AudioPanel {
      id: panel
      monitorId: "TEST"
    }
  }

  Timer {
    interval: 100
    repeat: true
    running: true
    onTriggered: {
      const s = root.steps[root.step];
      if (s.ready() && root.waited >= (s.settle ?? 0)) {
        root.waited = 0;
        root.step++;
        s.act();
      } else if (++root.waited > 100) {
        root.fail(`timed out waiting for: ${s.what}`);
      }
    }
  }
}
