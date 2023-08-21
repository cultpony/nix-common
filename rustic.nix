{ config
, pkgs
, backup_sources ? [ "/" ]
, backup_password_file
, backup_rclone_config
, ... 
}:
let
  rustic-wrapped = pkgs.writeShellScriptBin "rustic-wrapped" ''
    export RUSTIC_USE_PROFILE="/etc/rustic/rustic"
    export RCLONE_CONFIG="${backup_password_file}"
    export PATH="${pkgs.rclone}/bin:$PATH"
    exec ${pkgs.rustic-rs}/bin/rustic $@
  '';
in
{
  environment.etc."rustic/rustic.toml" = {
    user = "root";
    group = "root";
    text = ''
      #[global]
      #log-level = "debug"

      [repository]
      repository = "rclone:remote:nix-server-backups"
      password-file = "${backup_rclone_config}"
      cache-dir = "/var/cache/rustic"
      warm-up = true
      warm-up-wait = "20s"

      [repository.options]
      retry = "true"
      timeout = "10min"

      [backup]
      exclude-if-present = [".nobackup", "CACHEDIR.TAG"]
      one-file-system = true
      group-by = "host,label"

      [[backup.sources]]
      source = "/"
      glob = ["!/proc", "!/sys", "!/tmp", "!/dev", "!/run", "!/var/lib/docker/overlay2", "!/nix/store"]

      [[backup.sources]]
      source = "/mastodon"

      [[backup.sources]]
      source = "/mastodon/elastic"

      [snapshot-filter]
      filter-host = ["${config.networking.hostName}"]

      [forget]
      prune = false
      filter-host = ["${config.networking.hostName}"]
      keep-daily = 7
      keep-weekly = 5
      keep-monthly = 12
      keep-yearly = 3
      keep-within = "3h"
      keep-last = 3
    '';
  };

  services.cron.systemCronJobs = [
    "00 07 * * *  root  ${rustic-wrapped}/bin/rustic-wrapped backup"
  ];

  environment.systemPackages = with pkgs; [ rustic-wrapped ];
}