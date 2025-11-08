# ~/.config/py3status/modules/power_profile.py
class Py3status:
    # user-configurable defaults
    format = "⚡ {profile}"
    cache_timeout = 10
    command_get = "powerprofilesctl get"

    def power_profile(self):
        # run the command and strip newline
        profile = self.py3.command_output(self.command_get).strip()
        full_text = self.py3.safe_format(self.format, {"profile": profile})
        return {
            "full_text": full_text,
            "cached_until": self.py3.time_in(self.cache_timeout),
        }


