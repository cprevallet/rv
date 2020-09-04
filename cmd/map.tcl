package require Tk

wm geometry . 800x600+100+100

# The calculation of the map image is done in an extension (written in Go).
# Load the extension
switch $tcl_platform(platform) {
   windows {
      load [file join [pwd] goroutines.dll]
   }
   unix {
      load [file join [pwd] goroutines[info sharedlibextension]]
   }
}

# Interactively prompt for fit binary file.
set fit_file [::tk::dialog::file:: open]

# Call the go routine to convert the binary file.
createCsv $fit_file csvfile.dat

# Call the go routine to create the png file.
createImg csvfile.dat
# Take the png and convert to a label widget.
image create photo imgobj -file "image.png"
pack [label .myLabel] -expand 1 -fill both
.myLabel configure -image imgobj

# File cleanup.
file delete csvfile.dat
file delete image.png

