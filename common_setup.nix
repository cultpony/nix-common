{ config
, acmeEmail 
, rootPasswordFile
, backup_repository
, backup_repository_key
, pkgs
, unstable
, ...
}:
{
  imports = [ ./gen_common.nix ];

  age = {
    secrets = {
    };
  };

  #zramSwap.enable = true;
  networking.proxy.noProxy = "127.0.0.1,localhost";

  security = {
    acme = {
      acceptTerms = true;
      preliminarySelfsigned = true;
      defaults = {
        email = acmeEmail;
      };
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "de-latin1";
    # useXkbConfig = true; # use xkbOptions in tty.
  };

  nix.gc.automatic = true;

  services.tailscale.enable = true;
  systemd.services.tailscaled.stopIfChanged = false;
  systemd.services.sshd.stopIfChanged = false;
  systemd.services.dhcpcd.stopIfChanged = false;
  systemd.services.systemd-networkd.stopIfChanged = false;
  systemd.services.tailscaled.restartIfChanged = false;
  systemd.services.sshd.restartIfChanged = false;
  systemd.services.dhcpcd.restartIfChanged = false;
  systemd.services.systemd-networkd.restartIfChanged = true;
  users.mutableUsers = false;

  security.pam.services.sudo.sshAgentAuth = true;
  security.pam.enableSSHAgentAuth = true;

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  networking.firewall.checkReversePath = "loose";

  users.users.cultpony = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    passwordFile = rootPasswordFile;
    openssh.authorizedKeys.keys = import ./cultpony_ssh_keys.nix;
  };

  users.users.root = {
    passwordFile = rootPasswordFile;
    openssh.authorizedKeys.keys = import ./cultpony_ssh_keys.nix;
  };

  services.restic_noprune.backups.nix-conf = {
    initialize = false;
    repository = "rclone:remote:nix-server-backups";
    rcloneConfigFile = backup_repository;
    passwordFile = backup_repository_key;
    extraBackupArgs = [
      "-x"
      "--compression=auto"
      "--exclude-caches"
      "--verbose=1"
      "--exclude=/proc"
      "--exclude=/sys"
      "--exclude=/tmp"
      "--exclude=/dev"
      "--exclude=/run"
      "--exclude=/var/lib/docker/overlay2"
      "--exclude=/nix/store"
      "--exclude=/nix/var"
    ];
    paths = builtins.attrNames config.fileSystems;
    timerConfig = {
      OnCalendar = "00:05";
      RandomizedDelaySec = "5h";
    };
    # this is from the local fork of the service
    enablePrune = false;
    enableCheck = false;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--keep-yearly 3"
      "--keep-within 3h"
      "--keep-last 3"
    ];
  };
}
