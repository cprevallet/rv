REM Build
go build -o .\lib\libfit.dll -buildmode=c-shared .\cmd\goroutines.go .\cmd\wrappers.go
REM Install
mkdir .\interp\lib\fit1.0
copy .\lib\libfit.dll .\interp\lib\fit1.0\libfit.dll
copy .\lib\pkgIndex.tcl .\interp\lib\fit1.0\pkgIndex.tcl
copy .\lib\fit.tcl .\interp\lib\fit1.0\fit.tcl
mkdir .\interp\lib\tkblt3.2
copy .\tkblt3.2\*.* .\interp\lib\tkblt3.2\*.*
