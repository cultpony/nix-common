{ config
, pkgs
, backup_source ? config.services.postgresql.dataDir
, backup_repo ? "/var/lib/pgbackrest"
, stanza ? "localdb"
, extra_include_path ? null
, ... 
}:
{
  environment.etc."pgbackrest/pgbackrest.conf" = {
    user = "postgres";
    group = "postgres";
    text = ''
      [${stanza}]
      pg1-path=${backup_source}

      [global]
      repo1-path=${backup_repo}
      repo1-retention-full=1
      repo1-retention-diff=2
      repo1-retention-history=120
      archive-async=y
      process-max=4
      spool-path=/var/spool/pgbackrest
      compress-level=10
      compress-type=zst

      [global:archive-push]
      compress-level=15
      compress-type=zst
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/log/pgbackrest 750 postgres postgres"
    "d /var/spool/pgbackrest 750 postgres postgres"
    "d ${backup_repo} 750 postgres postgres"
  ];

  services.cron.systemCronJobs = [
    "30 06 * * 0    postgres  ${pkgs.pgbackrest}/bin/pgbackrest --type=full --repo=1 --stanza=${stanza} backup ${if extra_include_path != null then "--config-include-path=${extra_include_path}" else ""}"
    "30 06 * * 1-6  postgres  ${pkgs.pgbackrest}/bin/pgbackrest --type=diff --repo=1 --stanza=${stanza} backup ${if extra_include_path != null then "--config-include-path=${extra_include_path}" else ""}"
  ] ++ (if extra_include_path != null then [
    "30 04 * * 0    postgres  ${pkgs.pgbackrest}/bin/pgbackrest --type=full --repo=2 --stanza=${stanza} backup ${if extra_include_path != null then "--config-include-path=${extra_include_path}" else ""}"
    "30 04 * * 1-6  postgres  ${pkgs.pgbackrest}/bin/pgbackrest --type=diff --repo=2 --stanza=${stanza} backup ${if extra_include_path != null then "--config-include-path=${extra_include_path}" else ""}"
  ] else []);

  environment.systemPackages = with pkgs; [ pgbackrest ];

  services.postgresql.settings = {
    archive_mode = "on";
    archive_command = "${pkgs.pgbackrest}/bin/pgbackrest --stanza=${stanza} ${if extra_include_path != null then "--config-include-path=${extra_include_path}" else ""} archive-push %p";
    max_wal_senders = 3;
    wal_level = "replica";
  };
}