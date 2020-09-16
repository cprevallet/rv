# Identify and load the dependent packages in an OS specific manner.
# Separate the boilerplate here so that it may be reused.
package require fileutil
package require tablelist_tile

# Load the packages from appdlls directory
set dllfilepath [ file join [pwd] appdlls ]
lappend auto_path $dllfilepath

# BLT (graph) package source from http://sourceforge.net/projects/tkblt/ 
switch $tcl_platform(platform) {
   windows {
      load [file join $dllfilepath tkblt32[info sharedlibextension]]
   }
   unix {
      load [file join $dllfilepath libtkblt3.2[info sharedlibextension]]
   }
}
source [file join $dllfilepath graph.tcl]
package require tkblt
# requires tcl > 8
namespace import blt::*

# Load the extension responsible for parsing a FIT file and all other
# functions written in GO.  sharedlibextension = dll (Windows) or
# so (Linux)
load [file join $dllfilepath goroutines[info sharedlibextension]]

package require fileutil
package require csv
package require units

