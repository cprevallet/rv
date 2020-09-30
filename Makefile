# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
BINARY_NAME=libfit
BINARY_WIN=$(BINARY_NAME).dll
BINARY_UNIX=$(BINARY_NAME).so
SOURCE_FILES=$(wildcard ./cmd/*.go)
DEPS_UNIX=libtcl8.6 tcl8.6-dev tkblt tcllib tklib libtk8.6 build-essential

all: test install

#TODO
test: 
			$(GOTEST) -v ./...

clean: 
			$(GOCLEAN) -r 
ifeq ($(OS),Windows_NT)
			del .\lib\$(BINARY_WIN)
			if exist "interp" rmdir /Q /S .\interp
else
			rm -f ./lib/$(BINARY_UNIX)
endif

deps:
# Under Windows, all dependencies except tkblt are satisfied by a binary distribution of TK/TCL 
#	Provided by Thomas Perschak at https://bitbucket.org/tombert/tcltk/downloads/ 
ifeq ($(OS),Windows_NT)
			if exist "interp" rmdir /Q /S .\interp
			tar -xzf tcltk86-8.6.10-0.tcl86.Win10.x86_64.tgz
			rename tcltk86-8.6.10-0.tcl86.Win10.x86_64 interp
else
			sudo apt install $(DEPS_UNIX)
endif
			$(GOGET) github.com/tormoder/fit
			$(GOGET) github.com/flopp/go-staticmaps
			$(GOGET) github.com/golang/geo/s2

build: deps
ifeq ($(OS),Windows_NT)
			$(GOBUILD) -o ./lib/$(BINARY_WIN) -buildmode=c-shared $(SOURCE_FILES)
else
			$(GOBUILD) -o ./lib/$(BINARY_UNIX) -buildmode=c-shared $(SOURCE_FILES)
endif

install: build
#	The tkblt graphics widget is not provided by Perschak's distribution and it
#	requires MSYS under Windows to build so it's not easy to automate in a Makefile.  
#	For those who wish to build it themselves, the source can be found here:
#	https://sourceforge.net/projects/tkblt/ 
#	For simplicity of this makefile, we'll copy a prebuilt dll into the interpreter 
#	directory.
ifeq ($(OS),Windows_NT)
			mkdir .\interp\lib\tkblt3.2
			mkdir .\interp\lib\fit1.0
			copy .\tkblt3.2\*.* .\interp\lib\tkblt3.2
			copy .\lib\libfit.dll .\interp\lib\fit1.0
			copy .\lib\fit.tcl .\interp\lib\fit1.0
			copy .\lib\pkgIndex.tcl .\interp\lib\fit1.0
else
			sudo mkdir -p /usr/lib/tcltk/x86_64-linux-gnu/fit
			sudo mkdir -p /usr/share/tcltk/rv
			@echo "Installing files..."
			sudo cp ./lib/libfit.so /usr/lib/tcltk/x86_64-linux-gnu/fit
			sudo cp ./lib/fit.tcl /usr/lib/tcltk/x86_64-linux-gnu/fit
			sudo cp ./lib/pkgIndex.tcl /usr/lib/tcltk/x86_64-linux-gnu/fit
			sudo cp paned.tcl /usr/share/tcltk/rv
			sudo cp prepare_packages.tcl /usr/share/tcltk/rv
			sudo cp rv_imperial.sh /usr/bin/rv_imperial
			sudo cp rv_metric.sh /usr/bin/rv_metric
			sudo cp smartwatch-charging.svg /usr/share/pixmaps
			sudo cp rv_imperial.desktop /usr/share/applications
			sudo cp rv_metric.desktop /usr/share/applications
endif

uninstall:
ifeq ($(OS),Windows_NT)
else
			sudo rm /usr/bin/rv_imperial
			sudo rm /usr/bin/rv_metric
			sudo rm /usr/share/pixmaps/smartwatch-charging.svg
			sudo rm /usr/share/applications/rv_imperial.desktop
			sudo rm /usr/share/applications/rv_metric.desktop
			sudo rm -rf /usr/share/tcltk/rv
			sudo rm -rf /usr/lib/tcltk/x86_64-linux-gnu/fit
endif

run:
ifeq ($(OS),Windows_NT)
			.\rv_imperial.bat
else
			./rv_imperial.sh
endif
