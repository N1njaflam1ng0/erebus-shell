# Builds scripts/erebus-<name>.sh into a shellchecked `erebus-<name>`.
{pkgs}: name: runtimeInputs: runtimeEnv:
pkgs.writeShellApplication {
  name = "erebus-${name}";
  inherit runtimeInputs runtimeEnv;
  text = builtins.readFile ../../scripts/erebus-${name}.sh;
  # jq programs and Lua expressions are single-quoted on purpose.
  excludeShellChecks = ["SC2016"];
}
