package require Tk
# minimize the annoying Tk window (under Windows) on startup
wm iconify .
package require fileutil

# Load the dlls/shared object files and commonly used packages.
source prepare_packages.tcl

# Open a fit file. Return fit_file.
# Call the GO extension to convert the binary file to a csv file
# in a (OS-specific) temp directory.
set tempdir [::fileutil::tempdir ]
source getfile.tcl
createCsv [ GetFitFile ] csv.dat [ ::fileutil::tempdir ]

# Call the go routine to create the png file.
createImg csv.dat [ ::fileutil::tempdir ]

# Take the png and convert to a label widget.
image create photo imgobj -file "image.png"
pack [label .myLabel] -expand 1 -fill both
.myLabel configure -image imgobj
wm deiconify .

# File cleanup.
#file delete image.png
file delete [ ::fileutil::tempdir ][file separator]csv.dat

