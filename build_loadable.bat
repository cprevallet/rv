REM Build
go build -o .\lib\fit.dll -buildmode=c-shared .\cmd\goroutines.go .\cmd\wrappers.go
REM Install
REM mkdir .\interp\lib\fit
REM copy .\lib\fit.dll .\interp\lib\fit\fit.dll
REM copy .\lib\pkgIndex.tcl .\interp\lib\fit\pkgIndex.tcl
REM copy .\lib\fit.tcl .\interp\lib\fit\fit.tcl
