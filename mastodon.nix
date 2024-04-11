{ flake-args
, config
, lib
, pkgs
, database-endpoint ? "/run/postgresql"
, redis-endpoint ? "127.0.0.1"
, es-endpoint ? "localhost"
, ... }:
rec {
  pony-social-root = "/mastodon";
  mastodon-package = flake-args.self.packages.${pkgs.system}.mastodon;
  systemCallsList = [ "@cpu-emulation" "@debug" "@keyring" "@ipc" "@mount" "@obsolete" "@privileged" "@setuid" ];
  cfg-service = {
    # User and group
    User = "mastodon";
    Group = "mastodon";
    # State directory and mode
    StateDirectory = "mastodon";
    StateDirectoryMode = "0750";
    # Logs directory and mode
    LogsDirectory = "mastodon";
    LogsDirectoryMode = "0750";
    # Proc filesystem
    ProcSubset = "pid";
    ProtectProc = "invisible";
    # Access write directories
    UMask = "0027";
    # Capabilities
    CapabilityBoundingSet = "";
    # Security
    NoNewPrivileges = true;
    # Sandboxing
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    #RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
    #RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = false;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    PrivateMounts = true;
    # System Call Filtering
    SystemCallArchitectures = "native";

    EnvironmentFile = [ config.age.secrets.ponysocial_config.path ];
    ReadWritePaths = "${toString pony-social-root}/data";
    WorkingDirectory = mastodon-package;

    StartLimitIntervalSec = 120;
    StartLimitBurst = 5;

    Restart = "always";
    RestartSec = 20;
  };
  base-env = {
    all_proxy = config.networking.proxy.default;
    http_proxy = config.networking.proxy.default;
    https_proxy = config.networking.proxy.default;
    no_proxy = config.networking.proxy.noProxy;

    RAILS_LOG_LEVEL = "INFO";
    RAILS_ENV = "production";
    LD_PRELOAD = "${pkgs.jemalloc}/lib/libjemalloc.so";

    # Mastodon Config

    # Local Domain, DO NOT CHANGE
    LOCAL_DOMAIN = "pony.social";
    #WEB_DOMAIN = "pony.social";
    #ALTERNATE_DOMAINS = "pony.social";
    # Retain Session for 1 year
    SESSION_RETENTION_PERIOD = "31556952";
    # Retain IP for 1 week
    IP_RETENTION_PERIOD = "604800";
    # Ban users if they change to a banned email domain
    EMAIL_DOMAIN_LISTS_APPLY_AFTER_CONFIRMATION = "true";

    LIMITED_FEDERATION_MODE = "false";
    ALLOW_ACCESS_TO_HIDDEN_SERVICE = "true";
    AUTHORIZED_FETCH = "false";
    DISALLOW_UNAUTHENTICATED_API_ACCESS = "false";

    S3_ENABLED = "true";
    S3_OPEN_TIMEOUT = "10";
    S3_READ_TIMEOUT = "30";
    S3_OVERRIDE_PATH_STYLE = "true";
    S3_CLOUDFRONT_HOST = "cdn.pony.social";
    S3_PROTOCOL = "https";

    MAX_TOOT_CHARS = "10440";
    MAX_PINNED_TOOTS = "5";
    MAX_PROFILE_FIELDS = "6";
    MAX_BIO_CHARS = "10440";
    MAX_POLL_OPTIONS = "6";
    MAX_DISPLAY_NAME_CHARS = "69";

    ES_ENABLED = "true";
    ES_HOST = es-endpoint;
    ES_PORT = "9200";

    DB_HOST = database-endpoint;
    DB_NAME = "ponysocial_db";
    DB_USER = "mastodon";

    REDIS_HOST = redis-endpoint;
    REDIS_PORT = "6379";

    SMTP_PORT = "465";
    SMTP_FROM_ADDRESS = "celestAI@mail.pony.social";
    SMTP_DOMAIN = "mail.pony.social";
    SMTP_TLS = "true";

    #TRUSTED_PROXY_IP= "127.0.0.1";

    STATSD_ADDR = "localhost:8125";
  };
  sidekiq-basic = queue: threads: idx: {
    "sidekiq-${builtins.concatStringsSep "-" queue}-${toString idx}" = {
      description = "Mastodon Sidekiq worker ${toString idx} for queues ${builtins.concatStringsSep ", " queue}, with ${toString threads} threads";
      wantedBy = [ "mastodon.target" ];
      restartIfChanged = true;
      serviceConfig = {
        Slice = "system-ponysocial-sidekiq.slice";
        TimeoutSec = 15;
        LimitNOFILE = 65536;
        SystemCallFilter = [ ("~" + builtins.concatStringsSep " " systemCallsList) "@chown" "pipe" "pipe2" ];
        ExecStart = "${mastodon-package}/bin/bundle exec sidekiq -c ${toString threads} ${builtins.concatStringsSep " " (builtins.concatLists(map (queue: ["-q" queue]) queue))}";
      } // cfg-service;
      environment = {
        DB_POOL = toString threads;
        MALLOC_ARENA_MAX = "2";
      } // base-env;
      path = with pkgs; [ file imagemagick ffmpeg ];
    };
  };
  sidekiq-universal = threads: idx: {
    "sidekiq-all-${toString idx}" = {
      description = "Mastodon Sidekiq worker ${toString idx} for all queues, with ${toString threads} threads";
      wantedBy = [ "mastodon.target" ];
      restartIfChanged = true;
      serviceConfig = {
        Slice = "system-ponysocial-sidekiq.slice";
        TimeoutSec = 15;
        LimitNOFILE = 65536;
        SystemCallFilter = [ ("~" + builtins.concatStringsSep " " systemCallsList) "@chown" "pipe" "pipe2" ];
        ExecStart = "${mastodon-package}/bin/bundle exec sidekiq -c ${toString threads}";
      } // cfg-service;
      environment = {
        DB_POOL = toString threads;
        MALLOC_ARENA_MAX = "2";
      } // base-env;
      path = with pkgs; [ file imagemagick ffmpeg ];
    };
  };
  sidekiq-n = queue: threads: count: (
    builtins.foldl' flake-args.nixpkgs.lib.mergeAttrs { } (
      builtins.genList
        (sidekiq-basic queue threads)
        count
    )
  );

  mastodon-slice = {
    "system-ponysocial" = {
      sliceConfig = {
        MemoryAccounting = true;
        MemoryMax = "16G";
      };
      wantedBy = [ "multi-user.target" ];
    };
    # All below should try to add up to 16G
    "system-ponysocial-sidekiq" = {
      sliceConfig = {
        CPUAccounting = true;
        # max out sidekiq when it's using 80% of the CPU time available
        CPUWeight = "80";
        MemoryAccounting = true;
        MemoryMax = "8G";
      };
      wantedBy = [ "multi-user.target" ];
      partOf = [ "system-ponysocial.slice" ];
    };
    "system-ponysocial-coredb" = {
      sliceConfig = {
        MemoryAccounting = true;
        MemoryMax = "6G";
      };
      wantedBy = [ "multi-user.target" ];
      partOf = [ "system-ponysocial.slice" ];
    };
    "system-ponysocial-elasticsearch" = {
      sliceConfig = {
        MemoryAccounting = true;
        MemoryMax = "4G";
      };
      wantedBy = [ "multi-user.target" ];
      partOf = [ "system-ponysocial.slice" ];
    };
    "system-ponysocial-web" = {
      sliceConfig = {
        MemoryAccounting = true;
        MemoryMax = "2G";
      };
      wantedBy = [ "multi-user.target" ];
      partOf = [ "system-ponysocial.slice" ];
    };
  };

  envFile = pkgs.writeText "mastodon.env" (lib.concatMapStrings (s: s + "\n") 
    (lib.concatLists (lib.mapAttrsToList
      (name: value:
        if value != null then [
          "${name}=\"${toString value}\""
        ] else [ ]
      )
      base-env))
  );

  mastodonTootctl = pkgs.writeShellScriptBin "mastodon-tootctl" ''
    set -a
    export RAILS_ROOT="${mastodon-package}"
    source "${envFile}"
    source "${config.age.secrets.ponysocial_config.path}"

    sudo=exec
    if [[ "$USER" != "mastodon" ]]; then
      sudo='exec /run/wrappers/bin/sudo -u mastodon --preserve-env'
    fi
    $sudo ${mastodon-package}/bin/tootctl "$@"
  '';

  mastodonBundle = pkgs.writeShellScriptBin "mastodon-bundle" ''
    set -a
    export RAILS_ROOT="${mastodon-package}"
    export RAILS_ENV=production
    source "${envFile}"
    source "${config.age.secrets.ponysocial_config.path}"

    sudo=exec
    if [[ "$USER" != "mastodon" ]]; then
      sudo='exec /run/wrappers/bin/sudo -u mastodon --preserve-env'
    fi
    cd ${mastodon-package}
    
    $sudo ${mastodon-package}/bin/bundle "$@"
  '';

  mastodonImportEmoji = tmpdir: pkgs.writeShellScriptBin "mastodon-import_emoji.rb" ''
    set -a
    export TMP=${tmpdir}
    export TMPDIR=${tmpdir}
    export TMP_DIR=${tmpdir}
    export RAILS_ROOT="${mastodon-package}"
    export RAILS_ENV=production
    source "${envFile}"
    source "${config.age.secrets.ponysocial_config.path}"

    sudo=exec
    if [[ "$USER" != "mastodon" ]]; then
      sudo='exec /run/wrappers/bin/sudo -u mastodon --preserve-env'
    fi
    cd ${mastodon-package}
    
    $sudo ${mastodon-package}/bin/import_emoji.sh "$@"
  '';
}
