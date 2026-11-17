// Applied by Firefox at every start, overriding prefs.js.
// Location setup: ~/src/scripts_and_configs/doc/location.md

// Ask the desktop portal for the location (1 = always). The portal goes
// to the system GeoClue, which scans Wi-Fi and resolves it with beaconDB.
// Firefox's own lookup cannot do that from the snap: it has no access to
// NetworkManager, so it sends no Wi-Fi data and gets an IP-based guess
// about 25 km off.
user_pref("widget.use-xdg-desktop-portal.location", 1);

// Firefox's own lookup, used only if the portal fails: beaconDB (the
// community successor of the Mozilla Location Service) instead of Google.
user_pref("geo.provider.network.url", "https://api.beacondb.net/v1/geolocate");
