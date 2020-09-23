# Identify and load the dependent packages in an OS specific manner.
# Separate the boilerplate here so that it may be reused.
# from tklib
package require tablelist_tile
# from tcllib
package require fileutil
package require csv
package require units

# Load the Golang extension packages from libs directory

# BLT (graph) package source from http://sourceforge.net/projects/tkblt/ 
#switch $tcl_platform(platform) {
#   windows {
      # On Windows we build and copy the BLT package into appdlls 
#      load [file join $dllfilepath tkblt32[info sharedlibextension]]
#      source [file join $dllfilepath graph.tcl]
#   }
#   unix {
      # do nothing, if tkblt is installed via the package manager, 
      # autopath will point to the directory automagically
#   }
#}
package require tkblt
# requires tcl > 8
namespace import blt::*

# Load the extension responsible for parsing a FIT file and all other
# functions written in GO.  sharedlibextension = dll (Windows) or
# so (Linux)
#load [file join $dllfilepath goroutines[info sharedlibextension]]
package require fit
