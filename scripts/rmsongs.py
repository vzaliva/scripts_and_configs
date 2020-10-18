#!/usr/bin/env python3

# Curently (as of 2020-10-18) YoutTube Music only allows to delete your
# uploaded songs from your music library one-by-one. If you migrated your
# Google Play Music library with hundred uploaded songs, deleting them becomes
# a problem. This script allows you to automate that tedious task:
#
# Dependencies:
# https://github.com/sigma67/ytmusicapi
# https://pypi.org/project/curses-menu/

import sys

from cursesmenu import *
from cursesmenu.items import *

from ytmusicapi import YTMusic
yt = YTMusic('headers_auth.json')

def rmartist(aname,aid,nsongs):
    print("Deleting all %d songs by '%s'" % (nsongs,aname))
    while nsongs:
        songs = yt.get_library_upload_artist(aid)
        for s in songs:
            print("Deleting '%s'" % (s['title']))
            yt.delete_upload_entity(s['entityId'])
            nsongs = nsongs-1
    exit(0)

menu = CursesMenu("YT Music - Delete all songs by artist", "Artists")
print("Loading lists of artists...")
artists = yt.get_library_upload_artists(limit=1000)
for a in artists:
    item = FunctionItem("%s (%s songs)" % (a['artist'],a['songs']), rmartist, [a['artist'],a['browseId'],int(a['songs'])])
    menu.append_item(item)
menu.show()




