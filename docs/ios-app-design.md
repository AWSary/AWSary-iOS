# AWSary iOS App Design

Last reviewed from the repository on 2026-06-27.

## Purpose

AWSary is an iOS companion app for people who work with AWS services, teach AWS courses, design cloud architectures, or participate in the AWS community. Its core value is practical: it turns a large and constantly changing cloud ecosystem into searchable, mobile-friendly reference material and reusable visual assets.

The app started as an AWS service glossary and architecture-diagram helper. That remains the center of the product: users can search for an AWS service, read a concise description, hear a pronunciation clip, watch an optional explainer video, copy the description, and drag service logos into other apps. The current app has grown beyond that into a broader AWS builder companion with trending Builder Center content, AWS community discovery, App Intents and Spotlight integration, a small learning game, and a calendar planner for AWS Authorized Instructors.

The target user is not only someone casually browsing AWS marketing pages. The app is useful when a consultant, instructor, student, builder, or customer-facing technologist needs a quick answer, a logo for a diagram, a community profile, a user group link, or a prebuilt course agenda while already working on an iPhone or iPad.

## Product Principles Visible In The Current App

- Fast local reference first. The glossary, community people directory, and user group directory are bundled as JSON resources, so the main reference surfaces are available without waiting for a backend request.
- Native iOS behavior. The app uses SwiftUI navigation, TabView, searchable lists, drag and drop, App Intents, Spotlight indexing, EventKit calendar writing, SwiftData persistence, and StoreKit/RevenueCat subscription surfaces.
- Practical utility over passive reading. Many screens have an immediate action: drag a logo, copy a description, open a profile link, join a user group, add events to Calendar, rate the app, send feedback, or open a shortcut result.
- Graceful fallback. Remote configuration in About/Settings has local defaults; bundled data stores show empty or error states; app-stats data is cached and refreshed only when stale.
- Community as product content. AWS Heroes, AWS community members, and AWS User Groups are not just external links. They are indexed as first-class searchable app content and system-search content.

## Application Structure

The main iOS target is under `ios/AWSary`, with shared views and models under `ios/Shared`. The main app entry point is `awsaryApp` in `ios/AWSary/Views/AWSaryApp.swift`.

At startup, the app:

- Configures RevenueCat with the app API key.
- Registers a RevenueCat purchases delegate.
- Creates a SwiftData model container for `SystemSetting` and `CachedAppStats`.
- Shows `AppTabsView`.
- Schedules local App Intents / Spotlight indexing when needed.
- Fetches RevenueCat offerings asynchronously for premium/paywall screens.
- Applies the main purple accent color, `#5B5CFF`.

The app uses a tab-based root navigation:

- Home
- Glossary
- Community
- Game
- AAI Planner
- Search

The TabView uses `.sidebarAdaptable`, so it can adapt to larger iPad-style layouts while still behaving as a standard tab app on compact devices.

## Navigation Model

`AppTabsView` owns root tab state and cross-tab navigation. It keeps state for:

- The selected tab.
- The current shared search string.
- Search focus requests.
- Requested service, hero, and user group identifiers coming from deep links or system search.

Deep links are represented by `AWSaryDeepLink` and currently support:

- `awsary://service/{id}`
- `awsary://hero/{id}`
- `awsary://user-group/{id}`

When a service deep link arrives, the app switches to Glossary and pushes that service into the glossary `NavigationStack`. When a hero or user group deep link arrives, the app switches to Community, selects the correct Community directory if needed, and pushes the detail view.

Spotlight user activities are handled through the same dispatcher. This is important architecturally: App Intents, Spotlight, and in-app navigation share the same route model instead of each surface inventing its own navigation path.

## Home

Home is a Builder Center content surface. It fetches trending article data from:

`https://api.awsary.com/content/trending`

The response decodes into `BuildersContent` and `FeedContent` models. Articles are sorted newest first and displayed as cards. Selecting a card opens `BCArticleDetails`, a native article detail screen. The older web view path is still visible in commented code, but the active flow is native detail presentation.

Home is also one of the places where the settings/about sheet can be opened from a gear button. Visually, it uses an animated mesh gradient built from AWSary brand colors and a greeting that positions the app around building and learning.

Client value:

- Gives users an entry point into current AWS Builder Center content without leaving the app.
- Keeps the app useful even when the user is not looking for a specific service.
- Creates a bridge between static reference data and fresh educational content.

## Glossary

