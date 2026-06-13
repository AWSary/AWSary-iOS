# TestFlight CI

This repo can build AWSary from a selected branch, tag, pull request ref, or SHA and upload it to TestFlight with GitHub Actions and fastlane.

## Workflow

Run the `TestFlight` workflow manually from GitHub Actions.

Inputs:

- `ref`: the branch, tag, SHA, or PR ref to build. For a pull request, use `pull/123/head`.
- `runner_labels`: JSON runner labels. Use `["macos-26"]` for a GitHub-hosted runner with the iOS 26 SDK, or labels for an AWS Mac self-hosted runner such as `["self-hosted","macOS","ARM64","aws-mac"]`.
- `testflight_groups`: optional comma-separated TestFlight group names.
- `release_notes`: optional notes shown in TestFlight.

The workflow uses the `testflight` GitHub Environment so releases can be gated with required reviewers.

## Required Secrets

Add these secrets to the repository or the `testflight` environment:

- `APPLE_TEAM_ID`: Apple Developer Team ID, currently `67Z34DP7CK` in the Xcode project.
- `BUILD_CERTIFICATE_BASE64`: base64-encoded Apple Distribution `.p12` certificate.
- `P12_PASSWORD`: password for the `.p12` certificate.
- `BUILD_PROVISION_PROFILE_BASE64`: base64-encoded App Store provisioning profile for `pt.tig.awsary`.
- `KEYCHAIN_PASSWORD`: temporary CI keychain password.
- `APP_STORE_CONNECT_API_KEY_ID`: App Store Connect API key ID.
- `APP_STORE_CONNECT_API_ISSUER_ID`: App Store Connect issuer ID.
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`: base64-encoded App Store Connect `.p8` key.

Example encoding commands:

```sh
base64 -i AppleDistribution.p12 | pbcopy
base64 -i AWSary_AppStore.mobileprovision | pbcopy
base64 -i AuthKey_ABC123DEFG.p8 | pbcopy
```

## AWS Mac Runner Notes

Register the Mac as a self-hosted GitHub Actions runner and give it stable labels, for example `aws-mac`, `macOS`, and `ARM64`. Install the required Xcode version before assigning jobs. The current app deployment target is iOS 26.0, so the runner must have an Xcode version with the iOS 26 SDK.

Keep signing assets in GitHub secrets, not on the runner image. That keeps the same workflow usable on GitHub-hosted runners and AWS Mac runners.

## TestFlight Build Limit

Apple's "up to 100 builds" TestFlight wording is an active-availability limit per app in App Store Connect, not a monthly quota. It means you should periodically expire old TestFlight builds if CI uploads frequently.
