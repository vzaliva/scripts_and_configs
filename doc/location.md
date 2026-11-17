# Location (redshift, Firefox)

How the ThinkPad (Ubuntu 24.04, i3) finds where it is, for redshift's
sunrise and sunset and for websites that ask Firefox. Everything goes
through GeoClue, which scans nearby Wi-Fi networks and looks them up in
[beaconDB](https://beacondb.net/), the community replacement for the
Mozilla Location Service. Accuracy is about 50 m at home.

## What you get

- redshift-gtk starts with i3 and finds the location by itself, also
  after travel.
- Firefox gets the same Wi-Fi based location when a site asks, instead
  of an IP-based guess about 25 km off.

## Files

| In this repo | Installed as | Purpose |
|---|---|---|
| `configs/etc/geoclue/conf.d/90-beacondb.conf` | `/etc/geoclue/conf.d/90-beacondb.conf` | Wi-Fi lookups go to beaconDB; redshift may ask without an agent prompt |
| `configs/dot_config/i3/config` | `~/.config/i3/config` | starts the GeoClue agent, then redshift-gtk |
| `configs/firefox/user.js` | `~/snap/firefox/common/.mozilla/firefox/<profile>/user.js` | Firefox asks the desktop portal, with beaconDB as its own fallback |
| (not a file) | dconf `org.gnome.system.location enabled` | the location switch the portal checks |

The installed files are copies, not symlinks: copy again after editing.

## Installing on a fresh system

```sh
sudo apt install redshift-gtk geoclue-2-demo   # geoclue-2-demo: where-am-i, for checking
sudo install -m 644 configs/etc/geoclue/conf.d/90-beacondb.conf /etc/geoclue/conf.d/
sudo systemctl restart geoclue

gsettings set org.gnome.system.location enabled true

install -m 644 configs/dot_config/i3/config ~/.config/i3/config
install -m 644 configs/firefox/user.js ~/snap/firefox/common/.mozilla/firefox/*.default/
```

Then log out and in (the agent and redshift-gtk are `exec` lines, which
`i3-msg restart` does not run) and restart Firefox (`about:restart`).
The first time a site asks, a desktop dialog asks whether Firefox may
use the location.

## How the pieces fit

```
redshift-gtk ─────────────────────────────┐
                                          ├─> GeoClue ─> Wi-Fi scan ─> beaconDB
Firefox ─> xdg-desktop-portal (Location) ─┘      │
                                           GeoClue demo agent
                                           (approves apps)
```

- **GeoClue** (system service, D-Bus activated). Ubuntu's 2.7.0 still
  sends Wi-Fi lookups to `location.services.mozilla.com`, which shut down
  in 2024, so without the drop-in every lookup times out. The drop-in
  sets `[wifi] url=https://api.beacondb.net/v1/geolocate`.
- **The agent.** GeoClue gives no location to an app unless an agent
  approves it. GNOME Shell is one; under i3 the demo agent
  (`/usr/libexec/geoclue-2.0/demos/agent`) has to be started by hand,
  because i3 ignores its XDG autostart entry. redshift is also marked
  `system=true` in the drop-in, so it does not depend on the agent's
  answer.
- **The portal.** Firefox runs as a snap and cannot ask NetworkManager
  for Wi-Fi networks, so its built-in lookup only sends the IP address.
  With `widget.use-xdg-desktop-portal.location = 1` it asks
  xdg-desktop-portal instead, which asks GeoClue. The portal refuses
  with "Location services disabled" unless GNOME's per-user switch
  `org.gnome.system.location enabled` is true, even outside GNOME.
- **Firefox fallback.** If the portal fails, Firefox uses its own lookup,
  pointed at beaconDB by `geo.provider.network.url` instead of Google.
  `geo.provider.use_geoclue` stays false: the snap cannot reach GeoClue
  directly.

## Checking

```sh
/usr/libexec/geoclue-2.0/demos/where-am-i -a 8 -t 30   # exact level: Wi-Fi, ~50 m
/usr/libexec/geoclue-2.0/demos/where-am-i -a 4 -t 30   # city level: ~3 km
redshift -p                     # location and period; does not change the screen
gsettings get org.gnome.system.location enabled        # must be true for Firefox
```

In Firefox, <https://browserleaks.com/geo> shows what the browser
reports. Tens of metres means the portal path works; about 25 km means
Firefox fell back to an IP-based guess. Google Maps' "Show your
location" button uses the same browser location, so it is wrong in the
same way when the portal path is broken.

## Things that are not obvious

- redshift's first answer can be GeoClue's quick estimate (a few km off)
  before the Wi-Fi scan finishes. For sunrise and sunset it does not
  matter.
- When either GeoClue piece is missing, redshift-gtk shows "Failed to
  run Redshift ... Unable to obtain GeoClue client path: Timeout was
  reached" and exits. The "Could not connect to wayland display" line in
  that dialog is harmless: redshift tries Wayland first, then X11.
- `pgrep -f geoclue` matches its own command line, so it looks as if the
  agent were running when it is not. Use `pgrep -x agent`.
- Firefox reads `user.js` only at startup, and puts its values back at
  every start: a change made only in `about:config` does not stick.
- Every app that GeoClue serves now sends nearby Wi-Fi network IDs to
  beaconDB. Apps still need the agent's approval; only redshift is
  approved in advance.
