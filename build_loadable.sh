#!/bin/sh
# Build
 go build -o ./lib/libfit.so -buildmode=c-shared ./cmd/goroutines.go ./cmd/wrappers.go
# Install
sudo mkdir -p /usr/lib/tcltk/x86_64-linux-gnu/fit
sudo mkdir -p /usr/share/tcltk/rv
echo "Installing files..."
sudo cp ./lib/libfit.so /usr/lib/tcltk/x86_64-linux-gnu/fit
sudo cp ./lib/fit.tcl /usr/lib/tcltk/x86_64-linux-gnu/fit
sudo cp ./lib/pkgIndex.tcl /usr/lib/tcltk/x86_64-linux-gnu/fit
sudo cp paned.tcl /usr/share/tcltk/rv
sudo cp prepare_packages.tcl /usr/share/tcltk/rv
sudo cp rv_imperial.sh /usr/bin/rv_imperial
sudo cp rv_metric.sh /usr/bin/rv_metric
