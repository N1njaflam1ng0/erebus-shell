// Adapted from roosta/dotfiles (.config/quickshell/utils/Paths.qml, GPLv3).
// roosta's `scripts`/`assets`/`srcery` paths are gone — helper binaries come from
// Host.qml, and there is no srcery submodule here.

pragma Singleton

import Quickshell

Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME")

  // Helper function to get XDG directory with fallback
  function xdgDir(envVar, fallback, subdir = "") {
    const base = Quickshell.env(envVar) || `${abs(fallback)}`;
    return subdir ? `${base}/${subdir}` : base;
  }

  readonly property string config: xdgDir("XDG_CONFIG_HOME", "~/.config")
  readonly property string pictures: xdgDir("XDG_PICTURES_DIR", "~/Pictures")
  readonly property string videos: xdgDir("XDG_VIDEOS_DIR", "~/Videos")
  readonly property string data: xdgDir("XDG_DATA_HOME", "~/.local/share", "erebus")
  readonly property string state: xdgDir("XDG_STATE_HOME", "~/.local/state", "erebus")
  readonly property string cache: xdgDir("XDG_CACHE_HOME", "~/.cache", "erebus")

  function abs(path: string): string {
    return path.replace("~", home);
  }

  function shortenHome(path: string): string {
    return path.replace(home, "~");
  }
}
