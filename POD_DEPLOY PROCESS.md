- Assure `Carthage Project/${POD_NAME}.xcodeproj` and `Pods Project/${POD_NAME}.xcworkspace` have all dependencies added.
- Run `podUpdate.command`
- Run `carthageUpdate.command`
- Run `checkBuild.command`
- Change version in podspec
- Update CHANGELOG.md
- Update README.md with new version if needed
- Push changes in git
- Add git tag
- Run `podPush.command`
