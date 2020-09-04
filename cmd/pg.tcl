# tclsh pacegraph.tcl
package require Tk
package require BLT
package require csv

# If we're on Tcl8.x, make use of the namespaces

if { $tcl_version >= 8.0 } {
    namespace import blt::*
    namespace import -force blt::tile::*
}

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

# Interactively prompt for fit binary file.
set fit_file [::tk::dialog::file:: open]

# Call the go routine to convert the binary file.
#createCsv $fit_file csvfile.dat

# Create the line vectors and fill them in from the csv file.
vector create dist 1 2 3
vector create pace 4 5 7
vector create altitude 8 9 10

}

# Set up the graph.
set graph [graph .g]

set configOptions {
    line1.Color                 blue4
    line1.Fill                  blue1
    line1.Symbol                circle
    line2.Color                 purple4
    line2.Fill                  purple1
    line2.Symbol                arrow
    line3.Color                 green4
    line3.Fill                  green1
    line3.Symbol                triangle
}

set resource [string trimleft $graph .]
foreach { option value } $configOptions {
    option add *$resource.$option $value
}
$graph element create line1 -x dist -y pace -label "Pace"
$graph element create line2 -x dist -y altitude -label "Altitude" -mapy y2
$graph element configure line1 -pixels 2
$graph element configure line2 -pixels 2

$graph axis configure x -title "Distance (m)" -rotate 0 -titlefont "lucidasans -12" -tickfont "lucidasans -12" 
$graph axis configure y -title "Pace (min/km)" -titlefont "lucidasans -12" -descending "1" -tickfont "lucidasans -12" -stepsize 15 -subdivisions 2
$graph axis configure y2 -title "Altitude (m)" -titlefont "lucidasans -12" -tickfont "lucidasans -12" -hide no 
$graph grid configure -hide no

$graph axis configure y -command FormatYLabel 

proc FormatYLabel {widget y} {
    return [clock format $y -format "%M:%S"]
}

Blt_ZoomStack $graph
Blt_Crosshairs $graph
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

