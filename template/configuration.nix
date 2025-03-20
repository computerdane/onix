{ ... }:

{
  users.users.alice = {
    isNormalUser = true;
    createHome = true;
    description = "Alice Q. User";
    extraGroups = [
      "wheel"
    ];
    group = "users";
    home = "/home/alice";
    shell = "/bin/sh";
    uid = 1234;
  };
}
