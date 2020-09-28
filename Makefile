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

all: test build
build:
		$(GOBUILD) -o ./lib/$(BINARY_UNIX) -buildmode=c-shared $(SOURCE_FILES)
test: 
		#TODO
		$(GOTEST) -v ./...
clean: 
		$(GOCLEAN) -r 
		rm -f ./lib/$(BINARY_WIN)
		rm -f ./lib/$(BINARY_UNIX)
run:
		$(GOBUILD) -o $(BINARY_NAME_UNIX) -buildmode=c-shared $(SOURCE_FILES)
		./rv_imperial.sh
deps:
		sudo apt install $(DEPS_UNIX)
		$(GOGET) github.com/tormoder/fit
		$(GOGET) github.com/flopp/go-staticmaps
		$(GOGET) github.com/golang/geo/s2
install:
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
		sudo cp smartwatch-charging.svg /usr/share/pixmaps
		sudo cp rv_imperial.desktop /usr/share/applications
		sudo cp rv_metric.desktop /usr/share/applications
uninstall:
		sudo rm /usr/bin/rv_imperial
		sudo rm /usr/bin/rv_metric
		sudo rm /usr/share/pixmaps/smartwatch-charging.svg
		sudo rm /usr/share/applications/rv_imperial.desktop
		sudo rm /usr/share/applications/rv_metric.desktop
		sudo rm -rf /usr/share/tcltk/rv
		sudo rm -rf /usr/lib/tcltk/x86_64-linux-gnu/fit
