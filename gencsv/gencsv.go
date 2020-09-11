//
// Convert a provided .fit or .tcx file to a CSV and dump it to another file.
//
package gencsv
//package main

import (
        "bytes"
	"encoding/csv"
	"fmt"
	"io/ioutil"
        "path/filepath"
	"os"
        "strconv"
        "strings"
        "github.com/cprevallet/rv/strutil"
	"github.com/tormoder/fit"
)

var minPace = 0.56
var paceToMetric = 16.666667      // sec/meter -> min/km

func makePace( speed float64) ( pace float64) {
	// Speed -> pace
	if speed > 1.8 { //m/s
		pace = 1.0/speed
	} else {
		pace = minPace // s/m = 15 min/mi
	}
        return
        }

// Convert an activity structure.
func convertActivityRecs(activityRecs []*fit.RecordMsg) ( dumprec[][]string ) {
        // Convert distance to meters, speed to meters/sec, pace to min/km and type conversions on 
        // from the raw values to strings.
	for _, record := range activityRecs {
                newrec := []string{
                                   strconv.FormatFloat(record.GetDistanceScaled(), 'G', -1, 64),
                                   strconv.FormatFloat(record.GetSpeedScaled(), 'G', -1, 64),
                                   strutil.DecimalTimetoMinSec(makePace(record.GetSpeedScaled()) * paceToMetric),
                                   record.PositionLat.String(),
                                   record.PositionLong.String(),
                                   strconv.FormatFloat(record.GetAltitudeScaled(), 'G', -1, 64),
                                   strconv.Itoa(int(record.Cadence)),
                                   strconv.Itoa(int(record.HeartRate)),
                        }
                dumprec = append(dumprec, newrec)
                }
		return dumprec
	}

// Convert a lap structure.
func convertSegmentRecs(segmentRecs []*fit.LapMsg) ( dumprec[][]string ) {
        // Calculate values from raw values.
	for _, record := range segmentRecs {
                // Convert distance to meters, timer time to seconds, calories to kcal and type conversions on 
                // the raw values to strings.
                newrec := []string{record.StartPositionLat.String(),
                                   record.StartPositionLong.String(),
                                   record.EndPositionLat.String(),
                                   record.EndPositionLong.String(),
                                   strconv.FormatFloat(record.GetTotalDistanceScaled(), 'G', -1, 64),
                                   strconv.FormatFloat(record.GetTotalTimerTimeScaled(), 'G', -1, 64),
                                   strconv.Itoa(int(record.TotalCalories)),
                        }
                dumprec = append(dumprec, newrec)
                }
		return dumprec
	}

// Entry point for cgo
func CreateCSV(fit_filename string, csv_filename string, csv_path string) {
        infile, err := os.Open(fit_filename) // For read access.
	if err != nil {
		panic("Can't open input file. Aborting.")
	}
	if _, err := os.Stat(csv_path); os.IsNotExist(err) {
	    os.MkdirAll(csv_path, os.ModeDir)
	}
	if err != nil {
		panic("Can't find or create output dir. Aborting.")
	}
        activityfile, err2 := os.Create(csv_path + string(os.PathSeparator) + csv_filename) // For write access.
	if err2 != nil {
		panic("Can't open output file. Aborting.")
	}
	// fBytes is an in-memory array of bytes read from the file.
	fBytes, err := ioutil.ReadAll(infile)
	if err != nil {
		panic("Can't read input file. Aborting.")
	}
	// Decode the FIT file data
	fit, err := fit.Decode(bytes.NewReader(fBytes))
	if err != nil {
		fmt.Println(err)
		return
	}
	activity, err := fit.Activity()
	if err != nil {
		panic(err)
	}

        // Generate the activity csv file.
        w := csv.NewWriter(activityfile)
        wRecs := [][]string{}
        acthdr := []string{"Distance(m)",
            "Speed(m/s)",
            "Pace(min/km)",
            "Latitude (degrees)",
            "Longitude(degrees)",
            "Altitude(m)",
            "Cadence(spm)",
            "HeartRate(bpm)",
        }
        wRecs = append(wRecs, acthdr)
        actRecs := convertActivityRecs(activity.Records)
	for _, record := range actRecs {wRecs = append(wRecs, record)}
	w.WriteAll(wRecs)
	if err := w.Error(); err != nil {
		panic(err)
	}
        activityfile.Close()

        fname := strings.TrimSuffix(csv_filename, filepath.Ext(csv_filename))
        lapfile, err3 := os.Create(csv_path + string(os.PathSeparator) + fname + "_lap" + filepath.Ext(csv_filename)) // For write access.
	if err3 != nil {
		panic("Can't open output file. Aborting.")
	}

        // Generate the lap csv file.
        w = csv.NewWriter(lapfile)
        wRecs = [][]string{}
        laphdr := []string{"Start Latitude(degrees)",
            "Start Longitude(degrees)",
            "End Latitude(degrees)",
            "End Longitude(degrees)",
            "Distance(m)",
            "Total Time(sec)",
            "Total Calories(kcal)",
        }
        wRecs = append(wRecs, laphdr)
        lapRecs := convertSegmentRecs(activity.Laps)
	for _, record := range lapRecs {wRecs = append(wRecs, record)}
	w.WriteAll(wRecs)
	if err := w.Error(); err != nil {
		panic(err)
	}
        lapfile.Close()

        infile.Close()
}

func main() {
        if len(os.Args) != 4 {
            fmt.Println("Usage:", os.Args[0], "fit_filename, csv_filename, csv_path")
            return
        }
        fit_filename := os.Args[1]
        csv_filename := os.Args[2]
        csv_path := os.Args[3]
        CreateCSV(fit_filename, csv_filename, csv_path)
}
