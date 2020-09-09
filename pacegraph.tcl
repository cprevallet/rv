# tclsh pacegraph.tcl
package require Tk
# minimize the annoying Tk window (under Windows) on startup
wm iconify .
package require fileutil
package require csv
package require units

# Load the dlls/shared object files and commonly used packages.
source prepare_packages.tcl

# Read the command line.
# argv0 = metric or imperial (blank=imperial)
set unitsystem [lindex $argv 0]

# Create the line vectors and fill them in from the csv file.
vector create dist
vector create pace
vector create altitude
vector create cadence

proc makePace {speed} {
    # Speed -> pace careful not to divide by zero.
    if {$speed > 1.8} { 
    	set pace [expr 1.0 / $speed]
    } else {
    	set pace 0.56
    }
    return $pace
}
 
# Read in the data from a csv file.
proc PopulateVectors {units} {

    # Call the GO extension to convert the binary file to a csv file
    # in a (OS-specific) temp directory.
    source getfile.tcl
    set tempdir [ ::fileutil::tempdir ]
    createCsv [ GetFitFile ] csv.dat $tempdir

    # Read in the csv file.
    set f [open ${tempdir}[file separator]csv.dat r]
    while {1} {
        set line [gets $f]
        if {[eof $f]} {
            close $f
            break
        }
        set data [csv::split $line ","]
        if {$units == "metric"} {
            dist append [units::convert [concat [lindex $data 0] "meters"] "kilometers"]
            pace append [units::convert [concat [makePace [lindex $data 1]] "seconds/meter"] "seconds/kilometer"]
            altitude append [units::convert [concat [lindex $data 5] "meters"] "meters"]
            cadence append [lindex $data 6]
        } else {
            dist append [units::convert [concat [lindex $data 0] "meters"] "miles"]
            pace append [units::convert [concat [makePace [lindex $data 1]] "seconds/meter"] "seconds/mile"]
            altitude append [units::convert [concat [lindex $data 5] "meters"] "foot"]
            cadence append [lindex $data 6]
        }
    }
}

# Create the graph widget.
proc MakeGraph {units} {
    graph .g
    .g element create line1 -x dist -y pace -label "Pace"
    .g element create line2 -x dist -y altitude -label "Altitude" -mapy y2

    .g element configure line1 \
        -color blue4 \
        -symbol circle \
        -fill blue1 \
        -pixels 0.04i \
        -smooth quadratic

    .g element configure line2 \
        -color purple4 \
        -symbol square \
        -fill purple1 \
        -pixels 0.04i \
        -smooth quadratic

     if {$units == "metric"} {
         set xtitle "Distance (km)"
         set ytitle "Pace (min/km)"
         set y2title "Altitude (m)"
     } else {
         set xtitle "Distance (mi)"
         set ytitle "Pace (min/mi)"
         set y2title "Altitude (feet)"
     }

    .g axis configure x \
            -title $xtitle \
            -rotate 0 \
            -titlefont "lucidasans -12" \
            -tickfont "lucidasans -12" 
    .g axis configure y \
            -title $ytitle \
            -titlefont "lucidasans -12" \
            -descending "1" \
            -tickfont "lucidasans -12" \
            -stepsize 15 \
            -subdivisions 2 \
            -command FormatYLabel 
    .g axis configure y2 \
            -title $y2title \
            -titlefont "lucidasans -12" \
            -tickfont "lucidasans -12" \
            -hide no 
    Blt_ZoomStack .g
#Blt_Crosshairs .g
#    Blt_ActiveLegend .g
#Blt_ClosestPoint .g
}

proc FormatYLabel {widget y} {
    if {$y > 1} {
    return [clock format $y -format "%M:%S"]
    }
}

proc doFindElement { g x y } {
    # Remove any previous markers.
    catch {eval $g marker delete [$g marker names "bltClosest_*"]}
    # What elements are closest to the current x,y coordinates?
    # myinfo should include name, x, y, index, dist 
    array set myinfo [$g element closest $x $y ]
    if { ![info exists myinfo(name)] } {
	return
    }
    # Retrieve the x and y values, the axis used (y or y2), the axis label & 
    # foreground color for the element under the cursor.
    if {$myinfo(name) == "line2"} {
        set yaxis y2
        set ytitle [$g axis cget y2 -title]
    } else {
        set yaxis y
        set ytitle [$g axis cget y -title]
    }
    set elemlabel [$g element cget $myinfo(name) -label]
    set elemcolor [$g element cget $myinfo(name) -color]
    set xtitle [$g axis cget x -title]
    set xval [format %7.2f $myinfo(x)]
    set yval [format %7.2f $myinfo(y)]
    # Hmmm...special cases are bad.  Can we do this cleaner?
    if {[string range $ytitle 0 3] == "Pace"} {set yval [FormatYLabel $g [expr int($myinfo(y))]]}
    # Generate a new marker taking care to use the correct axis
    # for generating values.
    set markerName "bltClosest_$myinfo(name)"
    $g marker create text $markerName \
	-text "$xtitle = $xval\n$ytitle = $yval" \
        -coords "$myinfo(x) $myinfo(y)" \
        -mapx x -mapy $yaxis \
	-anchor s -justify left \
	-yoffset 0.5i -fill $elemcolor -outline white

}

PopulateVectors $unitsystem
MakeGraph $unitsystem

# Bind a motion event to the procedure that generates
# a marker for the points on the graph.
bind mytag <Motion>  { doFindElement %W %x %y }
blt::AddBindTag .g mytag

pack .g -expand 1 -fill both
wm deiconify .

# File cleanup.
file delete  [ ::fileutil::tempdir ][file separator]csv.dat

