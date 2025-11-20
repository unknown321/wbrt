PROJECT=wbrt
IMAGE=$(PROJECT)
DOCKER=docker run -t --rm \
       	   -v `pwd`:/home/ubuntu/$(PROJECT) \
       	   -w /home/ubuntu/$(PROJECT) \
       	   -u $$(id -u):$$(id -g) \
       	   $(IMAGE)

LIBWDI_REPO=https://github.com/pbatard/libwdi
LIBWDI_COMMIT_SHA=30df0c0e051b0132c4b9ebed8c054bc8eb3aaaec

FLASHTOOL_URL=https://github.com/unknown321/mediatek_flash_tool/releases/download/v0.1.1/flash_tool.exe
DA_URL=https://github.com/bkerler/mtkclient/raw/refs/tags/1.9/mtkclient/Loader/MTK_AllInOne_DA_5.2136.bin

prepare:
	cat Dockerfile | docker build -t $(IMAGE) -

deps: deps/wdk deps/flash_tool.exe deps/DA.bin

deps/wdfcoinstaller.msi:
	wget -O $(@) https://go.microsoft.com/fwlink/p/?LinkID=253170

deps/wdk: deps/wdfcoinstaller.msi
	msiextract deps/wdfcoinstaller.msi -C deps/wdk
	mv "deps/wdk/Program Files/Windows Kits/8.0" deps/wdk/8.0

libwdi:
	git clone $(LIBWDI_REPO) $(@)
	cd $(@)	&& git checkout $(LIBWDI_COMMIT_SHA)

libwdi/examples/wdi-simple.exe: libwdi deps/wdk
		mkdir -p libwdi/build
		cd libwdi && \
		bash -c "./autogen.sh --prefix=/home/ubuntu/$(PROJECT)/libwdi/build \
			--host=x86_64-w64-mingw32 \
			--enable-32bit=no \
			--disable-32bit \
			--enable-debug=no \
			--with-libusb0= \
			--with-libusbk= \
			--with-userdir= \
			--with-wdkdir=\"/home/ubuntu/$(PROJECT)/deps/wdk/8.0\" \
			" && \
		echo '#define COINSTALLER_DIR "wdf"' >> config.h && \
		echo '#define X64_DIR "x64"' >> config.h && \
		make && \
		cd examples && make wdi-simple.exe

deps/flash_tool.exe:
	wget -O deps/flash_tool.exe $(FLASHTOOL_URL)

deps/DA.bin:
	wget -O deps/DA.bin $(DA_URL)

nsis:
	-rm walkman-backup-restore-tool.exe
	$(MAKE) run

walkman-backup-restore-tool.exe: deps libwdi/examples/wdi-simple.exe
	makensis installer.nsi

run:
	$(DOCKER) make walkman-backup-restore-tool.exe

clean:
	-rm -rf \
		deps/*.msi \
		deps/DA.bin \
		deps/flash_tool.exe \
		deps/wdk \
		libwdi \
		*.exe

release: walkman-backup-restore-tool.exe

.DEFAULT_GOAL = run
.PHONY: deps nsis
