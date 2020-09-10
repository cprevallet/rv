//
// Convert a provided .fit or .tcx file to a CSV and dump it to another file.
//
package gencsv

import (
        "bytes"
	"encoding/csv"
	"fmt"
        "github.com/cprevallet/rv/strutil"
	"github.com/tormoder/fit"
	"io/ioutil"
	"os"
        "strconv"
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

// Slice up a structure.
func makeRecs(runRecs []*fit.RecordMsg) ( dumprec[][]string ) {
        // Calculate values from raw values.
	for _, record := range runRecs {
                newrec := []string{strconv.FormatFloat(float64(record.Distance)/100.0, 'G', -1, 64),
                                   strconv.FormatFloat(float64(record.Speed)/1000.0, 'G', -1, 64),
                                   strutil.DecimalTimetoMinSec(makePace(float64(record.Speed)/1000.0) * paceToMetric),
                                   record.PositionLat.String(),
                                   record.PositionLong.String(),
                                   strconv.FormatFloat(float64(record.Altitude)/5.0 - 500.0, 'G', -1, 64),
                                   strconv.Itoa(int(record.Cadence)),
                                   strconv.Itoa(int(record.HeartRate)),
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
        outfile, err2 := os.Create(csv_path + string(os.PathSeparator) + csv_filename) // For write access.
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
	// Inspect the TimeCreated field in the FileId message
	fmt.Println(fit.FileId.TimeCreated)

	// Inspect the dynamic Product field in the FileId message
	// fmt.Println(fit.FileId.GetProduct())

	// Inspect the FIT file type
	// fmt.Println(fit.Type())

	// Get the actual activity
	activity, err := fit.Activity()
	if err != nil {
		panic(err)
	}

        outrecs := makeRecs(activity.Records)
        w := csv.NewWriter(outfile)
	w.WriteAll(outrecs)
	if err := w.Error(); err != nil {
		panic(err)
	}
        infile.Close()
        outfile.Close()
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
