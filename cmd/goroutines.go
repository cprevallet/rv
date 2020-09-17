//example.go v0.2.0
//compile like this:
// linux
// go build -o goroutines.so -buildmode=c-shared goroutines.go wrappers.go
// windows
// go build -o goroutines.dll -buildmode=c-shared goroutines.go wrappers.go
package main

/*
#cgo linux   CFLAGS: "-I/usr/include/tcl8.6"
#cgo linux   LDFLAGS: -L/usr/lib/x86_64-linux-gnu -ltcl8.6 
#cgo windows CFLAGS:  -IC:/GoProjects/src/tk8.6/include 
#cgo windows LDFLAGS: -LC:/GoProjects/src/tk8.6/lib -ltcl86
#include <stdlib.h>
#include <tcl.h>
#include <tclDecls.h>

int CreateImg_Cmd_cgo(ClientData cdata, Tcl_Interp *interp, int objc,
	Tcl_Obj *const objv[]);
int CreateCsv_Cmd_cgo(ClientData cdata, Tcl_Interp *interp, int objc,
	Tcl_Obj *const objv[]);
*/
import "C"

import (
        "github.com/cprevallet/rv/genmap"
        "github.com/cprevallet/rv/gencsv"
        "image/png"
        "os"
	"reflect"
	"unsafe"
)

const (
	TCL_OK       = 0
	TCL_ERROR    = 1
	TCL_RETURN   = 2
	TCL_BREAK    = 3
	TCL_CONTINUE = 4
)



func (interp *C.struct_Tcl_Interp) createCommand(name string,
	f *C.Tcl_ObjCmdProc) {
	cName := C.CString(name)
	defer C.free(unsafe.Pointer(cName))
	C.Tcl_CreateObjCommand(interp, cName, f, nil, nil)
}

func (interp *C.struct_Tcl_Interp) wrongNumArgs(objc C.int,
	objv **C.Tcl_Obj, message string) {
	var cMessage *C.char
	if message == "" {
		cMessage = nil
	} else {
		cMessage = C.CString(message)
		defer C.free(unsafe.Pointer(cMessage))
	}
	C.Tcl_WrongNumArgs(interp, objc, objv, cMessage)
}

func slicify(objc C.int, objv **C.Tcl_Obj) (objs []*C.Tcl_Obj) {
	// http://stackoverflow.com/a/14828189
	sliceHeader := (*reflect.SliceHeader)(unsafe.Pointer(&objs))
	sliceHeader.Cap = (int)(objc)
	sliceHeader.Len = (int)(objc)
	sliceHeader.Data = uintptr(unsafe.Pointer(objv))
	return
}

//export CreateImg_Cmd
func CreateImg_Cmd(cdata C.ClientData, interp *C.struct_Tcl_Interp,
	objc C.int, objv **C.Tcl_Obj) C.int {
	if objc != 3 {
		interp.wrongNumArgs(1, objv, "filename filepath")
		return TCL_ERROR
	}
        objs := slicify(objc, objv)
        var i C.int
        filename := C.GoString(C.Tcl_GetStringFromObj(objs[1], &i))
        var i2 C.int
        filepath := C.GoString(C.Tcl_GetStringFromObj(objs[2], &i2))
        
        // Create the map in "image.png"
        img := genmap.Mapimg(filename, filepath)  //image.Image - see genmap.go file
        if img != nil {
                f, _ := os.Create("image.png")
                png.Encode(f, img)
	        return TCL_OK
        } else {
               return TCL_ERROR
        }
}

//export CreateCsv_Cmd
func CreateCsv_Cmd(cdata C.ClientData, interp *C.struct_Tcl_Interp,
	objc C.int, objv **C.Tcl_Obj) C.int {
	if objc != 4 {
		interp.wrongNumArgs(1, objv, "fit_filename csv_filename csv_path")
		return TCL_ERROR
	}
        objs := slicify(objc, objv)
        var i C.int
        fit_filename := C.GoString(C.Tcl_GetStringFromObj(objs[1], &i))
        var i2 C.int
        csv_filename := C.GoString(C.Tcl_GetStringFromObj(objs[2], &i2))
        var i3 C.int
        csv_path := C.GoString(C.Tcl_GetStringFromObj(objs[3], &i3))
        gencsv.CreateCSV(fit_filename, csv_filename, csv_path)
	return TCL_OK
}

//export Goroutines_Init
func Goroutines_Init(interp *C.struct_Tcl_Interp) C.int {
	interp.createCommand("::createImg", (*C.Tcl_ObjCmdProc)(C.CreateImg_Cmd_cgo))
	interp.createCommand("::createCsv", (*C.Tcl_ObjCmdProc)(C.CreateCsv_Cmd_cgo))
	return TCL_OK
}


func main() {}

