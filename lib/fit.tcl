# Load the extension responsible for parsing a FIT file and all other
# functions written in GO.  sharedlibextension = dll (Windows) or
# so (Linux)
package provide fit 1.0
variable dir [file dirname [file normalize [info script]]]
load [file join $dir libfit[info sharedlibextension]]
