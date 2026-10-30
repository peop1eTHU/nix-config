#!/usr/bin/env nu
#
# Pin shoukei's home Wi-Fi profile to a static IPv4.
#
# NetworkManager matches connections by SSID. Run this ONCE, while connected to
# the supplied SSID: the script refuses to run unless the current Wi-Fi network is that
# exact SSID, so it can never pin the wrong network by accident. Every other
# network keeps using DHCP. The change is stored in the profile under
# /etc/NetworkManager/system-connections (preserved by impermanence), so it
# survives reboots and rebuilds -- no need to run it again.
#
#   just shoukei-home-wifi <ssid>
#
# See hosts/12kingdoms-shoukei/README.md and WORKAROUNDS.md WA-024/025.

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# The address to pin on that SSID.
const STATIC = {
  address: "192.0.2.108/24"
  gateway: "192.0.2.1"
  dns: "192.0.2.1"
}

# ---------------------------------------------------------------------------
# nmcli helpers
# ---------------------------------------------------------------------------

# Run nmcli; abort the script if it exits non-zero.
def nmcli [args: list<string>] {
  let result = (^nmcli ...$args | complete)
  if $result.exit_code != 0 {
    error make { msg: $"nmcli ($args | str join ' ') failed: ($result.stderr | str trim)" }
  }
  $result.stdout | str trim
}

# Names of the connections that are active right now.
def active-connections [] {
  nmcli ["-t" "-f" "NAME,ACTIVE" "connection" "show"]
  | lines
  | where { |line| ($line | split row ":" | last) == "yes" }
  | each { |line| $line | split row ":" | first }
}

# Every Wi-Fi connection as a { name, ssid } record.
def wifi-profiles [] {
  nmcli ["-t" "-f" "NAME" "connection" "show"]
  | lines
  | where { |name| ($name | str trim) != "" }
  | each { |name|
      if (nmcli ["-g" "connection.type" "connection" "show" $name]) == "802-11-wireless" {
        { name: $name, ssid: (nmcli ["-g" "802-11-wireless.ssid" "connection" "show" $name]) }
      }
    }
  | compact
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

def assert-root [] {
  if (^id -u | str trim | into int) != 0 {
    error make { msg: "must run as root -- nmcli edits system connections; try: just shoukei-home-wifi <ssid>" }
  }
}

# Abort unless Wi-Fi is connected to the supplied SSID right now.
def assert-on-home [active: list<string>, wifi: list, ssid: string] {
  let connected = ($wifi | where { |p| $p.name in $active })
  let current = (if ($connected | is-empty) { [] } else { $connected | get ssid })
  if ($current | is-empty) {
    error make { msg: $"not connected to Wi-Fi -- connect to '($ssid)' first" }
  }
  if (not ($ssid in $current)) {
    error make { msg: $"not connected to '($ssid)'; currently on ($current | str join ', ')" }
  }
}

# ---------------------------------------------------------------------------
# Profile operations
# ---------------------------------------------------------------------------

# The profile names that carry the supplied SSID.
def home-profiles [wifi: list, ssid: string] {
  $wifi | where { |p| $p.ssid == $ssid } | get name
}

def set-static-ip [profile: string] {
  nmcli [
    "connection" "modify" $profile
    "ipv4.method" "manual"
    "ipv4.addresses" $STATIC.address
    "ipv4.gateway" $STATIC.gateway
    "ipv4.dns" $STATIC.dns
  ] | ignore
}

# Apply the new settings without dropping the link (avoids the brcmfmac
# re-auth/password re-prompt, WA-024/025); reconnect only as a fallback.
def apply-live [profile: string] {
  let device = (nmcli ["-g" "GENERAL.DEVICES" "connection" "show" $profile])
  if ($device | is-empty) { return }

  let result = (^nmcli device reapply $device | complete)
  if $result.exit_code == 0 {
    print $"  applied on ($device) via reapply, no reconnect"
  } else {
    print $"  reapply failed, reconnecting '($profile)'"
    nmcli ["connection" "up" $profile] | ignore
  }
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main [ssid: string] {
  assert-root

  let active = (active-connections)
  let wifi = (wifi-profiles)
  assert-on-home $active $wifi $ssid

  let profiles = (home-profiles $wifi $ssid)
  if ($profiles | is-empty) {
    error make { msg: $"no Wi-Fi profile for SSID '($ssid)'" }
  }

  print $"pinning '($ssid)': ($STATIC.address) via ($STATIC.gateway), dns ($STATIC.dns)"
  for p in $profiles {
    print $"  set '($p)'"
    set-static-ip $p
  }

  for p in $profiles {
    if $p in $active { apply-live $p }
  }

  print ""
  print "done. check: nmcli -f NAME,ipv4.method,ipv4.addresses connection show; ip -4 addr show wld0"
}