Glossary is the original core feature. It loads the bundled AWS service catalog through `AwsServices`, which reads `aws_services.json` from the app bundle or from a documents-directory override if present. The current bundled resource contains 282 AWS service records.

Each service record has:

- Numeric ID.
- Short service name.
- Long service name.
- Markdown-capable short description.
- Image URL that maps to a bundled AWS icon asset.
- Optional YouTube video ID.

The Glossary screen displays services in an adaptive grid, sorted alphabetically. It supports search via SwiftUI `.searchable`, filtering by the short service name. A SwiftData-backed setting controls whether service logo tiles show the label over the icon. That setting is stored as `SystemSetting` with the key `awsServiceLogoWithLabel`.

Selecting a service opens `DetailsView`.

## Service Details

The service detail screen focuses on explanation and reuse:

- Shows the AWS service logo.
- Shows the long service name and short name.
- Renders the service description using MarkdownUI.
- Allows text selection for the description.
- Provides a copy action for the short description.
- Supports drag-and-drop of the service description.
- Provides a Polly pronunciation action using an audio URL derived from the service icon name.
- Shows an embedded YouTube player when the service has a video ID.

The logo rendering is centralized through `AWSserviceImagePlaceHolderView` and related helper views. This matters because the same service icon presentation is reused across Glossary, Details, Game, Onboarding, About, App Clip, drag previews, and App Intents metadata.

Client value:

- Helps users understand unfamiliar AWS services quickly.
- Helps consultants and architects reuse AWS visuals in third-party drawing apps.
- Supports training and customer conversations where pronunciation, short definitions, and diagrams matter.

## Community

Community is a two-directory feature: People and User Groups. It uses a segmented picker at the top of the tab to switch between directories.

The People directory loads `community_members.json` through `CommunityMemberStore`. The current bundled file contains 255 community members. Each member includes:

- Stable ID.
- Name.
- Bio.
- Location.
- Image URL.
- AWS profile URL.
- Status tags, such as AWS Hero-related status.
- Specialty tags.
- Additional external links.

People can be searched by name, bio, location, status, and specialty. The screen exposes horizontal facet chips for status and specialty, and the list rows show avatar, location, tags, and a short bio preview. The detail view shows the profile image, name, location, full tag set, bio, AWS profile link, and additional links.

The User Groups directory loads `community_user_groups.json` through `CommunityUserGroupStore`. The current bundled file contains 576 user groups. Each user group includes:

- Stable ID.
- Name.
- Summary.
- Structured location, including display name, city, region, country, country code, coordinates, and timezone where available.
- Image URL.
- Join URL.
- Platform identifier.
- Topics.
- Links.
- Optional founding/network metadata.
- Metadata status.
- Optional activity metrics such as member count, upcoming event count, past event count, ratings, and capture date.

User Groups can be searched by name, summary, location, country, platform, network name, and topics. The UI includes a country menu and platform facet chips. Detail views show the group image, location, platform, activity metrics, summary, topic tags, join link, and additional links.

Client value:

- Turns AWS community discovery into a structured, searchable native experience.
- Helps users find people by skill, place, or community status.
- Helps users locate local or online AWS User Groups and jump directly to joining them.
- Makes community data available to Search, Spotlight, and App Intents rather than isolating it in one tab.

## Search

Search is a unified cross-content search surface for:

- AWS services.
- Community people.
- AWS User Groups.

It owns a live query and a submitted query. Before the user searches, it shows discovery cards that navigate to Services, People, User Groups, Game, and AAI Planner. While typing, it shows autocomplete suggestions and top matches. After submission, it shows faceted results with tabs for Top Results, Services, People, and User Groups.

Ranking is intentionally simple and local:

1. Exact name match.
2. Prefix name match.
3. Contains-name match.
4. Metadata contains query.

Ties sort alphabetically by result title.

This design keeps search explainable and fast. It also avoids adding a remote search dependency while the searchable data is already bundled in the app.

## Game

Game is a lightweight AWS service recognition exercise. It shows a random service icon without the label and asks the user to name it. The user can reveal the answer and then generate another random service.

It uses the same `AwsServices` data source and logo rendering as the Glossary. This is a good example of reusing the glossary dataset for a learning-oriented experience without introducing a separate game dataset.

Client value:

- Helps users memorize AWS service logos.
- Makes the app useful for study and casual repetition.
- Reinforces the diagramming use case because service-logo recognition is part of cloud architecture work.

