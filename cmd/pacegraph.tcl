# tclsh pacegraph.tcl
package require Tk
# package require BLT # old 2.5 version
package require csv

# package source from http://sourceforge.net/projects/tkblt/ 
lappend auto_path /usr/lib/tkblt3.2/
package require tkblt

# requires tcl > 8
namespace import blt::*  


wm geometry . 800x600+0+0

# Convert mm:ss to integer number of seconds.
proc TimeToSeconds t {
    set result 0
    foreach val [lreverse [split $t :]] mul {1 60} {
        if {$val == {}} break
        incr result [expr {[scan $val %d] * $mul}]
    }
    return $result
}

# The converting the binary run file to csv is done in an extension (written in Go).
# Load the extension.
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

# Create the line vectors and fill them in from the csv file.
vector create dist
vector create pace
vector create altitude

set f [open csvfile.dat r]
while {1} {
    set line [gets $f]
    if {[eof $f]} {
        close $f
        break
    }
    set data [csv::split $line ","]
    dist append [lindex $data 0]
    pace append [ TimeToSeconds [lindex $data 2]]
    altitude append [lindex $data 5]

}

# Set up the graph.
set graph [graph .g]

$graph element create line1 -x dist -y pace -label "Pace"
$graph element create line2 -x dist -y altitude -label "Altitude" -mapy y2

$graph element configure line1 -color blue4 -symbol circle -fill blue1
$graph element configure line2 -color purple4 -symbol square -fill purple1

$graph element configure line1 -pixels 2
$graph element configure line2 -pixels 2

$graph axis configure x -title "Distance (m)" -rotate 0 -titlefont "lucidasans -12" -tickfont "lucidasans -12" 
$graph axis configure y -title "Pace (min/km)" -titlefont "lucidasans -12" -descending "1" -tickfont "lucidasans -12" -stepsize 15 -subdivisions 2
$graph axis configure y2 -title "Altitude (m)" -titlefont "lucidasans -12" -tickfont "lucidasans -12" -hide no 

$graph axis configure y -command FormatYLabel 

proc FormatYLabel {widget y} {
    return [clock format $y -format "%M:%S"]
}

Blt_ZoomStack $graph
#Blt_Crosshairs $graph
Blt_ActiveLegend $graph
Blt_ClosestPoint $graph

pack $graph -expand 1 -fill both

# Add a binding for convenience to let you exit with pressing the
# "quit" button.

wm protocol . WM_DELETE_WINDOW { DoExit 0 }
bind all <Control-KeyPress-c> { DoExit 0 }

proc DoExit { code } {
    destroy .
    #exit $code
}

# File cleanup.
file delete csvfile.dat

