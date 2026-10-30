{ myvars, ... }:
let
  userReadable = {
    mode = "0500";
    owner = myvars.username;
  };
  rootOnly = {
    mode = "0500";
    owner = "root";
  };
  rootRead = {
    mode = "0400";
    owner = "root";
  };
  desktop = [
    [
      "desktop"
      "enable"
    ]
  ];
  application = [
    [
      "server"
      "application"
      "enable"
    ]
  ];
  operation = [
    [
      "server"
      "operation"
      "enable"
    ]
  ];
  kubernetes = [
    [
      "server"
      "kubernetes"
      "enable"
    ]
  ];
  webserver = [
    [
      "server"
      "webserver"
      "enable"
    ]
  ];
  storage = [
    [
      "server"
      "storage"
      "enable"
    ]
  ];
  shared = {
    platforms = [
      "nixos"
      "darwin"
    ];
    groups = desktop;
  };
in
{
  "nix-access-tokens" = shared // {
    file = "server/nix-access-tokens.age";
    groups =
      desktop
      ++ application
      ++ operation
      ++ kubernetes
      ++ webserver
      ++ storage
      ++ [
        [
          "server"
          "network"
          "enable"
        ]
      ];
    policy = userReadable;
  };
  "rclone.conf" = shared // {
    file = "desktop/rclone.conf.age";
    policy = rootOnly;
    etc = {
      name = "rclone.conf";
    };
  };
  "ssh-key-romantic" = shared // {
    file = "desktop/ssh-key-romantic.age";
    policy = userReadable;
    etc = {
      name = "ssh-key-romantic";
      mode = "0600";
    };
  };
  "work-gitconfig" = shared // {
    file = "desktop/work-gitconfig.age";
    policy = userReadable;
    etc = {
      name = "work-gitconfig";
      mode = "0400";
    };
  };
  "transmission-credentials.json" = {
    file = "server/transmission-credentials.json.age";
    groups = application;
    policy = rootOnly;
  };
  "sftpgo.env" = {
    file = "server/sftpgo.env.age";
    groups = application;
    policy = {
      mode = "0400";
      owner = "sftpgo";
    };
  };
  "rustfs.env" = {
    file = "server/rustfs.env.age";
    groups = application;
    policy = rootRead;
  };
  "grafana-admin-password" = {
    file = "server/grafana-admin-password.age";
    groups = operation;
    policy = {
      mode = "0400";
      owner = "grafana";
    };
  };
  "grafana-secret-key" = {
    file = "server/grafana-secret-key.age";
    groups = operation;
    policy = {
      mode = "0400";
      owner = "grafana";
    };
  };
  "alertmanager.env" = {
    file = "server/alertmanager.env.age";
    groups = operation;
    policy = rootOnly;
  };
  "k3s-test-1-token" = {
    file = "server/k3s-test-1-token.age";
    groups = kubernetes;
    policy = rootOnly;
  };
  "postgres-ecc-server.key" = {
    file = "certs/ecc-server.key.age";
    groups = webserver;
    policy = {
      mode = "0400";
      owner = "postgres";
    };
  };
  "cloudflare-dns-api-token" = {
    file = "server/cloudflare-dns-api-token.env.age";
    groups = webserver;
    policy = rootRead;
  };
  "desktop-restic-password" = {
    file = "desktop/restic-password-desktop.age";
    groups = desktop;
    secretName = "restic-password";
    policy = rootRead;
  };
  "restic-rest-credentials" = {
    file = "desktop/restic-rest-credentials.age";
    groups = desktop;
    policy = rootRead;
  };
  "homelab-restic-password" = {
    file = "server/restic-password-homelab.age";
    groups = storage;
    secretName = "restic-password";
    policy = rootRead;
  };
  "restic-rest-htpasswd" = {
    file = "server/restic-rest-htpasswd.age";
    groups = storage;
    policy = {
      mode = "0400";
      owner = "restic";
    };
  };
  "hdd-luks-crypt-key" = {
    file = "server/hdd-luks-crypt-key.age";
    groups = storage;
    policy = rootRead;
    etc = {
      name = "hdd-luks-crypt-key";
      mode = "0400";
    };
  };
}
