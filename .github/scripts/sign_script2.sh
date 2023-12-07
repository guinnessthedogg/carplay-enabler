#!/bin/zsh

# Check if an IPA file is provided
if [ -z "$1" ]
	then
		echo "$0 [ipa file to enable DiskProbe on]"
		exit 1
fi

# Create a temporary directory and move into it
mkdir temp
cd temp

# Extract the IPA file
echo "Extracting ipa"
unzip -q ../$1

# Find the app within the Payload directory
app=$(ls Payload/)
echo "Found $app"

# Check for embedded.mobileprovision and handle entitlements
if [ -f "Payload/$app/embedded.mobileprovision" ]; then
	echo "Merging entitlements"

	# Extract entitlements and merge with DiskProbe.entitlements
	security cms -D -i "Payload/$app/embedded.mobileprovision" > provision.plist
	/usr/libexec/PlistBuddy -x -c 'Print:Entitlements' provision.plist > entitlements.plist
	/usr/libexec/PlistBuddy -x -c "Merge ../DiskProbe.entitlements" entitlements.plist

	# Sign the app with the merged entitlements
	echo "Signing with DiskProbe entitlement"
	uname=$(id -un)
	codesign -d --entitlements entitlements.plist -f -s "Apple Development: $uname" Payload/$app

	# Check if signing was successful
	signed=$(codesign -d --entitlements - "Payload/$app" | grep -c "com.creaturecoding.DiskProbe")
	if [ $signed > 0 ]; then
		echo "Signed successfully!"
		zip -r "$app.ipa" Payload -q
		mv "$app.ipa" ../DiskProbe.ipa		
	else
		echo "Failed to sign!"
		exit 1
	fi

else
	echo "Generating entitlement"

	# Sign the app directly with DiskProbe.entitlements
	uname=$(id -un)
	codesign -d --entitlements ../DiskProbe.entitlements -f -s "Apple Development: $uname" Payload/$app
	signed=$(codesign -d --entitlements - "Payload/$app" | grep -c "com.creaturecoding.DiskProbe")
	if [ $signed > 0 ]; then
		echo "Signed successfully!"
		zip -r "$app.ipa" Payload -q
		mv "$app.ipa" ../DiskProbe.ipa		
	else
		echo "Failed to sign!"
		exit 1
	fi
fi

# Move out of the temp directory and clean up
cd ..
echo "Cleaning temporary files"
rm -rf temp
