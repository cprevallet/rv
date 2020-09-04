//
// Convert a provided .fit or .tcx file to a CSV and dump it to another file.
//
package gencsv

import (
	"encoding/csv"
	"fmt"
	"github.com/cprevallet/rv/tcx"
        "github.com/cprevallet/rv/strutil"
	"github.com/jezard/fit"
	"io/ioutil"
        "log"
	"net/http"
	"os"
        "strconv"
)

var minPace = 0.56
var paceToMetric = 16.666667      // sec/meter -> min/km

// CreateTempFile takes an in-memory array of bytes and stores it in a temporary
// file location (which varies by operating system)
func CreateTempFile(bytes []byte) (tmpFile *os.File, err error) {
	tmpFile, err = ioutil.TempFile("", "tmp")
	if err != nil {
		log.Printf("%q: %s %s\n", err, "Could not open", tmpFile.Name())
		return tmpFile, err
	}
	defer tmpFile.Close()
	tmpFile.Write(bytes)
	if err != nil {
		log.Printf("%q: %s\n", err, "Could not write to open temp file.")
		return nil, err
	}
	return tmpFile, nil
}

// DeleteTempFile deletes the temp file if it exists. Assumes file
func DeleteTempFile(tmpFile *os.File) {
	// Delete the resources we created
	err := os.Remove(tmpFile.Name())
	if err != nil {
		log.Printf("%q: %s %s\n", err, "Could not delete temp file", tmpFile.Name())
	}
}

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
func makeRecs(runRecs []fit.Record) ( dumprec[][]string ) {
        // Calculate values from raw values.
	for _, record := range runRecs {
                newrec := []string{strconv.FormatFloat(record.Distance, 'G', -1, 64),
                                   strconv.FormatFloat(record.Speed, 'G', -1, 64),
                                   strutil.DecimalTimetoMinSec(makePace(record.Speed) * paceToMetric),
                                   strconv.FormatFloat(record.Position_lat, 'G', -1, 64),
                                   strconv.FormatFloat(record.Position_long, 'G', -1, 64),
                                   strconv.FormatFloat(record.Altitude, 'G', -1, 64),
                                   strconv.Itoa(int(record.Cadence))}
                dumprec = append(dumprec, newrec)
        }
		return dumprec
	}

// Parse the input bytes into structures more conducive for additional
// processing by routines in graphdata.go.
func parseInputBytes(fBytes []byte) (fType string, fitStruct fit.FitFile, tcxdb *tcx.TCXDB, runRecs []fit.Record, runLaps []fit.Lap, err error) {
	// Make a copy in a temporary folder for use with fit and tcx
	// libraries.
	tmpFile, err := CreateTempFile(fBytes)
	if err != nil {
		return "", fit.FitFile{}, nil, nil, nil, err
	}
	err = nil
	tmpFname := tmpFile.Name()
	// Determine what type of file we're looking at.
	rslt := http.DetectContentType(fBytes)
	switch {
	case rslt == "application/octet-stream":
		// Filetype is FIT, or at least it could be?
		fType = "FIT"
		fitStruct = fit.Parse(tmpFname, false)
		tcxdb = nil
		runRecs = fitStruct.Records
		runLaps = fitStruct.Laps
	case rslt == "text/xml; charset=utf-8":
		// Filetype is TCX or at least it could be?
		fType = "TCX"
		fitStruct = fit.FitFile{}
		tcxdb, err = tcx.ReadTCXFile(tmpFname)
		// We cleverly convert the values of interest into a structures we already
		// can handle.
		if err == nil {
			runRecs = tcx.CvtToFitRecs(tcxdb)
			runLaps = tcx.CvtToFitLaps(tcxdb)
		}
	}
	DeleteTempFile(tmpFile)
	return fType, fitStruct, tcxdb, runRecs, runLaps, err
}

// Parse the uploaded file, parse it and return run information suitable
// to construct the user interface.
func dumpCSV(fBytes []byte) {
	// Parse the input bytes into structures more conducive for additional
	// processing by routines in graphdata.go.
	_, _, _, runRecs, _, err := parseInputBytes(fBytes)
	if err != nil {
                panic(err)
	}
        outrecs := makeRecs(runRecs)
	w := csv.NewWriter(os.Stdout)
	w.WriteAll(outrecs)
	if err := w.Error(); err != nil {
		panic(err)
	}
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
	// Parse the input bytes into structures more conducive for additional
	// processing by routines in graphdata.go.
	_, _, _, runRecs, _, err := parseInputBytes(fBytes)
	if err != nil {
                panic(err)
	}
        outrecs := makeRecs(runRecs)
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
