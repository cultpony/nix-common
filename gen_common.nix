# contains only very common config for everything
args@{ config
, pkgs
, flake-args
, backup_repository
, backup_repository_key
, unstable
, ... }:
{
  imports = [
    ./no-rsa-ssh-hostkey.nix
    ./cachix.nix
    ./restic_noprune.nix
  ];

  nix.settings.substituters = [ "https://cache.garnix.io" ];
  nix.settings.trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];

  nixpkgs.overlays = args.overlays;

  nix.settings.allowed-users = [ "@wheel" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # nix.extraOptions = ''!include ${config.age.secrets.github_pulltoken.path}'';
  system.autoUpgrade = {
    enable = false;
    allowReboot = true;
    persistent = true;
    flake = "github:cultpony/nix";
    dates = "05:40 UTC";
  };
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sd[a-z]*[0-9]*|mmcblk[0-9]*p[0-9]*|nvme[0-9]*n[0-9]*p[0-9]*", ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
  '';

  programs.ssh.extraConfig = ''
    StrictHostKeyChecking accept-new
    Host github.com
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      User git
  '';
  programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # This is a bit silly for everything
  #nix.gc.automatic = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  i18n.supportedLocales = [ "C.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8" ];

  environment.etc."tmux.conf" = {
    text = ''
      set -g mouse on
      setw -g history-limit 50000
      set-window-option -g automatic-rename on
      set-option -g set-titles on
      set-option -g allow-passthrough on
    '';
    mode = "644";
    user = "root";
    group = "root";
  };

  environment.systemPackages = with pkgs; [
    wget
    curl
    nano
    htop
    unzip
    (tmux.overrideAttrs (old: {
      configureFlags = old.configureFlags ++ [ "--enable-sixel" ];
    }))
    pam_ssh_agent_auth
    jq
    sudo
    cachix
    gdu
    unixtools.xxd
    unstable.wezterm.terminfo
    unstable.wezterm
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  services.journald.extraConfig = builtins.concatStringsSep "\n" [
    "MaxRetentionSec=10day"
  ];

  security.sudo.execWheelOnly = true;
  
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
  } // (if config.system.nixos.release == "22.11" then {
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = "prohibit-password";
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding yes
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
  } else {
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding yes
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
  });

}
