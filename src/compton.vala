/*
 * vera-plugin-openbox - openbox plugin for vera
 * Copyright (C) 2014  Eugenio "g7" Paolantonio and the Semplice Project
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *     Eugenio "g7" Paolantonio <me@medesimo.eu>
*/

namespace OpenboxPlugin {

	public class Compton : Object {
		
		/**
		 * This class handles the startup and the settings of the
		 * compton compositor.
		 * 
		 * Any change done via dconf will be applied on-the-fly on
		 * comtpon via DBus.
		*/
		
		// Ugly but works.
		private string DISPLAY = Environment.get_variable("DISPLAY").replace(":","").split(".")[0];
		
		private Settings settings;
		private DBusProxy compton_proxy;
		
		private void on_settings_changed(string key) {
			/**
			 * Fired when a setting has been changed.
			 * 
			 * We will make compton aware of the change via DBus.
			*/
			
			/*
			 * We need to create a new Variant composed of the key and
			 * the value.
			 * We get the value via Settings.get_value() and then we build
			 * another Variant using the informations for the Variant now
			 * obtained.
			 * 
			 * I'm sure there is a better way to do this, but I haven't
			 * found one yet.
			*/
			Variant val, new_variant;
			val = this.settings.get_value(key);
			
			message("Processing %s", key);
			
			switch (val.get_type_string()) {
				
				case "s":
					// String
					new_variant = new Variant("(ss)", key, val.get_string());
					break;
				default:
					// Breaking
					message("Returning...");
					return;
			}
			
			
			this.compton_proxy.call_sync("opts_set", new_variant, DBusCallFlags.NONE, 1000, null);
			
			/*
			if (!compton.call_sync("opts_set", new_variant, DBusCallFlags.NONE, 1000, null).get_boolean()) {
				warning("Unable to set property %s", key);
			} else {
				message("Set %s!", key);
			}
			*/
		}
		
		public Compton() {
			/**
			 * Constructs the object.
			*/
			
			/*
			 * I *love* vala's way to interface with DBus services.
			 * But it seems that that way doesn't work here.
			 * Compton doesn't export opts_set() so we can't interface
			 * with it.
			 * I'm no DBus expert, so I don't know if their way is ideal,
			 * probably yes.
			 * Anyway, by creating a new DBusProxy we can use call_sync()
			 * to use opts_set().
			 * Good, isn't it?
			*/
						
			this.settings = new Settings("org.semplicelinux.vera.compton");

			// Ensure we are aware when settings change...
			this.settings.changed.connect(this.on_settings_changed);
			
			this.compton_proxy = new DBusProxy.for_bus_sync(
				BusType.SESSION,
				DBusProxyFlags.NONE,
				null,
				"com.github.chjj.compton._" + DISPLAY,
				"/",
				"com.github.chjj.compton",
				null
			);
			
			this.on_settings_changed("vsync");
			
		}
		
	}
			

}
