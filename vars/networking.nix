{ lib }:
rec {
  # Homelab addresses use TEST-NET-1. Replace them before deploying inherited hosts.
  mainGateway = "192.0.2.1"; # main router
  mainGateway6 = "fe80::5"; # main router's link-local address
  # The trusted home LAN; the shared host firewall trusts this by source.
  lanCidr = "192.0.2.0/24";
  # use suzi as the default gateway
  # it's a subrouter with a transparent proxy
  proxyGateway = "192.0.2.178";
  proxyGateway6 = "fe80::8";
  # node identity must not ride the WAN /64: the ISP retires it, Cilium never refreshes it.
  clusterULA6 = "fd05:5::";
  nameservers = [
    # IPv4
    "119.29.29.29" # DNSPod https://www.dnspod.cn/Products/publicdns
    "223.5.5.5" # AliDNS
    "1.1.1.1" # Cloudflare https://one.one.one.one/dns/
    # IPv6
    "2402:4e00::" # DNSPod
    "2400:3200::1" # Alidns
    "2606:4700:4700::1111" # Cloudflare
  ];

  # Dedicated VIP block for the k3s clusters, outside the router's DHCP pool
  # (.2-.99). One /29 per cluster, handed to kube-vip: the first usable address
  # is the control-plane API VIP, the rest are LoadBalancer service VIPs.
  k8sVip = {
    cidr = "192.0.2.192/27";
    clusters = {
      k3s-test-1 = {
        cidr = "192.0.2.192/29";
        apiVip = "192.0.2.193";
      };
      # Reserved for future clusters:
      #   .200/29  apiVip .201
      #   .208/29  apiVip .209
      #   .216/29  apiVip .217
    };
  };

  # Static LAN addresses, sorted by IPv4 ascending -- keep it sorted when adding
  # a host so the next free address is obvious. `homeOnly = true` marks an
  # address that only exists at home (the laptop's home Wi-Fi static); ssh and
  # monitoring skip those entries.
  hostsAddr = {
    ai = {
      # Desktop PC. `iface` is only for the two consumers that need one exact name
      # — mihomo's DNS takeover hook and the Noctalia net-speed widget; networkd
      # matches the wired interface by its `en*` prefix (hosts/idols-ai/default.nix).
      iface = "enp4s0";
      ipv4 = "192.0.2.100";
      ipv6 = "fe80::10"; # Link-local Address
    };
    aquamarine = {
      # Physical AI inference server. Reuses the retired VM's address, so check
      # that the router still reserves .101 for this machine. No `iface`: the host
      # matches the wired interface by its `en*` prefix (hosts/idols-aquamarine/).
      ipv4 = "192.0.2.101";
    };
    ruby = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.102";
    };
    kana = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.103";
    };
    nozomi = {
      # LicheePi 4A's wireless interface - RISC-V
      iface = "wlan0";
      ipv4 = "192.0.2.104";
    };
    yukina = {
      # LicheePi 4A's wireless interface - RISC-V
      iface = "wlan0";
      ipv4 = "192.0.2.105";
    };
    chiaya = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.106";
    };
    suzu = {
      # Orange Pi 5 - ARM
      iface = "end1";
      ipv4 = "192.0.2.107";
    };
    shoukei = {
      # Laptop: pinned on the home Wi-Fi only, by `just shoukei-home-wifi`; off
      # the home network it uses DHCP.
      iface = "wld0";
      ipv4 = "192.0.2.108";
      homeOnly = true;
    };
    k3s-test-1-worker-1 = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.111";
    };
    k3s-test-1-worker-2 = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.112";
    };
    k3s-test-1-worker-3 = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.113";
    };
    k3s-test-1-master-1 = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.114";
    };
    k3s-test-1-master-2 = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.115";
    };
    k3s-test-1-master-3 = {
      # VM
      iface = "enp2s0";
      ipv4 = "192.0.2.116";
    };
    mitsuha = {
      iface = "enp2s0"; # fake iface, it's not used by the host
      ipv4 = "192.0.2.177";
    };
    suzi = {
      iface = "enp2s0"; # fake iface, it's not used by the host
      ipv4 = "192.0.2.178";
      ipv6 = "fe80::8"; # Link-local Address, can be used as default gateway
    };
    rakushun = {
      # Orange Pi 5 - ARM, now running Armbian (not NixOS)
      # RJ45 port 1 - enP4p65s0
      # RJ45 port 2 - enP3p49s0
      iface = "enP4p65s0";
      ipv4 = "192.0.2.179";
    };
    shoryu = {
      # Homelab's physical machine (VM host)
      iface = "eno1";
      ipv4 = "192.0.2.181";
    };
    shushou = {
      # Homelab's physical machine (VM host)
      iface = "eno1";
      ipv4 = "192.0.2.182";
    };
    youko = {
      # Homelab's physical machine (VM host)
      iface = "eno1";
      ipv4 = "192.0.2.183";
    };
    # akane = {
    #   # VM (running in macOS's UTM App), using DHCP instead of static ip.
    #   iface = "enp0s1";
    #   ipv4 = "192.168.64.2";
    # };
  };

  ssh = {
    # define the host alias for remote builders
    # this config will be written to /etc/ssh/ssh_config
    #
    # Config format:
    #   Host —  given the pattern used to match against the host name given on the command line.
    #   HostName — specify nickname or abbreviation for host
    #   IdentityFile — the location of your SSH key authentication file for the account.
    # Format in details:
    #   https://www.ssh.com/academy/ssh/config
    # `homeOnly` entries get no alias: their address is not reachable off the
    # home LAN, so an alias would break e.g. `ssh shoukei` over Tailscale.
    extraConfig = (
      lib.attrsets.foldlAttrs (
        acc: host: val:
        if val.homeOnly or false then
          acc
        else
          acc
          + ''
            Host ${host}
              HostName ${val.ipv4}
              Port 22
          ''
      ) "" hostsAddr
    );

    # this config will be written to /etc/ssh/ssh_known_hosts
    knownHosts =
      # Update only the values of the given attribute set.
      #
      #   mapAttrs
      #   (name: value: ("bar-" + value))
      #   { x = "a"; y = "b"; }
      #     => { x = "bar-a"; y = "bar-b"; }
      lib.attrsets.mapAttrs
        (host: value: {
          # Name plus address: the Nix daemon connects the builder by its
          # address, and verifies the host key under that name. A name-only
          # entry fails the build with "Host key verification failed".
          hostNames = [ host ] ++ lib.optionals (builtins.hasAttr host hostsAddr) [ hostsAddr.${host}.ipv4 ];
          publicKey = value.publicKey;
        })
        {
          # Add your own verified builder host keys before opting into remote builds.

          # ==================================== Other SSH Service's Public Key =======================================

          # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
          "github.com".publicKey =
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
  };
}
