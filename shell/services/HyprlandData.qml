// ┌────────────────────────────────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░█░█░█░█░█▀█░█▀▄░█░░░█▀█░█▀█░█▀▄░█▀▄░█▀█░▀█▀░█▀█░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░█▀█░░█░░█▀▀░█▀▄░█░░░█▀█░█░█░█░█░█░█░█▀█░░█░░█▀█░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░▀░▀░░▀░░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀░░▀▀░░▀░▀░░▀░░▀░▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀────────────────────────────────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>                               ├┤
// ││ Repo    : https://github.com/roosta/dotfiles                         ││
// ││ Site    : https://www.roosta.sh                                      ││
// ├┤ License : GNU General Public License v3                              ├┤
// ┆└──────────────────────────────────────────────────────────────────────┘┆

// Based on: https://github.com/end-4/dots-hyprland/blob/703697e1c40b66619fb224043891aade47494bb3/.config/quickshell/ii/services/HyprlandData.qml
// Modified 2025 by Daniel Berg <mail@roosta.sh>
//
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.utils

/**
 * Provides access to some Hyprland data not available in Quickshell.Hyprland.
 */
Singleton {
  id: root
  property var windowList: []
  property var addresses: []
  property var windowByAddress: ({})
  property var workspaces: []
  property var workspaceAddresses: []
  property var workspaceByAddress: ({})
  property var workspacesByMonitor: ({})
  property var windowsByWorkspace: ({})
  property var activeWorkspace: null
  property var monitors: []
  property var layers: ({})
  property var special: []
  property string specialEventData: ""
  property string submap: ""
  property bool submapActive: submap.length > 0

  // Hyprland >= 0.57 only emits a workspace "id" for numbered workspaces;
  // specials and named ones have none. "address" is the one key every
  // workspace carries, so the shell keys off it throughout.
  readonly property bool specialActive: monitors.some(m => {
    return (m?.specialWorkspace?.address ?? "") !== ""
  })

  /**
   * Address of the workspace active on a given monitor, "" when unknown.
   */
  function activeWorkspaceAddressFor(monitorName: string): string {
    const mon = root.monitors.find(m => m.name === monitorName)
    return mon?.activeWorkspace?.address ?? ""
  }

  /**
   * Turns a workspace address into a dispatcher selector. Numbered and special
   * addresses already are selectors; a named workspace needs the name: prefix.
   */
  function selectorFor(address: string): string {
    if (address.startsWith("special:") || /^\d+$/.test(address))
      return address
    return `name:${address}`
  }

  /**
   * Urgent windows
   */
  property var urgentWindows: []
  property var activeTopLevel: Hyprland.activeToplevel?.lastIpcObject


  function clearUrgentByClass(c) {
    root.urgentWindows = root.urgentWindows.filter(win => {
      return win.class !== c
    })
  }

  onActiveTopLevelChanged: {
    if (activeTopLevel && urgentWindows.some(w => {
     return w.address === activeTopLevel.address
    })) {
      clearUrgentByClass(activeTopLevel.class)
    }
  }

  function updateWindowList() {
    getClients.running = true;
  }

  function updateLayers() {
    getLayers.running = true;
  }

  function updateMonitors() {
    getMonitors.running = true;
  }

  function updateWorkspaces() {
    getWorkspaces.running = true;
    getActiveWorkspace.running = true;
  }

  function updateAll() {
    updateWindowList();
    updateMonitors();
    updateLayers();
    updateWorkspaces();
  }

  Component.onCompleted: {
    updateAll();
  }
  Connections {
    target: Hyprland

    function onRawEvent(event) {
      root.updateAll()
      Hyprland.refreshToplevels()
      if (event.name === "urgent") {
        const win = root.windowList.find(w => w.address === `0x${event.data}`)
        if (win) {
          root.urgentWindows = [
            ...root.urgentWindows,
            win
          ]
        }
      } else if (event.name === "submap") {
        root.submap = event?.data
      } else if (event.name === "activespecial") {
        root.specialEventData = event?.data
      }
    }
  }

  Process {
    id: getClients
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        if (clientsCollector?.text) {
          root.windowList = JSON.parse(clientsCollector.text)
          let tempWinByAddress = {};
          for (var i = 0; i < root.windowList.length; ++i) {
            var win = root.windowList[i];
            tempWinByAddress[win.address] = win;
          }
          root.windowByAddress = tempWinByAddress;
          root.windowsByWorkspace = Functions.groupBy(root.windowList, w => w.workspace.address)
          root.addresses = root.windowList.map(win => win.address);
        }
      }
    }
  }

  Process {
    id: getMonitors
    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      id: monitorsCollector
      onStreamFinished: {
        if (monitorsCollector?.text) {
          root.monitors = JSON.parse(monitorsCollector.text);
        }
      }
    }
  }

  Process {
    id: getLayers
    command: ["hyprctl", "layers", "-j"]
    stdout: StdioCollector {
      id: layersCollector
      onStreamFinished: {
        if (layersCollector?.text) {
          root.layers = JSON.parse(layersCollector.text);
        }
      }
    }
  }

  Process {
    id: getWorkspaces
    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      id: workspacesCollector
      onStreamFinished: {
        if (workspacesCollector?.text) {
          // Specials sort last, then numerically by address (a numbered
          // workspace's address is its number as a string), then lexically.
          const rank = ws => ws.type === "special" ? 1 : 0;
          const num = ws => /^\d+$/.test(ws.address) ? Number(ws.address) : Infinity;
          const workspaces = JSON.parse(workspacesCollector.text)
            .sort((a, b) => {
              if (rank(a) !== rank(b)) return rank(a) - rank(b);
              if (num(a) !== num(b)) return num(a) - num(b);
              return a.address.localeCompare(b.address);
            });
          root.workspaces = workspaces
          root.special = workspaces.filter(w => w.type === "special")
          root.workspacesByMonitor = Functions.groupBy(root.workspaces, x => x.monitor)
          let byAddress = {};
          for (var i = 0; i < root.workspaces.length; ++i) {
            var ws = root.workspaces[i];
            byAddress[ws.address] = ws;
          }
          root.workspaceByAddress = byAddress
          root.workspaceAddresses = root.workspaces.map(ws => ws.address);
        }
      }
    }
  }

  Process {
    id: getActiveWorkspace
    command: ["hyprctl", "activeworkspace", "-j"]
    stdout: StdioCollector {
      id: activeWorkspaceCollector
      onStreamFinished: {
        if (activeWorkspaceCollector?.text) {
          root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
        }
      }
    }
  }
}
