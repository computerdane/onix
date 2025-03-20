{
  writeShellApplication,
  fastfetch,
  curl,
  coreutils,
  gnugrep,
}:

writeShellApplication {
  name = "funnyfetch";
  runtimeInputs = [
    fastfetch
    curl
    coreutils
    gnugrep
  ];
  text = builtins.readFile ./script.sh;
}
