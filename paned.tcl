# tclsh pacegraph.tcl
package require Tk
# minimize the annoying Tk window (under Windows) on startup
wm iconify .

# Load the dlls/shared object files and commonly used packages.
source prepare_packages.tcl

# Read the command line.
# argv0 = metric or imperial (blank=imperial)
set unitsystem [lindex $argv 0]

# update the window title
wm title . [concat rv ($unitsystem unitsystem)]

# TODO:/maybe native styles for different platform and/or dark/light
# built-ins
# Linux = clam alt classic default
# Windows = xpnative
switch $tcl_platform(platform) {
   windows {
      #set theme vista
      #set theme winnative
      set theme xpnative
   }
   unix {
      set theme clam
      #set theme alt
      #set theme classic
      #set theme default
   }
}
tablelist::setTheme $theme
ttk::style theme use $theme
# The graph(s) does not support ttk themes, so we look up theme colors
# so they match.
set bgcolor [ttk::style lookup TButton -background]
set fgcolor [ttk::style lookup TButton -foreground]

# Create the line vectors and fill them in from the csv file.
vector create dist
vector create pace
vector create altitude
vector create cadence
vector create heartrate

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
    set fitfilename [GetFitFile]
    wm title . [concat rv ($units unitsystem) - $fitfilename]
    createCsv $fitfilename csv.dat $tempdir

    # Read in the activity csv file.
    set f [open ${tempdir}[file separator]csv.dat r]
    while {1} {
        set line [gets $f]
        if {[eof $f]} {
            close $f
            break
        }
        # Skip the header.
        if {[string is alpha [string index $line 0]] == "1"} { 
            continue 
        }
        set data [csv::split $line ","]
        # Check for bad data in the list (NaN or Invalid).
        set badRec 0
        for {set i 0} {$i < [llength $data]} {incr i} {
            if {[lindex $data $i] == "NaN" || [lindex $data $i] == "Invalid"} {set badRec 1}
        }
        if {$badRec < 1} then {
            if {$units == "metric"} {
                dist append [units::convert [concat [lindex $data 0] "meters"] "kilometers"]
                pace append [units::convert [concat [makePace [lindex $data 1]] "seconds/meter"] "seconds/kilometer"]
                altitude append [units::convert [concat [lindex $data 5] "meters"] "meters"]
                cadence append [lindex $data 6]
                heartrate append [lindex $data 7]
            } else {
                dist append [units::convert [concat [lindex $data 0] "meters"] "miles"]
                pace append [units::convert [concat [makePace [lindex $data 1]] "seconds/meter"] "seconds/mile"]
                altitude append [units::convert [concat [lindex $data 5] "meters"] "foot"]
                cadence append [lindex $data 6]
                heartrate append [lindex $data 7]
            }
        }
    }

}

# Create a paned window object. Must be done before creating
# objects to add into it. Why????
# ttk version apparently has a bug when resizing the sash or else we'd use it.
panedwindow .pnd -orient h -opaqueresize 0

# Create the table widget.
proc MakeLapTable {units t} {

    # Read in the lap csv file.
    set tempdir [ ::fileutil::tempdir ]
    set f [open ${tempdir}[file separator]csv_lap.dat r]
    set lap 0
    while {1} {
        set line [gets $f]
        if {[eof $f]} {
            close $f
            break
        }
        # Skip the header.
        if {[string is alpha [string index $line 0]] == "1"} { 
            continue 
        }
        set data [csv::split $line ","] 
        set badRec 0
        for {set i 0} {$i < [llength $data]} {incr i} {
            if {[lindex $data $i] == "NaN" || [lindex $data $i] == "Invalid"} {set badRec 1}
        }
        if {$badRec < 1 } then {
            set lap [expr $lap + 1]
            set c2 [FormatYLabel .g [expr int([lindex $data 5]) ]]
            set c3 [format %7.0f [lindex $data 6]]
            if {$units == "metric"} {
                    set c1 [format %5.2f [units::convert [concat [lindex $data 4] "meters"] "kilometers"]]
            } else {
                    set c1 [format %5.2f [units::convert [concat [lindex $data 4] "meters"] "miles"] ]
            }
            $t insert end [list $lap $c1 $c2 $c3]
        }
    }
}

