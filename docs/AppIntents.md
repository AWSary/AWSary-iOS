# App Intents

AWSary exposes public app content to the system through App Intents entities:

- `AWSServiceEntity` for bundled AWS services from `aws_services.json`
- `AWSHeroEntity` for public AWS Hero profiles from `community_members.json`
- `AWSUserGroupEntity` for public User Groups from `community_user_groups.json`

The integration is isolated under `ios/AWSary/AppIntents` and uses the existing app models and bundled JSON resources. It does not introduce a backend or duplicate content.

## Verification

Build the app:

```sh
xcodebuild -project ios/awsary.xcodeproj -scheme 'awsary (iOS)' -destination 'generic/platform=iOS Simulator' build
```

Verify entity lookup and search by exercising the query types in a local debug session:

- `AWSServiceEntityQuery().entities(for:)` resolves existing integer service IDs.
- `AWSServiceEntityQuery().entities(matching:)` searches service name, full name, summary text, and icon-derived service tokens.
- `AWSHeroEntityQuery().entities(for:)` resolves existing public Hero IDs.
- `AWSUserGroupEntityQuery().entities(for:)` resolves existing User Group IDs.
- `AWSaryAppIntentsDebugVerification.run()` returns a lightweight lookup/search/route smoke report without needing a separate test target.

Verify open routing on device or simulator with URLs:

- `awsary://service/<id>`
- `awsary://hero/<id>`
- `awsary://user-group/<id>`

Spotlight/App Intents indexing runs after app launch through `AWSaryContentIndexer`. It computes a simple bundled-content version from resource metadata and counts, stores it in `UserDefaults`, and skips unchanged data. Indexing uses public bundled data only and runs in a background utility task.

Spotlight, Siri, Shortcuts, and Apple Intelligence discovery can depend on iOS version, language, region, indexing delay, and system feature availability. Device testing is more representative than the simulator for system discovery.
