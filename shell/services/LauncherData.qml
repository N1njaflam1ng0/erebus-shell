// ┌────────────────────────────────────────────────────────────────────────┐
// │█▀▀▀▀▀▀▀▀█░░░█░░░█▀█░█░█░█▀█░█▀▀░█░█░█▀▀░█▀▄░█▀▄░█▀█░▀█▀░█▀█░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░█░░░█▀█░█░█░█░█░█░░░█▀█░█▀▀░█▀▄░█░█░█▀█░░█░░█▀█░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀█░░░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀░░▀░▀░░▀░░▀░▀░░█▀▀▀▀▀▀▀▀█│
// │█▀▀▀▀▀▀▀▀▀────────────────────────────────────────────────────▀▀▀▀▀▀▀▀▀█│
// ├┤ Author  : Daniel Berg <mail@roosta.sh>                               ├┤
// ││ Repo    : https://github.com/roosta/dotfiles                         ││
// ││ Site    : https://www.roosta.sh                                      ││
// ├┤ License : GNU General Public License v3                              ├┤
// ┆└──────────────────────────────────────────────────────────────────────┘┆

pragma Singleton
pragma ComponentBehavior: Bound

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.config
import qs.utils

// import Quickshell.Io
// import QtQuick
// import qs.utils

Singleton {
  id: root
  property list<var> audioData: {
    if (AudioData.ready) {
      let data = [...Config.outputs, ...Config.audioOptions]
      return data.map(a => ({ name: Fuzzy.prepare(a.name), entry: a }))
    }
    return []
  }

  // ---- Displays --------------------------------------------------------------
  // One card per output, read live from `erebus-monitors list` (tab-separated:
  // name, description, mode, position, scale, enabled|disabled, mirrorOf, focused).
  // Each card carries per-monitor actions in its drawer; the static arrange/save
  // entries from Config are appended at the end.
  property list<var> monitorEntries: []
  property list<var> displayData: {
    const live = monitorEntries.map(a => ({ name: Fuzzy.prepare(a.name), entry: a }));
    const statics = Config.displayLayouts.map(a => ({ name: Fuzzy.prepare(a.name), entry: a }));
    return [...live, ...statics];
  }

  function refreshMonitors() { monProc.running = true }

  Process {
    id: monProc
    command: [Host.monitors, "list"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const rows = [];
        for (const line of this.text.split("\n")) {
          if (!line.length) continue;
          const f = line.split("\t");
          if (f.length < 8) continue;
          rows.push({
            name: f[0], desc: f[1], mode: f[2], pos: f[3],
            scale: f[4], enabled: f[5] === "enabled",
            mirrorOf: f[6], focused: f[7] === "focused"
          });
        }

        const out = [];
        for (const m of rows) {
          const actions = [{
            id: `mon-toggle-${m.name}`,
            name: m.enabled ? "Disable" : "Enable",
            icon: "",
            execString: `${Host.monitors} toggle ${m.name}`,
            command: [Host.monitors, "toggle", m.name]
          }];

          if (m.mirrorOf !== "none") {
            actions.push({
              id: `mon-unmirror-${m.name}`,
              name: `Stop mirroring ${m.mirrorOf}`,
              icon: "",
              execString: `${Host.monitors} unmirror ${m.name}`,
              command: [Host.monitors, "unmirror", m.name]
            });
          }

          // Mirror any *other* output onto this one.
          for (const src of rows) {
            if (src.name === m.name || !src.enabled) continue;
            actions.push({
              id: `mon-mirror-${src.name}-${m.name}`,
              name: `Show ${src.name} here`,
              icon: "",
              execString: `${Host.monitors} mirror ${src.name} ${m.name}`,
              command: [Host.monitors, "mirror", src.name, m.name]
            });
          }

          const state = [];
          if (!m.enabled) state.push("disabled");
          if (m.mirrorOf !== "none") state.push(`mirroring ${m.mirrorOf}`);
          if (m.focused) state.push("focused");

          out.push({
            id: `erebus-monitor-${m.name}`,
            name: m.name,
            comment: `${m.desc} — ${m.mode} at ${m.pos}${state.length ? " (" + state.join(", ") + ")" : ""}`,
            genericName: "Monitor",
            categories: ["Display", m.enabled ? "Enabled" : "Disabled"],
            iconId: m.enabled ? "video-display" : "preferences-desktop-display",
            // Enter on the card toggles; the drawer holds mirroring.
            command: [Host.monitors, "toggle", m.name],
            script: [Host.monitors, "toggle", m.name],
            actions: actions
          });
        }
        root.monitorEntries = out;
      }
    }
  }

  property list<var> powerData: {
    return Config.powerScripts.map(a => {
      return  {
        name: Fuzzy.prepare(a.name),
        entry: a
      }
    })
  }

  property list<var> menuData: Config.launcherMenus.map(a => {
    return  {
      name: Fuzzy.prepare(a.name),
      entry: a
    }
  })

  property list<var> utilsData: Config.utilities.map(a => {
    return {
      name: Fuzzy.prepare(a.name),
      entry: a
    }
  })

  property list<var> appsData: {
    let entries = Array.from(DesktopEntries.applications.values) ?? [];

    const favs = Config.favorites
      .map(id => entries.find(a => a.id === id))
      .filter(a => a !== undefined);

    const rest = entries
      .filter(a => !Config.favorites.includes(a.id))
      .sort((a, b) => a.name.localeCompare(b.name));

    return [...favs, ...rest].map(a => ({
      name: Fuzzy.prepare(a.name),
      entry: a,
    }));
  }

  // ---- Clipboard history -----------------------------------------------------
  // Backed by `erebus-clipboard list`, which emits "<id>\t<preview>" per line
  // (cliphist's own format). Refreshed each time the mode is opened, since the
  // history changes constantly outside the shell.
  property list<var> clipboardEntries: []
  property list<var> clipboardData: clipboardEntries.map(a => ({ name: Fuzzy.prepare(a.name), entry: a }))

  function refreshClipboard() { clipProc.running = true }

  Process {
    id: clipProc
    command: [Host.clipboard, "list"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const out = [];
        for (const line of this.text.split("\n")) {
          if (!line.length) continue;
          const tab = line.indexOf("\t");
          if (tab < 0) continue;
          const id = line.slice(0, tab);
          const preview = line.slice(tab + 1);
          out.push({
            id: `erebus-clip-${id}`,
            clipId: id,
            name: preview,
            comment: "Copy this entry to the clipboard",
            genericName: "Clipboard",
            categories: ["Clipboard"],
            iconId: preview.startsWith("[[ binary data") ? "image" : "edit-paste",
            script: [Host.clipboard, "copy", id]
          });
        }
        root.clipboardEntries = out;
      }
    }
  }

  // ---- Wallpapers ------------------------------------------------------------
  // `erebus-wallpaper list` emits paths relative to the wallpaper root, so the
  // stored selection survives a rebuild or a store GC.
  property list<var> wallpaperEntries: []
  property list<var> wallpaperData: wallpaperEntries.map(a => ({ name: Fuzzy.prepare(a.name), entry: a }))

  function refreshWallpapers() { wallProc.running = true }

  Process {
    id: wallProc
    command: [Host.wallpaper, "list"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const out = [];
        for (const rel of this.text.split("\n")) {
          if (!rel.length) continue;
          const isVideo = /\.(mp4|mkv|webm|avi|mov)$/i.test(rel);
          const slash = rel.lastIndexOf("/");
          const folder = slash > 0 ? rel.slice(0, slash) : "";
          const file = rel.slice(slash + 1).replace(/\.[^.]+$/, "");
          out.push({
            id: `erebus-wall-${rel}`,
            name: file,
            comment: isVideo ? `Animated wallpaper (${folder})` : `Wallpaper (${folder})`,
            genericName: isVideo ? "Video" : "Image",
            categories: ["Wallpaper", folder],
            iconId: isVideo ? "video-x-generic" : "image-x-generic",
            script: [Host.wallpaper, "set-all", rel]
          });
        }
        root.wallpaperEntries = out;
      }
    }
  }

  function launch(entry) {
    if (entry.script) {
      Quickshell.execDetached({
        command: entry.script,
      });
    } else if (entry.runInTerminal) {
      Quickshell.execDetached({
        command: [Config.terminal, ...entry.command],
        workingDirectory: entry.workingDirectory
      });
    } else {
      const wdir = entry.workingDirectory
      const obj = { command: entry.command, }
      if (wdir) { obj.workingDirectory = wdir }
      Quickshell.execDetached(obj);
    }
  }
}

