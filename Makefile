.PHONY: all build clean

all: PIAWireguardGo.xcframework

build: frameworks/PIAWireguardGo.xcframework

clean:
	rm -rf frameworks lib PIAWireguardGo.xcframework

lib/iphoneos/PIAWireguardGo.a lib/iphonesimulator/PIAWireguardGo.a lib/maccatalyst/PIAWireguardGo.a:
	bash wireguard-go-bridge/build.sh

frameworks/PIAWireguardGo.xcframework: lib/iphoneos/PIAWireguardGo.a lib/iphonesimulator/PIAWireguardGo.a lib/maccatalyst/PIAWireguardGo.a
	bash create-libwg-go-xcframework.sh

PIAWireguardGo.xcframework: frameworks/PIAWireguardGo.xcframework
	rm -rf "PIAWireguardGo.xcframework"
	cp -r "frameworks/PIAWireguardGo.xcframework" "PIAWireguardGo.xcframework"
