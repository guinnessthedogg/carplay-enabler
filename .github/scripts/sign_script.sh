#!/bin/zsh

if [ -z "$1" ]
	then
		echo "$0 [ipa file to enable DiskProbe on]"
		exit 1
fi

mkdir temp
cd temp

echo "Extracting ipa"
unzip -q ../$1

app=$(ls Payload/)

echo "Found $app"

if [ -f "Payload/$app/embedded.mobileprovision" ]; then
	echo "Merging entitlements"

	security cms -D -i "Payload/$app/embedded.mobileprovision" > provision.plist
	/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' provision.plist > entitlements.plist
	/usr/libexec/PlistBuddy -x -c "Merge ../DiskProbe.entitlements" entitlements.plist

	echo "Signing with DiskProbe entitlement"
	uname=$(id -un)
	codesign -d --entitlements entitlements.plist -f -s "Apple Development: $uname" Payload/$app

	signed=$(codesign -d --entitlements - "Payload/$app" | grep -c "com.creaturecoding.DiskProbe")
	if [ $signed > 0 ]; then
		echo "Signed successfully!"
		zip -r "$app.ipa" Payload -q
		cp "$app.ipa" ../		
	else
		echo "Failed to sign!"
		exit 1
	fi

else
	echo "Generating entitlement"
	uname=$(id -un)
	codesign -d --entitlements ../DiskProbe.entitlements -f -s "Apple Development: $uname" Payload/$app
	signed=$(codesign -d --entitlements - "Payload/$app" | grep -c "com.creaturecoding.DiskProbe")
	if [ $signed > 0 ]; then
		echo "Signed successfully!"
		zip -r "$app.ipa" Payload -q
		cp "$app.ipa" ../		
	else
		echo "Failed to sign!"
		exit 1
	fi
fi

cd ..
echo "Cleaning temporary files"
rm -rf temp