# Create another table widget.
proc MakeSessionTable {units t} {
    # Read in the lap csv file.
    set tempdir [ ::fileutil::tempdir ]
    set f [open ${tempdir}[file separator]csv_session.dat r]

    while {1} {
        set line [gets $f]
        if {[eof $f]} {
            close $f
            break
        }
        set data [csv::split $line ","]
        set c0 [lindex $data 0]
        set c1 [lindex $data 1]
        # Times to hh:mm:ss
        if {$c0 == "Elapsed Time" || $c0 == "Active Time"} {
            set c1 [clock format [expr int([lindex $data 1])] -gmt 1 -format "%H:%M:%S"]
        }
        if {$c0 == "Total Distance" && $units == "metric"} {
            set c1 [format %5.2f [units::convert [concat [lindex $data 1] "meters"] "kilometers"]]
        }
        if {$c0 == "Total Distance" && $units != "metric"} {
            set c1 [format %5.2f [units::convert [concat [lindex $data 1] "meters"] "miles"]]
        }
        if {($c0 == "Average Pace" || $c0 == "Fastest Pace") && $units == "metric"} {
            set pace [format %5.2f [units::convert [concat [lindex $data 1] "seconds/meter"] "seconds/kilometer"]]
            set c1 [clock format [expr int($pace)] -format "%M:%S"]
        }
        if {($c0 == "Average Pace" || $c0 == "Fastest Pace") && $units != "metric"} {
            set pace [format %5.2f [units::convert [concat [lindex $data 1] "seconds/meter"] "seconds/mile"]]
            set c1 [clock format [expr int($pace)] -format "%M:%S"]
        }
        if {($c0 == "Total Ascent" || $c0 == "Total Descent") && $units == "metric"} {
            set c1 [format %5.0f [units::convert [concat [lindex $data 1] "meters"] "meters"]]
        }
        if {($c0 == "Total Ascent" || $c0 == "Total Descent") && $units != "metric"} {
            set c1 [format %5.0f [units::convert [concat [lindex $data 1] "meters"] "foot"]]
        }
        $t insert end [list $c0 $c1]
    }
}

# Create the graph widget.
proc MakeGraph {units} {
    variable bgcolor
    variable fgcolor
    graph .g -background $bgcolor -highlightthickness 0
    .g element create line1 -x dist -y pace -label "Pace" 
    .g element create line2 -x dist -y altitude -label "Altitude" -mapy y2
    .g legend configure -foreground $fgcolor

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
            -titlecolor $fgcolor \
            -tickfont "lucidasans -12" \
            -foreground $fgcolor
    .g axis configure y \
            -title $ytitle \
            -titlefont "lucidasans -12" \
            -titlecolor $fgcolor \
            -descending "1" \
            -tickfont "lucidasans -12" \
            -stepsize 15 \
            -subdivisions 2 \
            -command FormatYLabel \
            -foreground $fgcolor
    .g axis configure y2 \
            -title $y2title \
            -titlefont "lucidasans -12" \
            -titlecolor $fgcolor \
            -tickfont "lucidasans -12" \
            -hide no \
            -foreground $fgcolor
    Blt_ZoomStack .g
}


