## Copyright by Sinbadflyce ##
# This script to help increasing build & version numbers
#!/bin/sh


PLIST_CK_DEV='Riot/SupportingFiles/Info.plist'
PLIST_CK_PROD='Riot/SupportingFiles/Info-prod.plist'

PLIST_CKEX_DEV='RiotShareExtension/SupportingFiles/Info.plist'
PLIST_CKEX_PROD='RiotShareExtension/SupportingFiles/Info-prod.plist'

PLIST_SIRI='SiriIntents/Info.plist'

VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" $PLIST_CK_DEV)
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" $PLIST_CK_DEV)

echo "Current Version: $VERSION_NUMBER"
echo "Current Build: $BUILD_NUMBER"

read -p 'New Version: ' NEW_VERSION
read -p 'New Build: ' NEW_BUILD

echo "New version: $NEW_VERSION"
echo "New build: $NEW_BUILD"
echo "Update new versions and build numbers..."

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" $PLIST_CK_DEV
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" $PLIST_CK_DEV

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" $PLIST_CK_PROD
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" $PLIST_CK_PROD

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" $PLIST_CKEX_DEV
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" $PLIST_CKEX_DEV

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" $PLIST_CKEX_PROD
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" $PLIST_CKEX_PROD


/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${NEW_VERSION}" $PLIST_SIRI
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${NEW_BUILD}" $PLIST_SIRI

echo "*** DONE! ***"