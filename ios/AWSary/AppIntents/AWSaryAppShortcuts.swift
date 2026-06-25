import AppIntents

struct AWSaryAppShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenAWSServiceIntent(),
            phrases: [
                "Open \(.applicationName) service",
                "Search AWS service in \(.applicationName)"
            ],
            shortTitle: "Open Service",
            systemImageName: "cloud"
        )

        AppShortcut(
            intent: OpenAWSHeroIntent(),
            phrases: [
                "Open \(.applicationName) Hero",
                "Find AWS Hero in \(.applicationName)"
            ],
            shortTitle: "Open Hero",
            systemImageName: "person.crop.circle"
        )

        AppShortcut(
            intent: OpenAWSUserGroupIntent(),
            phrases: [
                "Open \(.applicationName) User Group",
                "Find AWS User Group in \(.applicationName)"
            ],
            shortTitle: "Open User Group",
            systemImageName: "person.3.fill"
        )
    }
}
