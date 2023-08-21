{ config
, pkgs
, backup_source ? config.services.postgresql.dataDir
, backup_repo ? "/var/lib/pgbackrest"
, stanza ? "localdb"
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
      repo1-retention-full=2
      repo1-retention-diff=4
      repo1-retention-history=120
      archive-async=y
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
    "30 06 * * 0    postgres  ${pkgs.pgbackrest}/bin/pgbackrest --type=full --stanza=${stanza} backup"
    "30 06 * * 1-6  postgres  ${pkgs.pgbackrest}/bin/pgbackrest --type=diff --stanza=${stanza} backup"
  ];

  environment.systemPackages = with pkgs; [ pgbackrest ];

  services.postgresql.settings = {
    archive_mode = "on";
    archive_command = "${pkgs.pgbackrest}/bin/pgbackrest --stanza=${stanza} archive-push %p";
    max_wal_senders = 3;
    wal_level = "replica";
  };
}