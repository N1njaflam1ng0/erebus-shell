// ┌────────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░█▀█░█░░░█▀▀░█▀▄░▀█▀░█▀▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░█▀█░█░░░█▀▀░█▀▄░░█░░▀▀█░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀────────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>       ├┤
// ││ Repo    : https://github.com/roosta/dotfiles ││
// ││ Site    : https://www.roosta.sh              ││
// ├┤ License : GNU General Public License v3      ├┤
// ┆└──────────────────────────────────────────────┘┆

pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell.Io
import Quickshell
import QtQuick
import qs.services
// import qs.utils

Singleton {
  id: root
  property bool audioIn: AudioData.audioIn.length > 0
  // Prefer the human-readable stream description ("Firefox Developer Edition")
  // over the raw PipeWire node name.
  property string audioInTooltip: AudioData.audioIn
    .map(n => n.description || n.nickname || n.name).join('\n')
  property bool videoIn: false
  property bool audioOut: AudioData.audioOut.length > 0
  property bool hasAlerts: audioIn || cpuUsage
  property bool cpuUsage: ResourceUsage.cpuUsage >= 0.8
}
