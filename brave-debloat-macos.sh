#!/usr/bin/env bash
# =============================================================================
# Brave Browser Debloat for macOS
#
# macOS port of the "Brave Browser - Debloat" tweak (WPFTweaksBraveDebloat)
# from WinUtil (config/tweaks.json). This script writes the Brave enterprise
# policies to macOS "managed preferences", the location Chromium-based browsers
# read policies from.
#
# Usage:
#   sudo ./brave-debloat-macos.sh apply      # apply the debloat policies
#   sudo ./brave-debloat-macos.sh revert     # remove them again
#        ./brave-debloat-macos.sh status     # show what is currently set
#        ./brave-debloat-macos.sh profile    # write a .mobileconfig instead
#
# Options (before or after the command):
#   -c, --channel <name>   stable (default) | beta | nightly | dev | all
#   -h, --help
#
# After applying, fully quit Brave (Cmd+Q) and reopen it, then check
# brave://policy to confirm the policies show as "OK".
# =============================================================================
set -euo pipefail

# --- Policies (identical to the Windows tweak) -------------------------------
# name:boolean-value
POLICIES=(
  "BraveRewardsDisabled:true"                       # Brave Rewards (BAT ads)
  "BraveWalletDisabled:true"                        # Crypto wallet
  "IPFSEnabled:false"                               # IPFS / Web3 gateway (crypto-related)
  "BraveVPNDisabled:true"                           # Brave VPN
  "BraveAIChatEnabled:false"                        # Leo AI chat
  "BraveStatsPingEnabled:false"                     # Usage ping
  "BraveNewsDisabled:true"                          # Brave News
  "BraveTalkDisabled:true"                          # Brave Talk
  "TorDisabled:true"                                # Private window with Tor
  "BraveP3AEnabled:false"                           # Privacy-preserving product analytics
  "UrlKeyedAnonymizedDataCollectionEnabled:false"   # URL-keyed data collection
  "SafeBrowsingExtendedReportingEnabled:false"      # Safe Browsing extended reporting
  "MetricsReportingEnabled:false"                   # Usage/crash metrics
)

MANAGED_DIR="/Library/Managed Preferences"
PB="/usr/libexec/PlistBuddy"

# --- Helpers -----------------------------------------------------------------
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
warn()  { printf '\033[33m! %s\033[0m\n' "$*" >&2; }
die()   { printf '\033[31mError: %s\033[0m\n' "$*" >&2; exit 1; }

usage() { sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

need_macos() { [[ "$(uname -s)" == "Darwin" ]] || die "This script is for macOS only."; }
need_root()  { [[ $EUID -eq 0 ]] || die "Run with sudo:  sudo \"$0\" $COMMAND"; }

domain_for() {
  case "$1" in
    stable)  echo "com.brave.Browser" ;;
    beta)    echo "com.brave.Browser.beta" ;;
    nightly) echo "com.brave.Browser.nightly" ;;
    dev)     echo "com.brave.Browser.dev" ;;
    *) die "Unknown channel '$1' (use stable, beta, nightly, dev, all)" ;;
  esac
}

plist_for() { echo "$MANAGED_DIR/$(domain_for "$1").plist"; }

channels() {
  if [[ "$CHANNEL" == "all" ]]; then echo stable beta nightly dev; else echo "$CHANNEL"; fi
}

brave_running() { pgrep -x "Brave Browser" >/dev/null 2>&1 || pgrep -f "Brave Browser" >/dev/null 2>&1; }

refresh_prefs() {
  # Make sure macOS re-reads the managed preferences.
  killall cfprefsd >/dev/null 2>&1 || true
}

# --- Commands ----------------------------------------------------------------
do_apply() {
  need_macos; need_root
  mkdir -p "$MANAGED_DIR"
  for ch in $(channels); do
    local plist; plist="$(plist_for "$ch")"
    bold "Applying to Brave ($ch)  ->  $plist"
    if [[ -f "$plist" && ! -f "$plist.bak" ]]; then
      cp "$plist" "$plist.bak"
      info "Backed up existing file to $plist.bak"
    fi
    # Write the plist file directly (defaults can silently fail on this path).
    [[ -f "$plist" ]] || printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict/>\n</plist>\n' > "$plist" \
      || die "Cannot create $plist (is this folder protected on your macOS version?). Try:  $0 profile"
    for entry in "${POLICIES[@]}"; do
      local name="${entry%%:*}" value="${entry##*:}"
      $PB -c "Delete :$name" "$plist" >/dev/null 2>&1 || true
      $PB -c "Add :$name bool $value" "$plist" >/dev/null
      info "$name = $value"
    done
    chown root:wheel "$plist"
    chmod 644 "$plist"
    [[ -f "$plist" ]] || die "File was not created. Use the profile method:  $0 profile"
  done
  refresh_prefs
  echo
  bold "Done."
  brave_running && warn "Brave is running - quit it fully (Cmd+Q) and reopen for the changes to take effect."
  info "Verify at brave://policy"
}

