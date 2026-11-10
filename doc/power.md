# Power management (TLP)

Power profiles and battery charge limits on the ThinkPad P14s Gen 6 AMD
(Ubuntu 24.04, i3 with py3status). Everything goes through
[TLP](https://linrunner.de/tlp/), which replaced power-profiles-daemon.

## What you get

- Three profiles: `performance`, `balanced`, `power-saver`.
- Click the `⚡ <profile>` item in the bar to pick one from a rofi menu.
- Plugging in switches to `performance`, unplugging to `balanced`. A
  hand-picked `power-saver` stays until it is changed by hand.
- Click the battery item in the bar for a window with cable and battery
  details and a "Battery care" switch (stop charging at 80%).

## Files

| In this repo | Installed as | Purpose |
|---|---|---|
| `configs/etc/tlp.d/10-profiles.conf` | `/etc/tlp.d/10-profiles.conf` | which profile follows the charger |
| `configs/etc/tlp.d/30-tuning.conf` | `/etc/tlp.d/30-tuning.conf` | per-profile CPU tuning |
| (not tracked) | `/etc/tlp.d/20-battery-care.conf` | charge thresholds, rewritten by `battery-care` |
| `scripts/powerprofile-rofi` | `~/bin/powerprofile-rofi` | profile menu |
| `scripts/battery-care` | `~/bin/battery-care` | charge threshold switch |
| `scripts/whatcable-popup` | `~/bin/whatcable-popup` | battery window |
| `configs/dot_config/py3status/modules/power_profile.py` | `~/.config/py3status/modules/` | bar item showing the profile |
| `configs/dot_config/py3status/config` | `~/.config/py3status/config` | binds the clicks |
| `configs/dot_config/i3/config` | `~/.config/i3/config` | starts the listener that refreshes the bar on a profile change |

The installed files are copies, not symlinks: copy again after editing.

## Installing on a fresh system

TLP 1.9 or newer is needed for the three profiles and for `tlp-pd`.
Ubuntu 24.04 ships 1.6, so use the TLP PPA
([instructions](https://linrunner.de/tlp/installation/ubuntu.html)):

```sh
sudo add-apt-repository ppa:linrunner/tlp
sudo apt install tlp tlp-pd tlp-rdw
sudo apt purge power-profiles-daemon     # apt removes it; this drops its config

sudo install -m 644 configs/etc/tlp.d/10-profiles.conf configs/etc/tlp.d/30-tuning.conf /etc/tlp.d/
sudo tlp start

install -m 755 scripts/powerprofile-rofi scripts/battery-care scripts/whatcable-popup ~/bin/
install -m 644 configs/dot_config/py3status/modules/power_profile.py ~/.config/py3status/modules/
i3-msg restart                           # py3status loads modules only at start
```

No reboot is needed. Side effects of the packages: `powerprofilesctl`
goes away with power-profiles-daemon (use `tlpctl`), and
`systemd-rfkill.service` and `.socket` get masked.

Other requirements: `rofi`, `py3status`, `python3-gi` (GTK 3) for the
battery window, `jq`, `upower`, and `~/bin/whatcable-linux` for the cable
details. `battery-care on|off` runs `sudo -n`, so it needs a passwordless
sudo rule.

## Profiles

`tlp-pd` provides the D-Bus API that power-profiles-daemon had, and
`tlpctl` is its client; it needs no root in the active session.

```sh
tlpctl get                  # current profile
tlpctl set power-saver      # performance | balanced | power-saver
```

What each profile sets on this machine (read back from sysfs):

| | performance | balanced | power-saver |
|---|---|---|---|
| Platform profile | `performance` | `balanced` | `low-power` |
| CPU energy preference | `performance` | `balance_power` | `power` |
| CPU boost | on | on | off (2.0 GHz cap) |
| Panel power saving (ABM) | 0 | 1 | 3 |

The platform profile and ABM values are TLP's defaults; the energy
preference on AC and the boost settings come from `30-tuning.conf`. In
TLP's config, `_ON_AC` settings belong to performance, `_ON_BAT` to
balanced and `_ON_SAV` to power-saver.

### Switching with the charger

`10-profiles.conf` sets `TLP_AUTO_SWITCH=2`:

| Event | Result |
|---|---|
| plug in while on balanced | performance |
| unplug while on performance | balanced |
| plug in or unplug while on power-saver | stays power-saver |

So for travel, pick power-saver once; back home, pick another profile by
hand once. With `TLP_AUTO_SWITCH=1` every plug or unplug would override
the manual choice.

## Battery care

```sh
battery-care status         # "on 75 80" / "off 0 100" / "unsupported"
battery-care on             # charge only below 75%, stop at 80%
battery-care off            # charge to 100%
```

The battery window offers the same switch as two radio buttons.

- The choice survives reboots: `battery-care` writes
  `/etc/tlp.d/20-battery-care.conf` and TLP applies it at every boot.
- Above 80% the battery only stops charging, it is not discharged. The
  bar then shows `IDLE`.
- Before a trip, switch it off the evening before to get a full charge,
  and on again afterwards.

## Checking

```sh
sudo tlp-stat -s            # profile, power source, service state
sudo tlp-stat -c            # effective settings and the file each comes from
sudo tlp-stat -b            # thresholds, capacity, current draw (power_now)
sudo tlp-stat -p            # CPU driver, energy preference, platform profile
sudo tlp start              # reload after editing /etc/tlp.d
```

## Things that are not obvious

- The bar item polls every 10 seconds. To show a change at once, the i3
  config starts a `gdbus monitor` on tlp-pd, which announces every profile
  change on D-Bus, and runs `py3-cmd refresh --all` for each one. It is an
  `exec` line, so it starts with the i3 session, not on `i3-msg restart`.
- `tlpctl set` returns about half a second before the profile is
  applied. `powerprofile-rofi` waits for `tlpctl get` to report the new
  profile before refreshing the bar.
- TLP skips charge thresholds that are not configured, and the battery
  keeps the last values written to it. That is why "off" writes an
  explicit 0/100 instead of removing the config file.
- `CPU_BOOST` has no default in TLP. All three of `_ON_AC`, `_ON_BAT` and
  `_ON_SAV` are set, otherwise boost would stay off after leaving
  power-saver.
- TLP and power-profiles-daemon must not run together: they write the
  same kernel settings.
- Not used here because they do not apply: `CPU_MAX_PERF` and
  `CPU_HWP_DYN_BOOST` are Intel-only, and the machine only offers `s2idle`
  suspend.
