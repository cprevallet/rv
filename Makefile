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
prefix = /usr

all: install

#TODO
#test: 
#			$(GOTEST) -v ./...

clean: 
			$(GOCLEAN) -r 
ifeq ($(OS),Windows_NT)
			del .\lib\$(BINARY_WIN)
			if exist "interp" rmdir /Q /S .\interp
else
			rm -f ./lib/$(BINARY_UNIX)
			rm -f ./docs/*.1
			rm -f ./docs/*.gz
endif

deps:
# Under Windows, all dependencies except tkblt are satisfied by a binary distribution of TK/TCL 
#	Provided by Thomas Perschak at https://bitbucket.org/tombert/tcltk/downloads/ 
ifeq ($(OS),Windows_NT)
			if exist "interp" rmdir /Q /S .\interp
			tar -xzf tcltk86-8.6.10-0.tcl86.Win10.x86_64.tgz
			rename tcltk86-8.6.10-0.tcl86.Win10.x86_64 interp
else
			apt install $(DEPS_UNIX)
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
			install -D ./lib/libfit.so $(DESTDIR)$(prefix)/lib/tcltk/x86_64-linux-gnu/fit/libfit.so
			install -D ./lib/fit.tcl $(DESTDIR)$(prefix)/lib/tcltk/x86_64-linux-gnu/fit/fit.tcl
			install -D ./lib/pkgIndex.tcl $(DESTDIR)$(prefix)/lib/tcltk/x86_64-linux-gnu/fit/pkgIndex.tcl
			install -D paned.tcl $(DESTDIR)$(prefix)/share/tcltk/rv/paned.tcl
			install -D prepare_packages.tcl $(DESTDIR)$(prefix)/share/tcltk/rv/prepare_packages.tcl
			install -D rv_imperial $(DESTDIR)$(prefix)/bin/rv_imperial
			install -D rv_metric $(DESTDIR)$(prefix)/bin/rv_metric
			install -D smartwatch-charging.svg $(DESTDIR)$(prefix)/share/pixmaps/smartwatch-charging.svg
			install -D rv_imperial.desktop $(DESTDIR)$(prefix)/share/applications/rv_imperial.desktop
			install -D rv_metric.desktop $(DESTDIR)$(prefix)/share/applications/rv_metric.desktop
endif

buildman:
ifeq ($(OS),Windows_NT)
			asciidoctor --backend html ./docs/*.txt
else
			asciidoctor --backend manpage ./docs/*.txt
endif

installman: buildman
ifeq ($(OS),Windows_NT)
else
			gzip -k ./docs/*.1
			install -D ./docs/rv_imperial.1.gz $(DESTDIR)$(prefix)/share/man/man1/rv_imperial.1.gz
			install -D ./docs/rv_metric.1.gz $(DESTDIR)$(prefix)/share/man/man1/rv_metric.1.gz
endif


uninstall:
ifeq ($(OS),Windows_NT)
else
			rm $(DESTDIR)$(prefix)/bin/rv_imperial
			rm $(DESTDIR)$(prefix)/bin/rv_metric
			rm $(DESTDIR)$(prefix)/share/pixmaps/smartwatch-charging.svg
			rm $(DESTDIR)$(prefix)/share/applications/rv_imperial.desktop
			rm $(DESTDIR)$(prefix)/share/applications/rv_metric.desktop
			rm -rf $(DESTDIR)$(prefix)/share/tcltk/rv
			rm -rf $(DESTDIR)$(prefix)/lib/tcltk/x86_64-linux-gnu/fit
			rm $(DESTDIR)$(prefix)/share/man/man1/rv_imperial.1.gz
			rm $(DESTDIR)$(prefix)/share/man/man1/rv_metric.1.gz
endif

run:
ifeq ($(OS),Windows_NT)
			.\rv_imperial.bat
else
			./rv_imperial
endif