do_revert() {
  need_macos; need_root
  for ch in $(channels); do
    local plist; plist="$(plist_for "$ch")"
    bold "Reverting Brave ($ch)"
    if [[ ! -f "$plist" ]]; then info "Nothing to revert ($plist not found)."; continue; fi
    for entry in "${POLICIES[@]}"; do
      local name="${entry%%:*}"
      $PB -c "Delete :$name" "$plist" >/dev/null 2>&1 && info "Removed $name" || true
    done
    # Delete the file if no other policies remain (only the empty dict is left).
    local remaining
    remaining="$($PB -c "Print" "$plist" 2>/dev/null | grep -c '=' || true)"
    if [[ "${remaining:-0}" -eq 0 ]]; then
      rm -f "$plist"
      info "Removed empty $plist"
    fi
  done
  refresh_prefs
  echo
  bold "Done. Restart Brave to restore the defaults."
}

do_status() {
  need_macos
  for ch in $(channels); do
    local plist; plist="$(plist_for "$ch")"
    bold "Brave ($ch)  $plist"
    if [[ ! -f "$plist" ]]; then info "(no managed policies set)"; continue; fi
    for entry in "${POLICIES[@]}"; do
      local name="${entry%%:*}" want="${entry##*:}" got
      got="$($PB -c "Print :$name" "$plist" 2>/dev/null || echo "-")"
      if [[ "$got" == "$want" ]]; then info "[x] $name = $got"; else info "[ ] $name = $got (want $want)"; fi
    done
  done
}

do_profile() {
  # Generates a configuration profile (.mobileconfig) as an alternative to
  # writing into /Library/Managed Preferences. Install by double-clicking it,
  # then approve in System Settings > General > Device Management (Profiles).
  need_macos
  local out="${PWD}/brave-debloat.mobileconfig"
  local uuid_a uuid_b
  uuid_a="$(uuidgen)"; uuid_b="$(uuidgen)"
  {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
EOF
    for ch in $(channels); do
      local dom uuid; dom="$(domain_for "$ch")"; uuid="$(uuidgen)"
      cat <<EOF
    <dict>
      <key>PayloadType</key><string>$dom</string>
      <key>PayloadIdentifier</key><string>$dom.debloat.$uuid_a</string>
      <key>PayloadUUID</key><string>$uuid</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadDisplayName</key><string>Brave Debloat ($ch)</string>
EOF
      for entry in "${POLICIES[@]}"; do
        printf '      <key>%s</key><%s/>\n' "${entry%%:*}" "${entry##*:}"
      done
      echo "    </dict>"
    done
    cat <<EOF
  </array>
  <key>PayloadDisplayName</key><string>Brave Browser Debloat</string>
  <key>PayloadIdentifier</key><string>local.brave-debloat.$uuid_a</string>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadScope</key><string>System</string>
  <key>PayloadUUID</key><string>$uuid_b</string>
  <key>PayloadVersion</key><integer>1</integer>
</dict>
</plist>
EOF
  } > "$out"
  plutil -lint "$out" >/dev/null || die "Generated profile failed validation."
  bold "Wrote $out"
  info "Double-click it, then approve under System Settings > General > Device Management."
}

# --- Argument parsing --------------------------------------------------------
COMMAND=""; CHANNEL="stable"
while [[ $# -gt 0 ]]; do
  case "$1" in
    apply|revert|status|profile) COMMAND="$1" ;;
    -c|--channel) shift; [[ $# -gt 0 ]] || die "--channel needs a value"; CHANNEL="$1" ;;
    -h|--help) usage 0 ;;
    *) warn "Unknown argument: $1"; usage 1 ;;
  esac
  shift
done
[[ -n "$COMMAND" ]] || usage 1
[[ "$CHANNEL" =~ ^(stable|beta|nightly|dev|all)$ ]] || die "Unknown channel '$CHANNEL'"

case "$COMMAND" in
  apply)   do_apply ;;
  revert)  do_revert ;;
  status)  do_status ;;
  profile) do_profile ;;
esac