## AAI Planner

AAI Planner is a utility for AWS Authorized Instructors. It lets an instructor choose an AWS training course, a start date/time, and a timezone, then write the recommended module plan, labs, breaks, lunch, Q&A, and multi-day transitions into the user calendar.

The planner uses:

- `AAIEventData` for course names, course sequences, and time zones.
- `CalendarViewModel` for EventKit write-only calendar access and event creation.
- RevenueCat subscription state to gate premium course plans.
- RevenueCatUI paywall presentation when a premium course is selected by a non-subscriber.

Free access currently includes Architecting on AWS and courses matching the Essentials naming pattern. Premium unlocks the broader set of training plans.

Client value:

- Saves instructors repetitive calendar planning work.
- Encodes practical course delivery timelines in a reusable tool.
- Provides a clear premium feature with real operational value.

## About, Settings, Premium, And Remote App Stats

About/Settings is opened from the gear button in Home and Glossary. It is implemented as a modal `NavigationStack` with several sections and detail screens.

It currently includes:

- Optional featured message from remote app stats.
- Optional update-available prompt that opens the App Store.
- About AWSary explanation and YouTube demo.
- Settings & Premium.
- Contact & Feedback.
- Legal.
- Legacy/current settings sections that are still present while the newer navigation-style About experience reaches parity.

The remote stats endpoint is:

`https://api.awsary.com/app-stats`

The main app caches this payload in SwiftData through `CachedAppStats`. On About open, it loads cached values first, then refreshes from the API if the cache is older than one hour. The App Clip has a separate simpler path that fetches app stats directly and does not share the main app's cached stats model.

The app stats payload can control:

- Current version string.
- Rating metadata and custom rating message.
- Featured message.
- Update availability.
- Merch store URL.
- Privacy policy URL.
- Terms URL.
- GitHub URL.
- Support email.
- Feedback subject and footer.
- Premium discount code and label.
- About/demo YouTube ID.

Local defaults exist for these fields, so malformed or missing remote data should not block basic About/Settings behavior.

Premium is managed through RevenueCat. The app configures RevenueCat at startup, observes subscription state through `UserViewModel`, fetches offerings, shows RevenueCatUI paywalls, supports restore purchase, and uses premium state in AAI Planner and About/Settings.

## App Intents, Shortcuts, And Spotlight

The app exposes AWSary content to iOS system surfaces through App Intents and Core Spotlight.

The indexed content types are:

- AWS Services.
- AWS Heroes, derived from community members whose statuses contain AWS Hero.
- AWS User Groups.

`AWSaryContentDataSource` is an actor that loads and caches bundled JSON resources for this system integration layer. It also computes a content version based on schema version, resource file sizes, modification dates, and content counts.

`AWSaryContentIndexer` schedules indexing from app startup. It skips work when the stored content version matches the current content version. When indexing runs, it creates app entities and submits them to `CSSearchableIndex`.

App Shortcuts expose intents for:

- Open AWS Service.
- Open AWS Hero.
- Open AWS User Group.

Each intent opens the corresponding deep link in the foreground and can return a snippet view with a compact native summary. Service snippets use rasterized bundled icon data when available; people and user group snippets use remote images with system-image fallback.

Client value:

- Users can find app content from Spotlight without first opening AWSary.
- Siri/Shortcuts can open specific content types.
- Snippets make AWSary useful as an answer surface, not only as a destination app.

## App Clip

The App Clip target has its own entry point, `AWSaryAppClipApp`, and starts with `OnboardingView`. It configures RevenueCat and a SwiftData container for `SystemSetting`.

The App Clip includes simplified versions of some shared surfaces:

- About/Settings can show remote featured messages, update prompts, logo settings, feedback, why/how content, and legal links.
- AAI Planner exists as a placeholder that explains the full app is required for the feature.

The App Clip does not use the main app's full tab structure or cached app-stats model. It is a lighter entry point intended to demonstrate or route users toward the full app experience.

## Data Layer Summary

Bundled JSON resources:

- `aws_services.json`: 282 services.
- `community_members.json`: 255 people.
- `community_user_groups.json`: 576 user groups.

Local persistence:

- `SystemSetting` in SwiftData stores user settings such as whether service logos show names.
- `CachedAppStats` in SwiftData stores the app-stats API response and cache timestamp.
- `UserDefaults` stores the last indexed content version for Spotlight/App Intents.

Remote APIs:

