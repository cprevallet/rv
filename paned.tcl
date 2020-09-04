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

# Create a paned window object. Must be done before creating
# objects to add into it. Why????
panedwindow .pnd -orient v -opaqueresize 0

# Create the graph widget.
proc MakeGraph {units} {
    graph .g
    .g element create line1 -x dist -y pace -label "Pace"
    .g element create line2 -x dist -y altitude -label "Altitude" -mapy y2

    .g element configure line1 -color blue4 -symbol circle -fill blue1 -pixels 0.04i
    .g element configure line2 -color purple4 -symbol square -fill purple1 -pixels 0.04i

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
    Blt_ActiveLegend .g
    Blt_ClosestPoint .g
}

proc FormatYLabel {widget y} {
    if {$y > 1} {
    return [clock format $y -format "%M:%S"]
    }
}

# Create the map on a label widget.
proc MakeMap {} {
    # Call goroutine to create png
    createImg csv.dat [ ::fileutil::tempdir ]
    image create photo imgobj -file "image.png"
    .myLabel configure -image imgobj
}

# Handle loading a new file.
proc Update {units} {
    dist set {}
    pace set {}
    altitude set {}
    cadence set {}
    PopulateVectors $units
    MakeMap
}

# Initialize data and GUI.
label .myLabel
PopulateVectors $unitsystem
MakeGraph $unitsystem
MakeMap

# And display!
# Add both widgets to the paned window.
.pnd add [button .b -text "Load File..." -command "Update $unitsystem"]
.pnd add .g
.pnd add .myLabel
pack .pnd -fill both -expand 1
wm deiconify .

# File cleanup.
#file delete image.png
file delete  [ ::fileutil::tempdir ][file separator]csv.dat
