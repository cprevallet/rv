package genmap

import (
  "bufio"
  "encoding/csv"
//  "fmt"
  "image"
  "image/color"
  //"image/png"
  "io"
  "path/filepath"
  "os"
  "strconv"
  "strings"
  "github.com/flopp/go-staticmaps"
  "github.com/golang/geo/s2"
)

func IsFloat(s string) bool {
    // Does the string contain a float number?
    _, err := strconv.ParseFloat(s, 64) 
    return err == nil
}

func readInputs(filename string, filepath string, latcol int, lngcol int) ([]s2.LatLng) {
    csvFile, _ := os.Open(filepath + string(os.PathSeparator) + filename)
    reader := csv.NewReader(bufio.NewReader(csvFile))
    var position []s2.LatLng
    for {
        line, error := reader.Read()
        if error == io.EOF {
            break
        } else if error != nil {
            panic(error)
        }
        if !IsFloat(line[0]) { continue }  //skip the header
        badrec := 0
        for _, item := range line {
            if (item == "NaN" || item == "Invalid") {badrec = 1}
        }
        if (badrec == 0) {
            lat, err := strconv.ParseFloat(line[latcol], 64)
            if err != nil {panic(err)}
            lng, err := strconv.ParseFloat(line[lngcol], 64)
            if err != nil {panic(err)}
            position = append(position, s2.LatLngFromDegrees(lat, lng))
        }
    }
    return position
}

// Entry point for cgo
func Mapimg(fname string, fpath string) (image.Image) {
  position := readInputs(fname, fpath, 3, 4)
  ctx := sm.NewContext()
  ctx.SetSize(800, 600)
  ctx.AddPath(sm.NewPath(position, color.RGBA{0, 0, 0xff, 0xff}, 2.0))
  // Start
  ctx.AddMarker(sm.NewMarker(position[0], color.RGBA{0, 0x80, 0, 0xff}, 12.0))
  // Laps
  lapfname := strings.TrimSuffix(fname, filepath.Ext(fname)) + "_lap" + filepath.Ext(fname)
  mposition := readInputs(lapfname, fpath, 2, 3)
        for i, mpos := range mposition {
            mrkr := sm.NewMarker(mpos, color.RGBA{0, 0, 0xff, 0xff}, 12.0)
            mrkr.Label = strconv.Itoa(i+1)
            ctx.AddMarker(mrkr)
        }
  // End
  ctx.AddMarker(sm.NewMarker(position[len(position)-1], color.RGBA{0xff, 0, 0, 0xff}, 12.0))

  img, err := ctx.Render()
  if err != nil {
    panic(err)
  }
  return img
}
