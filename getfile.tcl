package require Tk
package require fileutil

proc GetLocation {} {
    set location ""
    if {$::tcl_platform(os) == "Windows NT"} {
            foreach i {C D E F G H I J K L M N O P Q R S T U V W X Y Z} {
                    #check if a file exists, if it does set location and break loop
                    if { [file isdirectory $i:/GARMIN/ACTIVITY] == 1} {
                            set location $i:/GARMIN/ACTIVITY
                            break
                    }
            }
       # statement(s) will execute if the boolean expression is true 
    } else {
       if {[file isdirectory /media/$::tcl_platform(user)/GARMIN/GARMIN/ACTIVITY] == 1} {
           set location /media/$::tcl_platform(user)/GARMIN/GARMIN/ACTIVITY/
       }
    }
    return $location
}

# Interactively prompt for fit binary file.
proc GetFitFile {} {
    set initDir [ GetLocation ]
    if { $initDir != ""} {
            set fit_file [tk_getOpenFile -initialdir $initDir]
    } else {
            set fit_file [tk_getOpenFile]
    }
    return $fit_file
}

