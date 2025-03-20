{ writeShellApplication }:

writeShellApplication {
  name = "echo-green";
  text = ''
    echo -e "\033[32m$*\033[0m"
  '';
}
