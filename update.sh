#rm -rf ~/Library/Caches/org.carthage.CarthageKit/dependencies/
sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer
xcodebuild -version
time carthage update --configuration Debug
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
