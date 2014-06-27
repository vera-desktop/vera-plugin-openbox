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

using Vera;
using Gee;

namespace OpenboxPlugin {

	public class Plugin : Peas.ExtensionBase, VeraPlugin {

		private string HOME = Environment.get_home_dir();

		public Display display;
		public Settings settings;

		private Compton compton;
		
		private void on_process_terminated(Pid pid, int status) {
			/**
			 * Fired when the process pid has been terminated.
			*/
			
			debug("Pid %s terminated.", pid.to_string());
			
			Process.close_pid(pid);
		}

		public void init(Display display) {
			/**
			 * Initializes the plugin.
			*/
			
			try {
				this.display = display;
				
				this.compton = new Compton();
					
				//this.settings = new Settings("org.semplicelinux.vera.tint2");

				//this.settings.changed.connect(this.on_settings_changed);

			} catch (Error ex) {
				error("Unable to load plugin settings.");
			}

			
		}
		
		public void startup(StartupPhase phase) {
			/**
			 * Called by vera when doing the startup.
			*/
			
			if (phase == StartupPhase.WM) {
								
				// Launch openbox.
				Pid pid;
				
				try {
					Process.spawn_async(
						this.HOME,
						{ "openbox" },
						Environ.get(),
						SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
						null,
						out pid
					);
										
					ChildWatch.add(pid, this.on_process_terminated);
				} catch (SpawnError e) {
					warning(e.message);
				}
			}
			
		}
		

	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(VeraPlugin), typeof(OpenboxPlugin.Plugin));
}
