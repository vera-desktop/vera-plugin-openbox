#!/usr/bin/python3
# -*- coding: utf-8 -*-
#
# openbox-vera-color - change the Openbox theme colors by looking at vera-color
# Copyright (C) 2014  Eugenio "g7" Paolantonio and the Semplice Project
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
#     Eugenio "g7" Paolantonio <me@medesimo.eu>
#

import os
import shutil
import xml.etree.ElementTree as etree

from gi.repository import Gio, Gdk

# First time? Remove trigger for the next one
if os.path.exists(os.path.expanduser("~/.config/autostart/first-time-openbox-vera-color.desktop")):
	os.remove(os.path.expanduser("~/.config/autostart/first-time-openbox-vera-color.desktop"))

OPENBOX_CONFIGURATION = os.path.expanduser("~/.config/vera/openbox/rc.xml")
namespaces = {"ob":"http://openbox.org/3.5/rc"}

# Open openbox configuration
tree = etree.parse(OPENBOX_CONFIGURATION)
root = tree.getroot()
etree.register_namespace('',namespaces["ob"])

try:
	theme = root.find("ob:theme", namespaces=namespaces).find("ob:name", namespaces=namespaces).text
except:
	raise Exception("Unable to find theme.")

# Get current vera-color
if Gio.SettingsSchemaSource.get_default().lookup("org.semplicelinux.vera.desktop", True) == None:
	raise Exception("Schema org.semplicelinux.vera.desktop not available.")

vera_color = Gio.Settings("org.semplicelinux.vera.desktop").get_string("vera-color")
rgba = Gdk.RGBA()
rgba.parse(vera_color)
# http://wrhansen.blogspot.it/2012/09/how-to-convert-gdkrgba-to-hex-string-in.html
vera_color = "#{0:02x}{1:02x}{2:02x}".format(
	int(rgba.red*255),
	int(rgba.green*255),
	int(rgba.blue*255)
)

# Now that we have the theme name, we should search for the base theme
found = False
for directory in (os.path.expanduser("~/.themes"), "/usr/share/themes"):
	path = os.path.join(directory, "%s/openbox-3" % theme)
	
	if not os.path.exists(path):
		continue
	
	if os.path.exists(os.path.join(path, "themerc.vera-color-base")):
		found = True
		break

if not found:
	raise Exception("Unable to find theme %s or the theme is not vera-color enabled." % theme)

# If the found directory is in /usr/share/themes, we should copy it to home
if path.startswith("/usr/share/themes"):
	finalpath = os.path.join(os.path.expanduser("~/.themes"), "%s/openbox-3" % theme)
	if not os.path.exists(finalpath.replace("/openbox-3","")):
		os.makedirs(finalpath.replace("/openbox-3",""))
	shutil.copytree(path, finalpath)
	path = finalpath

# Write changes
content = []
with open(os.path.join(path, "themerc.vera-color-base"), "r") as f:
	content = f.readlines()

with open(os.path.join(path, "themerc"), "w") as f:
	for line in content:
		f.write(line.replace("@vera-color", vera_color))
