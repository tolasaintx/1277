import SwiftUI

struct RepositoryHomeView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @EnvironmentObject private var appState: AppState
    @State private var feed: [RepositoryPackageRecord] = []

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    heroBanner
                    packageCards
                    deviceSummary
                    resourceLinks
                    footer
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
            .background(Color.black.ignoresSafeArea())
            .refreshable {
                await store.refreshAllAndWait()
                rebuildFeed()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
            .onAppear {
                store.refreshAllIfNeeded()
                if feed.isEmpty {
                    rebuildFeed()
                }
            }
            .onChange(of: store.packages) { _ in
                rebuildFeed()
            }
        }
    }

    private var heroBanner: some View {
        ZStack(alignment: .topLeading) {
            Image("HomeHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 236)
                .clipped()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [.black.opacity(0.12), .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3 1 0 5")
                    Text("PLAY BEYOND LIMITS")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("SIMPLE")
                    Text("SAFE")
                    Text("STABLE")
                    Capsule()
                        .fill(.white.opacity(0.65))
                        .frame(width: 24, height: 1)
                        .padding(.top, 2)
                }
            }
            .font(.system(size: 7, weight: .semibold, design: .monospaced))
            .tracking(3)
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 14)
            .padding(.top, 22)

            Text("三\n一\n〇\n五")
                .font(.system(size: 21, weight: .black, design: .serif))
                .foregroundStyle(.white.opacity(0.48))
                .lineSpacing(-3)
                .padding(.leading, 19)
                .padding(.top, 86)
                .accessibilityHidden(true)
        }
        .frame(height: 236)
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }

    @ViewBuilder
    private var packageCards: some View {
        if feed.isEmpty {
            marketplaceEmpty(
                systemImage: store.sources.isEmpty
                    ? "shippingbox.and.arrow.backward"
                    : "shippingbox",
                titleKey: store.sources.isEmpty
                    ? "repository.no_sources_title"
                    : "repository.no_packages_title",
                messageKey: store.sources.isEmpty
                    ? "repository.home_no_sources_message"
                    : "repository.no_packages_message"
            )
        } else {
            VStack(spacing: 10) {
                ForEach(Array(feed.prefix(2))) { record in
                    NavigationLink(value: record) {
                        packageCard(record)
                    }
                    .buttonStyle(.plain)
                }

                if feed.count > 2 {
                    DisclosureGroup {
                        VStack(spacing: 10) {
                            ForEach(Array(feed.dropFirst(2))) { record in
                                NavigationLink(value: record) {
                                    packageCard(record)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        Text(language.text("repository.more_patches"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .tint(.white.opacity(0.55))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private func packageCard(_ record: RepositoryPackageRecord) -> some View {
        HStack(spacing: 13) {
            RepositoryPackageIcon(package: record.package, size: 54)

            VStack(alignment: .leading, spacing: 5) {
                Text(record.package.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(record.package.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.045), in: Circle())
                .accessibilityHidden(true)
        }
        .padding(10)
        .background(dashboardCardBackground)
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var deviceSummary: some View {
        HStack(spacing: 0) {
            metric(
                icon: "iphone.gen3",
                title: "Device",
                value: deviceDisplayName
            )

            metricDivider

            metric(
                icon: "apple.logo",
                title: "iOS Version",
                value: AppInfo.osVersion
            )

            metricDivider

            metric(
                icon: "checkmark.shield",
                title: "Status",
                value: language.text(
                    appState.isSupported ? "settings.supported" : "settings.unsupported"
                )
            )
        }
        .padding(.vertical, 18)
        .background(dashboardCardBackground)
    }

    private var deviceDisplayName: String {
        let identifier = AppInfo.displayMachineName
        if identifier.hasPrefix("iPhone") { return "iPhone" }
        if identifier.hasPrefix("iPad") { return "iPad" }
        return identifier
    }

    private func metric(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
                .frame(height: 25)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    title == "Status"
                        ? (appState.isSupported ? Color.green : Color.red)
                        : Color.white
                )
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.17))
            .frame(width: 1, height: 67)
            .accessibilityHidden(true)
    }

    private var resourceLinks: some View {
        VStack(spacing: 10) {
            dashboardLink(
                title: "Support",
                subtitle: "Get help if you have any issue",
                systemImage: "headphones",
                destination: "https://github.com/YangJiiii/3105/issues"
            )
            dashboardLink(
                title: "Telegram Channel",
                subtitle: "Get latest updates and announcements",
                systemImage: "paperplane.fill",
                destination: "https://t.me/ioscrackvn"
            )
        }
    }

    private func dashboardLink(
        title: String,
        subtitle: String,
        systemImage: String,
        destination: String
    ) -> some View {
        Link(destination: URL(string: destination)!) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.black, in: Circle())
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(dashboardCardBackground)
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private var footer: some View {
        VStack(spacing: 7) {
            Spacer(minLength: 96)
            Text("3 1 0 5")
            Text("PLAY BEYOND LIMITS  •  \(AppUpdateChecker.currentVersion)")
            Capsule()
                .fill(.white)
                .frame(width: 28, height: 2)
                .padding(.top, 3)
        }
        .font(.system(size: 7, weight: .semibold, design: .monospaced))
        .tracking(3)
        .foregroundStyle(.white.opacity(0.72))
        .frame(maxWidth: .infinity)
    }

    private var dashboardCardBackground: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Color.white.opacity(0.035))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.075), lineWidth: 0.7)
            }
    }

    private func marketplaceEmpty(
        systemImage: String,
        titleKey: String,
        messageKey: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white)
            Text(language.text(titleKey))
                .font(.headline)
                .foregroundStyle(.white)
            Text(language.text(messageKey))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
        .background(dashboardCardBackground)
    }

    private func rebuildFeed() {
        feed = PackageRepositoryFeedPolicy.home(store.packages)
    }
}

struct RepositoryNewView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var packages: [RepositoryPackageRecord] = []
    @State private var showSimulatedPackageDetail = false
    @State private var simulatedPackageDetailGate = OneShotPresentationGate()

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if packages.isEmpty {
                    Section {
                        emptyState
                    }
                } else {
                    Section {
                        ForEach(packages) { record in
                            NavigationLink(value: record) {
                                RepositoryNewPackageRow(record: record)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(language.text("tab.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
            .navigationDestination(isPresented: $showSimulatedPackageDetail) {
                if let record = packages.first {
                    RepositoryPackageDetailView(record: record)
                }
            }
            .refreshable {
                await store.refreshAllAndWait()
                rebuildPackages()
            }
            .onAppear {
                store.refreshAllIfNeeded()
                rebuildPackages()
                openSimulatedPackageDetailIfNeeded()
            }
            .onChange(of: store.packages) { _ in
                rebuildPackages()
                openSimulatedPackageDetailIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if store.isRefreshing && !store.sources.isEmpty {
            HStack(spacing: 10) {
                ProgressView()
                Text(language.text("repository.refreshing"))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        } else {
            VStack(spacing: 12) {
                Image(systemName: store.sources.isEmpty ? "shippingbox" : "clock")
                    .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                    .foregroundStyle(AppTheme.accent)
                Text(language.text(
                    store.sources.isEmpty
                        ? "repository.no_sources_title"
                        : "repository.new_empty_title"
                ))
                .font(.headline)
                Text(language.text(
                    store.sources.isEmpty
                        ? "repository.no_sources_message"
                        : "repository.new_empty_message"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        }
    }

    private func rebuildPackages() {
        packages = PackageRepositoryFeedPolicy.newest(store.packages)
    }

    private func openSimulatedPackageDetailIfNeeded() {
#if targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains(
            "--simulate-package-detail"
        ), !packages.isEmpty, simulatedPackageDetailGate.claim() else {
            return
        }
        DispatchQueue.main.async {
            showSimulatedPackageDetail = true
        }
#endif
    }
}

struct RepositorySearchView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var store: PackageRepositoryStore
    @State private var searchText = ""

    let onOpenSettings: () -> Void
    let onOpenLogs: () -> Void

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [RepositoryPackageRecord] {
        guard !query.isEmpty else { return [] }
        return store.packages.filter { record in
            let package = record.package
            return package.name.localizedCaseInsensitiveContains(query)
                || package.author.localizedCaseInsensitiveContains(query)
                || package.summary.localizedCaseInsensitiveContains(query)
                || package.identifier.localizedCaseInsensitiveContains(query)
                || record.sourceName.localizedCaseInsensitiveContains(query)
                || (package.category?.localizedCaseInsensitiveContains(query) ?? false)
                || package.tags.contains {
                    $0.localizedCaseInsensitiveContains(query)
                }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AppSearchField(
                    text: $searchText,
                    prompt: language.text("repository.search_prompt"),
                    clearLabel: language.text("common.clear")
                )
                Divider()
                List {
                    if query.isEmpty {
                        searchPrompt
                            .listRowSeparator(.hidden)
                    } else if results.isEmpty {
                        searchEmpty
                            .listRowSeparator(.hidden)
                    } else {
                        Section(language.text(
                            "repository.search_results",
                            Int64(results.count)
                        )) {
                            ForEach(results) { record in
                                NavigationLink(value: record) {
                                    RepositoryPackageRow(record: record)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    await store.refreshAllAndWait()
                }
            }
            .navigationTitle(language.text("repository.search"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppUtilityToolbar(
                    language: language,
                    onOpenSettings: onOpenSettings,
                    onOpenLogs: onOpenLogs
                )
            }
            .navigationDestination(for: RepositoryPackageRecord.self) { record in
                RepositoryPackageDetailView(record: record)
            }
            .onAppear {
                store.refreshAllIfNeeded()
            }
        }
    }

    private var searchPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(AppTheme.accent)
            Text(language.text("repository.search_title"))
                .font(.headline)
            Text(language.text("repository.search_message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }

    private var searchEmpty: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: AppTheme.emptyIconSize, weight: .light))
                .foregroundStyle(.secondary)
            Text(language.text("repository.search_empty"))
                .font(.headline)
            Text(language.text("repository.search_empty_message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
    }
}

private struct RepositoryFeaturedCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var imageLoader = RepositoryImageLoader()
    let record: RepositoryPackageRecord
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            artwork

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.28),
                    .init(color: .black.opacity(0.16), location: 0.56),
                    .init(color: .black.opacity(0.78), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.package.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)

                Text(record.package.author)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .shadow(color: .black.opacity(0.42), radius: 1, y: 1)
        }
        .frame(width: width, height: height, alignment: .bottomLeading)
        .background(Color(uiColor: .secondarySystemFill))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    Color(uiColor: .separator).opacity(0.24),
                    lineWidth: 0.5
                )
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .task(id: record.package.iconURL) {
            guard let iconURL = record.package.iconURL else { return }
            await imageLoader.load(url: iconURL, maximumPixelSize: 640)
        }
    }

    private var artwork: some View {
        Rectangle()
            .fill(Color(uiColor: .secondarySystemFill))
            .overlay {
                if let image = imageLoader.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if imageLoader.didFail {
                    placeholder
                } else if record.package.iconURL == nil {
                    placeholder
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: record.package.kind == .wallpaper
            ? "photo.fill"
            : "shippingbox.fill")
            .font(.system(size: 30, weight: .medium))
            .foregroundStyle(.white.opacity(0.82))
    }
}

private struct RepositoryCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct RepositoryNewPackageRow: View {
    @Environment(\.appLanguage) private var language
    let record: RepositoryPackageRecord

    var body: some View {
        HStack(spacing: 12) {
            RepositoryPackageIcon(package: record.package, size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.package.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(language.text(
                    "repository.home_package_meta",
                    record.package.author,
                    record.sourceName
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let publishedAt = record.package.publishedAt {
                Text(
                    publishedAt,
                    format: .dateTime.day().month(.abbreviated)
                )
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
    }
}
