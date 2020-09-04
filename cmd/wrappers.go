//wrappers.go
package main

/*
#cgo linux   CFLAGS: "-I/usr/include/tcl8.6"
#cgo linux   LDFLAGS: -L/usr/lib/x86_64-linux-gnu -ltcl8.6 
#cgo windows CFLAGS:  -IC:/GoProjects/src/tk8.6/include 
#cgo windows LDFLAGS: -LC:/GoProjects/src/tk8.6/lib -ltcl86
#include <tcl.h>
#include <tclDecls.h>

int CreateImg_Cmd_cgo(ClientData cdata, Tcl_Interp *interp, int objc,
	Tcl_Obj *const objv[]) {
	int CreateImg_Cmd(ClientData cdata, Tcl_Interp *interp, int objc,
		Tcl_Obj *const objv[]);
	return CreateImg_Cmd(cdata, interp, objc, objv);
}

int CreateCsv_Cmd_cgo(ClientData cdata, Tcl_Interp *interp, int objc,
	Tcl_Obj *const objv[]) {
	int CreateCsv_Cmd(ClientData cdata, Tcl_Interp *interp, int objc,
		Tcl_Obj *const objv[]);
	return CreateCsv_Cmd(cdata, interp, objc, objv);
}


*/
import "C"
