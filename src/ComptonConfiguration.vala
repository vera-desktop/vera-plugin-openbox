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
 * FIXMEs:
 *  - Maybe create a DBus service to reload() the configuration?
 *  - Bind libconfig to vala and remove the uglyness in this files
*/

namespace OpenboxPlugin {

	public class ComptonConfiguration : Object {
		
		/**
		 * This class tries to wrap the settings specified in the
		 * compton.conf.
		 * 
		 * When a setting is changed via the public API, it will be
		 * automatically written back in the configuration file.
		*/
		
		private HashTable<string, string> settings = new HashTable<string, string> (str_hash, str_equal);
		
		public string configuration_file {get; set;}
		
		public ComptonConfiguration(string configuration_file) {
			/**
			 * Construct the object.
			*/
			
			this.configuration_file = configuration_file;
			
			this.reload();
			
		}
		
		public bool? get_bool(string key) {
			/**
			 * Reads the key from the HashTable, and returns its value
			 * as a boolean.
			 * 
			 * If the key is not into the settings HashTable, or the key
			 * is not associated with a boolean, this method will return
			 * null.
			*/
			
			bool result = false;
			if (settings.contains(key) && bool.try_parse(settings.get(key), out result)) {
				return result;
			} else {
				return null;
			}
		}
		
		public string? get_string(string key) {
			/**
			 * Reads the key from the HashTable, and returns its value.
			 * 
			 * If the key is not into the settings HashTable, this method
			 * will return null.
			*/
			
			if (settings.contains(key)) {
				return settings.get(key);
			} else {
				return null;
			}
		}
		
		public int? get_int(string key) {
			/**
			 * Reads the key from the HashTable, and returns its value
			 * as an integer.
			 * 
			 * If the key is not into the settings HashTable this method
			 * will return null.
			 * 
			 * If the key is not associated to an integer, it will return
			 * 0. This is unfortunately a limit of the gint type.
			 * Please ensure that you're actually reading an integer
			 * before using this method.
			*/
			
			if (settings.contains(key)) {
				return int.parse(settings.get(key));
			} else {
				return null;
			}
		}
		
		public double? get_double(string key) {
			/**
			 * Reads the key from the HashTable, and returns its value
			 * as a double.
			 * 
			 * If the key is not into the settings HashTable, or the key
			 * is not associated with a double, this method will return
			 * null.
			*/
			
			double result = 0.0;
			if (settings.contains(key) && double.try_parse(settings.get(key), out result)) {
				return result;
			} else {
				return null;
			}
		}
		
		private string? read_line_from_stream(DataInputStream stream) throws IOError {
			/**
			 * Convenience method to read a string without cluttering too
			 * much the while loop used to populate the HashTable.
			*/
			
			string line;
			//line = stream.read_until(";", null, null);
			//line = stream.read_line_utf8(null);
			line = stream.read_line(null);
			
			if (line == null)
				return null;
						
			line = line.replace(" ","").replace("\r","").replace("\"","");
			
			if (line.has_prefix("#")) {
				return "";
			} else if (!line.has_suffix(";")) {
				/*
				 * line doesn't end with ;, so we will read the next
				 * line and append it to the one we have read here.
				 * 
				 * NOTE: Some complex settings like
				 * wintypes:
				 * {
				 *   tooltip = { fade = true; shadow = false; opacity = 0.75; };
				 * };
				 * 
				 * will not work and will only create some useless keys
				 * in the HashTable, but we aren't going to support them
				 * (and neither did paranoid) so we can take the risk.
				 * 
				 * This entire file is pretty hacky, by the way.
				*/
				
				string _new = this.read_line_from_stream(stream);
				if (_new != null)
					line += _new;
			} else {
				line = line.replace(";","");
			}
						
			return line;
		}
		
		public void reload() {
			/**
			 * Reloads the configuration file.
			*/
			
			// Clean
			this.settings.remove_all();
			
			// Open file
			File file = File.new_for_path(this.configuration_file);
			
			if (!file.query_exists()) {
				// Uh oh
				warning("compton configuration file %s not found!", this.configuration_file);
				return;
			}
			
			// Populate the HashTable
			try {
				DataInputStream stream = new DataInputStream(file.read());
				
				string line;
				string[] splt;
				while ((line = read_line_from_stream(stream)) != null) {
										
					splt = line.split("=");
					
					if (line == "" || splt[1] == null)
						continue;
					
					this.settings.insert(splt[0], splt[1]);
					message("Inserted %s. (value %s)", splt[0], splt[1]);
				}
			} catch (Error e) {
				warning("Unable to read the compton configuration file.");
			}
		}
	}
			

}