- `https://api.awsary.com/content/trending` for Home trending Builder Center content.
- `https://api.awsary.com/app-stats` for app configuration, featured messaging, update prompts, feedback/legal/premium links, and rating metadata.

External media and links:

- AWS service pronunciation clips are loaded from `https://cdn.awsary.com/audio/...`.
- YouTube videos are embedded with YouTubePlayerKit.
- Community avatars, user group images, profile links, join links, and extra links come from the bundled community JSON.
- App Store review/update actions use the app ID `1634871091`.

Packages and major frameworks:

- SwiftUI for UI.
- SwiftData for local persistence.
- RevenueCat and RevenueCatUI for subscriptions and paywalls.
- MarkdownUI for Markdown rendering.
- YouTubePlayerKit for embedded videos.
- EventKit for calendar writes.
- AppIntents and CoreSpotlight for system integration.
- SDWebImageSwiftUI is present as a package dependency, while current visible image loading also uses local `ImageLoaderView`/AsyncImage-style paths.

## UI And Design Language

The app uses a native SwiftUI visual language with branded accents. The primary app accent is `#5B5CFF`, with supporting AWSary colors including pink, purple, blue, and orange in specific surfaces.

Common UI patterns:

- Tab root navigation with nested `NavigationStack`s.
- `.searchable` in Glossary, Community, and Search.
- Adaptive grids for service icons and discovery cards.
- Segmented picker for Community directory switching.
- Horizontal facet chips for filtering.
- List-based settings and detail screens.
- Native links, buttons, toggles, menus, and paywall screens.
- Compact cards for community rows, search discovery, article cards, and snippets.

The design is functional and tool-oriented rather than marketing-first. The app uses personality in places such as Home's greeting and visual gradient, but the main screens prioritize scanning, filtering, and action.

## Current Strengths

- Strong bundled content foundation: services, people, and user groups all work as local app data.
- Multiple entry points into the same content: tabs, search, deep links, Spotlight, App Intents, and snippets.
- Clear utility beyond reading: drag-and-drop logos, copy text, calendar event creation, external profile/group links, and system search.
- Monetization is tied to a specific high-value workflow rather than blocking the main glossary.
- Remote app messaging and links can evolve without an app release while retaining local fallback defaults.

## Current Constraints And Future Discussion Points

- Search is local and simple. This is fast and understandable, but future relevance tuning, typo tolerance, or semantic search would require a more advanced local index or backend support.
- The glossary search currently filters by service short name in the Glossary tab, while unified Search searches more fields. Future UX could make these behaviors more consistent.
- Community data is bundled. This is reliable offline, but content freshness depends on the local batch generation and app release/resource refresh process.
- Home depends on a remote trending endpoint and currently has no rich offline fallback beyond showing no loaded articles if the fetch fails.
- The About screen still contains both the newer structured navigation sections and older settings/content sections. Future cleanup can remove duplicated legacy sections once parity is accepted.
- Premium gating is currently concentrated around AAI Planner and merch discount behavior. Future premium features should preserve the app's core free reference value while expanding practical workflows.
- The App Clip is intentionally lighter than the full app. Future work should decide whether it is primarily an onboarding surface, a focused glossary preview, or a conversion path for premium/full-app features.
- The app has several strong content domains now: AWS services, Builder articles, community people, user groups, and instructor planning. Future navigation decisions should keep these domains coherent rather than adding unrelated tabs for every new idea.

## Short Description For LLM Context

AWSary for iOS is a SwiftUI AWS companion app. It combines a bundled AWS service glossary with service icons, Markdown descriptions, copy/drag actions, pronunciation audio, and optional video explanations; a Home feed of trending AWS Builder Center articles; a Community tab for searchable AWS community members and global User Groups; unified in-app search across services, people, and user groups; App Intents and Spotlight indexing for opening AWS services, Heroes, and User Groups from system surfaces; a logo-recognition learning game; and an AAI Planner that writes AWS training module schedules into Calendar with some plans gated by RevenueCat premium.

The main architecture is a tab-based SwiftUI app with local JSON-backed stores for glossary and community data, SwiftData for settings and cached remote app stats, RevenueCat for subscriptions, EventKit for calendar writing, MarkdownUI and YouTubePlayerKit for rich content, and deep links shared by App Intents, Spotlight, and in-app navigation. The app's value is not just marketing content: it is a practical reference and workflow tool for AWS consultants, instructors, builders, students, and community members.