# Create the graph widget.
proc MakeGraph2 {units} {
    variable bgcolor
    variable fgcolor
    graph .g2 -background $bgcolor -highlightthickness 0
    .g2 element create line1 -x dist -y pace -label "Pace"
    .g2 element create line2 -x dist -y heartrate -label "Heartrate" -mapy y2
    .g2 legend configure -foreground $fgcolor

    .g2 element configure line1 \
        -color blue4 \
        -symbol circle \
        -fill blue1 \
        -pixels 0.04i \
        -smooth quadratic

    .g2 element configure line2 \
        -color purple4 \
        -symbol square \
        -fill purple1 \
        -pixels 0.04i \
        -smooth quadratic

     if {$units == "metric"} {
         set xtitle "Distance (km)"
         set ytitle "Pace (min/km)"
         set y2title "Heartrate (bpm)"
     } else {
         set xtitle "Distance (mi)"
         set ytitle "Pace (min/mi)"
         set y2title "Heartrate (bpm)"
     }

    .g2 axis configure x \
            -title $xtitle \
            -rotate 0 \
            -titlefont "lucidasans -12" \
            -tickfont "lucidasans -12" \
            -titlecolor $fgcolor \
            -foreground $fgcolor
    .g2 axis configure y \
            -title $ytitle \
            -titlefont "lucidasans -12" \
            -titlecolor $fgcolor \
            -descending "1" \
            -tickfont "lucidasans -12" \
            -stepsize 15 \
            -subdivisions 2 \
            -command FormatYLabel \
            -foreground $fgcolor
    .g2 axis configure y2 \
            -title $y2title \
            -titlefont "lucidasans -12" \
            -tickfont "lucidasans -12" \
            -titlecolor $fgcolor \
            -hide no \
            -foreground $fgcolor
    Blt_ZoomStack .g2
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

# Create the map on a label widget.
proc MakeMap {} {
    # Call goroutine to create png
    createImg csv.dat [ ::fileutil::tempdir ]
    image create photo imgobj -file "image.png"
    .theMap configure -image imgobj
}

# Handle loading a new file.
proc Update {units} {
    file delete  [ ::fileutil::tempdir ][file separator]csv.dat
    #clear out the old data first
    .t delete 0 last
    .t2 delete 0 last
    dist set {}
    pace set {}
    altitude set {}
    cadence set {}
    heartrate set {}
    PopulateVectors $units
    MakeLapTable $units .t
    MakeSessionTable $units .t2
    MakeMap
}

# Initialize data and GUI.
ttk::label .theMap
    if {$unitsystem == "metric"} {
    set distanceheader { 0 "Distance(km)"}
    } else {
    set distanceheader { 0 "Distance(mile)"}
    }
set colh [concat {0 "Lap"} $distanceheader {0 "Time(min:sec)" 0 "Calories(kcal)"}]
tablelist::tablelist .t -columns $colh -stretch all
tablelist::tablelist .t2 -columns {0 "Attribute" 0 "Value"} -stretch all
PopulateVectors $unitsystem
MakeGraph  $unitsystem
MakeGraph2 $unitsystem
MakeLapTable $unitsystem .t
MakeSessionTable $unitsystem .t2
MakeMap

# Bind a motion event to the procedure that generates
# a marker for the points on the graph.
bind mytag <Motion>  { doFindElement %W %x %y }
blt::AddBindTag .g mytag
blt::AddBindTag .g2 mytag

proc SwapAlt {} {
   catch {.pnd forget .g2 }
  .pnd add .g  
}

proc SwapHr {} {
   catch {.pnd forget .g }
  .pnd add .g2  
}
 

# And display!
# Add both widgets to the paned window.
ttk::frame .f -relief ridge
pack .f -side top -fill x

ttk::button .f.b -text "Load File..." -command "Update $unitsystem"
ttk::button .f.b1 -text "Pace vs. Altitude" -command  "SwapAlt" 
ttk::button .f.b2 -text "Pace vs. Heartrate" -command "SwapHr" 
pack .f.b .f.b1 .f.b2 -side left -fill x

pack .f .t2 .t -side top -fill x

.pnd add .theMap
pack .pnd -fill both -expand 1
wm deiconify .

# File cleanup.
#file delete image.png
file delete  [ ::fileutil::tempdir ][file separator]csv.dat
