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

/*
 * Currently compton supports the on-the-fly change of the following properties:
 * 
 * fade_delta
 * fade_in_step
 * fade_out_step
 * no_fading_openclose
 * uredir_if_possible
 * clear_shadow
 * track_focus
 * vsync
 * redirected_force
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
		//private string DISPLAY = Environment.get_variable("DISPLAY").replace(":","_").replace(".","_");
		private string DISPLAY = Environment.get_variable("DISPLAY").replace(":","_").split(".")[0];
		
		private Settings settings;
		private ComptonConfiguration compton_settings;
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
			
			// Properties have underscores instead of a dash
			string new_key = key.replace("-","_");
			
			switch (val.get_type_string()) {
				
				case "s":
					// String
					new_variant = new Variant("(ss)", new_key, val.get_string());
					break;
				case "b":
					// Boolean
					new_variant = new Variant("(sb)", new_key, val.get_boolean());
					break;
				case "d":
					// Double
					new_variant = new Variant("(sd)", new_key, val.get_double());
					break;
				case "i":
					// int32
					new_variant = new Variant("(si)", new_key, val.get_int32());
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
		
		private void syncronize_dconf() {
			/**
			 * This method syncronizes the contents of the settings
			 * in dconf with the configuration in this.compton_settings.
			*/
			
			Variant val;
			foreach (string key in this.settings.list_keys()) {
				
				val = this.settings.get_value(key);
				
				switch (val.get_type_string()) {
					case "s":
						// String
						
						string? result = this.compton_settings.get_string(key);
						
						if (result != null && result != val.get_string())
							this.settings.set_string(key, result);
						
						break;
					case "b":
						// Boolean
						
						bool? result = this.compton_settings.get_bool(key);
						
						if (result != null && result != val.get_boolean())
							this.settings.set_boolean(key, result);
						
						break;
					case "d":
						// Double
						
						double? result = this.compton_settings.get_double(key);
						
						if (result != null && result != val.get_double())
							this.settings.set_double(key, result);
						
						break;
					case "i":
						// int32
						
						int? result = this.compton_settings.get_int(key);
						
						if (result != null && result != val.get_int32())
							this.settings.set_int(key, result);
						
						break;
				}
			}
			
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
			
			// Read compton settings
			this.compton_settings = new ComptonConfiguration("/home/g7/.config/compton.conf");
			
			// Syncronize dconf with the compton.conf
			this.syncronize_dconf();
			
			// Ensure we are aware when settings change...
			this.settings.changed.connect(this.on_settings_changed);
			
			this.compton_proxy = new DBusProxy.for_bus_sync(
				BusType.SESSION,
				DBusProxyFlags.NONE,
				null,
				"com.github.chjj.compton." + DISPLAY,
				"/",
				"com.github.chjj.compton",
				null
			);
		}
		
	}
			

}
