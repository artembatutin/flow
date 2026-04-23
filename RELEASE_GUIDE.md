# GitHub Release Guide for Flow

This guide provides step-by-step instructions for releasing Flow on GitHub.

## Pre-Release Checklist

### 1. Code Quality & Testing
- [ ] Run all unit tests and ensure they pass
- [ ] Test the application on different macOS versions
- [ ] Verify all features work correctly
- [ ] Check for memory leaks and performance issues
- [ ] Test with multiple IDEs (Cursor, Windsurf, VS Code, Xcode, JetBrains)

### 2. Documentation Review
- [ ] Update README.md with latest features
- [ ] Ensure all documentation files are up-to-date
- [ ] Check that screenshots/images are current
- [ ] Verify all links work correctly
- [ ] Update version numbers throughout documentation

### 3. Version Management
- [ ] Update version in `Flow.xcodeproj/project.pbxproj`
- [ ] Update version in `Flow/Resources/Info.plist` if applicable
- [ ] Update version references in documentation
- [ ] Create version tag in git

## Release Process

### Step 1: Prepare the Release Build

1. **Clean Build Folder**
   ```bash
   # In Xcode: Product → Clean Build Folder (⇧⌘K)
   # Or from command line:
   xcodebuild clean -project Flow.xcodeproj -scheme Flow
   ```

2. **Archive the Application**
   ```bash
   # Command line archiving
   xcodebuild archive -project Flow.xcodeproj -scheme Flow -archivePath Flow.xcarchive
   ```

3. **Export for Distribution**
   ```bash
   # Export as Developer ID signed application
   xcodebuild -exportArchive -archivePath Flow.xcarchive -exportPath Distribution -exportOptionsPlist exportOptions.plist
   ```

### Step 2: Create the DMG File

1. **Prepare DMG Structure**
   ```bash
   # Create a temporary directory for DMG contents
   mkdir -p "Flow-Installer"
   cp -R "Distribution/Flow.app" "Flow-Installer/"
   
   # Create Applications shortcut
   ln -s /Applications "Flow-Installer/Applications"
   ```

2. **Create the DMG**
   ```bash
   # Create a disk image
   hdiutil create -volname "Flow" -srcfolder "Flow-Installer" -ov -format UDZO "Flow-[VERSION].dmg"
   
   # Code sign the DMG (if you have a Developer ID)
   codesign --sign "Developer ID Application: Your Name" "Flow-[VERSION].dmg"
   ```

3. **Notarize the DMG** (Required for macOS 10.15+)
   ```bash
   # Upload for notarization
   xcrun notarytool submit "Flow-[VERSION].dmg" --keychain-profile "AC_PASSWORD" --wait
   
   # Staple the notarization ticket
   xcrun stapler staple "Flow-[VERSION].dmg"
   ```

### Step 3: Create GitHub Release

1. **Create and Push Tag**
   ```bash
   # Create annotated tag
   git tag -a v1.0.0 -m "Release version 1.0.0"
   
   # Push tag to remote
   git push origin v1.0.0
   ```

2. **Create GitHub Release**
   - Go to your GitHub repository
   - Click on "Releases" → "Create a new release"
   - Choose the tag you just pushed
   - Fill in release title and description
   - Upload the DMG file as a release asset
   - Publish the release

### Step 4: Post-Release Tasks

1. **Update Documentation**
   - Update installation instructions with new version
   - Add release notes to CHANGELOG.md
   - Update any version-specific documentation

2. **Announce the Release**
   - Share on social media
   - Post in relevant communities/forums
   - Update your website if applicable

3. **Monitor Feedback**
   - Watch GitHub issues for bug reports
   - Monitor download statistics
   - Respond to user questions and feedback

## Release Notes Template

```markdown
# Flow v[VERSION]

## What's New
- [List new features]
- [List improvements]

## Bug Fixes
- [List bug fixes]

## Known Issues
- [List any known issues]

## Installation
Download the latest DMG file from the assets below and follow the installation instructions in the README.

## System Requirements
- macOS 12.0 or later
- Microphone access permissions

## Support
For issues and questions, please visit our [GitHub Issues](https://github.com/artembatutin/flow/issues) page.
```

## Security Considerations

### Code Signing
- Always sign your application with a valid Developer ID certificate
- Notarize the application for macOS 10.15+ compatibility
- Include secure timestamp in signatures

### Distribution Security
- Use HTTPS for all downloads
- Verify file integrity with checksums
- Keep private keys secure and backed up
- Regular security audits of dependencies

## Automation Script

Here's a basic automation script for the release process:

```bash
#!/bin/bash
# release.sh - Automate the release process

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version>"
    exit 1
fi

echo "Starting release process for version $VERSION"

# Clean and build
xcodebuild clean -project Flow.xcodeproj -scheme Flow
xcodebuild archive -project Flow.xcodeproj -scheme Flow -archivePath "Flow-$VERSION.xcarchive"

# Export
xcodebuild -exportArchive -archivePath "Flow-$VERSION.xcarchive" -exportPath "Distribution-$VERSION" -exportOptionsPlist exportOptions.plist

# Create DMG
mkdir -p "Flow-Installer-$VERSION"
cp -R "Distribution-$VERSION/Flow.app" "Flow-Installer-$VERSION/"
ln -s /Applications "Flow-Installer-$VERSION/Applications"
hdiutil create -volname "Flow $VERSION" -srcfolder "Flow-Installer-$VERSION" -ov -format UDZO "Flow-$VERSION.dmg"

# Cleanup
rm -rf "Flow-Installer-$VERSION"
rm -rf "Distribution-$VERSION"
rm -f "Flow-$VERSION.xcarchive"

echo "Release build complete: Flow-$VERSION.dmg"
```

## Troubleshooting Common Issues

### Code Signing Issues
- Ensure your Developer ID certificate is valid and not expired
- Check that the certificate is in your keychain
- Verify the bundle identifier matches your provisioning profile

### Notarization Issues
- Ensure all binaries are properly signed before notarization
- Check for any private API usage
- Review notarization logs for specific issues

### DMG Creation Issues
- Ensure sufficient disk space for temporary files
- Check file permissions on source files
- Verify hdiutil is working correctly

## Best Practices

1. **Version Numbering**: Use semantic versioning (MAJOR.MINOR.PATCH)
2. **Testing**: Always test the final DMG on a clean system
3. **Documentation**: Keep release notes detailed and user-friendly
4. **Communication**: Notify users of significant changes
5. **Backup**: Keep backups of all release artifacts
6. **Monitoring**: Track download metrics and user feedback

## Contact & Support

For questions about the release process, please:
- Check existing documentation first
- Search closed issues for similar problems
- Create a new issue with detailed information
- Join community discussions

Remember: Always test your release process thoroughly before publishing to ensure a smooth experience for your users.
