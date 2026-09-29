import SwiftUI

/// Full-featured cursor theme store with browsing, search, and purchases.
struct StoreView: View {
    @EnvironmentObject var engine: CursorEngine
    @EnvironmentObject var store: StoreManager

    @State private var selectedTab: StoreTab = .featured
    @State private var searchText = ""
    @State private var selectedTheme: StoreTheme?
    @State private var showSubscriptionSheet = false

    enum StoreTab: String, CaseIterable {
        case featured = "Featured"
        case free = "Free"
        case premium = "Premium"
        case animated = "Animated"
        case installed = "Installed"
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailContent
        }
        .searchable(text: $searchText, prompt: "Search cursor themes...")
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionSheet()
        }
        .sheet(item: $selectedTheme) { theme in
            ThemeDetailSheet(theme: theme)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(StoreTab.allCases, id: \.self, selection: $selectedTab) { tab in
            Label(tab.rawValue, systemImage: iconForTab(tab))
                .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
    }

    private func iconForTab(_ tab: StoreTab) -> String {
        switch tab {
        case .featured: return "star.fill"
        case .free: return "gift.fill"
        case .premium: return "crown.fill"
        case .animated: return "sparkles"
        case .installed: return "square.and.arrow.down.fill"
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if !searchText.isEmpty {
            searchResults
        } else {
            switch selectedTab {
            case .featured: featuredView
            case .free: themeGrid(themes: store.themes(for: "free"))
            case .premium: themeGrid(themes: store.themes(for: "premium"))
            case .animated: themeGrid(themes: store.themes(for: "animated"))
            case .installed: installedView
            }
        }
    }

    // MARK: - Featured

    private var featuredView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero banner
                heroBanner

                // Curated collections
                sectionHeader("Popular Themes", subtitle: "Most downloaded this month")
                horizontalScroll(store.availableThemes.sorted { $0.downloadCount > $1.downloadCount })

                sectionHeader("New Arrivals", subtitle: "Fresh designs")
                horizontalScroll(store.availableThemes.sorted { $0.createdAt > $1.createdAt })

                sectionHeader("Staff Picks", subtitle: "Our favorites")
                horizontalScroll(store.availableThemes.shuffled())
            }
            .padding(24)
        }
    }

    private var heroBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)

            VStack(spacing: 8) {
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)

                Text("Unlock Premium Cursors")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Subscribe to access 500+ exclusive themes")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Button("View Plans") {
                    showSubscriptionSheet = true
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .padding(.top, 4)
            }
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func horizontalScroll(_ themes: [StoreTheme]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(themes) { theme in
                    ThemeCard(theme: theme)
                        .onTapGesture {
                            selectedTheme = theme
                        }
                }
            }
        }
    }

    // MARK: - Grid

    private func themeGrid(themes: [StoreTheme]) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
            ], spacing: 16) {
                ForEach(themes) { theme in
                    ThemeCard(theme: theme)
                        .onTapGesture {
                            selectedTheme = theme
                        }
                }
            }
            .padding(24)
        }
    }

    // MARK: - Search

    private var searchResults: some View {
        let results = store.searchThemes(query: searchText)
        return ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
            ], spacing: 16) {
                ForEach(results) { theme in
                    ThemeCard(theme: theme)
                        .onTapGesture {
                            selectedTheme = theme
                        }
                }
            }
            .padding(24)
        }
    }

    // MARK: - Installed

    private var installedView: some View {
        ScrollView {
            if store.installedThemes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No themes installed yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Browse the store to find your perfect cursor")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
                ], spacing: 16) {
                    ForEach(store.installedThemes) { theme in
                        InstalledThemeCard(theme: theme)
                    }
                }
                .padding(24)
            }
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: StoreTheme
    @EnvironmentObject var store: StoreManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview image area
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: theme.isAnimated ? "sparkles" : "cursorarrow.motionlines")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    )

                // Price badge
                VStack {
                    HStack {
                        Spacer()
                        priceBadge
                    }
                    Spacer()
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(theme.author)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(String(format: "%.1f", theme.rating), systemImage: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)

                Text("•")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 8))

                Text(formatCount(theme.downloadCount))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Spacer()

                if store.canAccess(theme) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var priceBadge: some View {
        switch theme.price.type {
        case .free:
            Text("Free")
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.green.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        case .oneTime:
            Text(String(format: "$%.2f", theme.price.amount))
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        case .premium, .premiumPlus:
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.purple.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// MARK: - Installed Theme Card

struct InstalledThemeCard: View {
    let theme: InstalledTheme
    @EnvironmentObject var store: StoreManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(height: 140)
                    .overlay(
                        Image(systemName: theme.isActive ? "cursorarrow.click.2" : "cursorarrow.motionlines")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.isActive ? .blue : .secondary)
                    )

                if theme.isActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(8)
                }
            }

            Text(theme.name)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)

            HStack {
                Text("\(theme.cursorCount) cursors")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()

                Button("Apply") {
                    store.activateTheme(theme.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(theme.isActive)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Theme Detail Sheet

struct ThemeDetailSheet: View {
    let theme: StoreTheme
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var engine: CursorEngine
    @Environment(\.dismiss) var dismiss

    @State private var isInstalling = false
    @State private var isPurchasing = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.title2.bold())
                    Text("by \(theme.author)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Preview
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 240)
                        .overlay(
                            VStack {
                                Image(systemName: theme.isAnimated ? "sparkles" : "cursorarrow.motionlines")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        )

                    // Description
                    Text(theme.description)
                        .font(.body)

                    // Tags
                    FlowLayout(spacing: 6) {
                        ForEach(theme.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    // Stats
                    HStack(spacing: 24) {
                        statItem("\(theme.cursorCount)", "Cursors")
                        statItem(String(format: "%.1f", theme.rating), "Rating")
                        statItem(formatCount(theme.downloadCount), "Downloads")
                        statItem(formatBytes(theme.fileSize), "Size")
                    }

                    Divider()

                    // Action buttons
                    actionButtons
                }
                .padding(20)
            }
        }
        .frame(width: 500, height: 600)
    }

    private func statItem(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if store.canAccess(theme) {
            Button {
                Task {
                    isInstalling = true
                    let success = await store.downloadAndInstall(theme)
                    isInstalling = false
                    if success {
                        store.activateTheme(theme.id)
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    if isInstalling {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(isInstalling ? "Installing..." : "Install & Apply")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isInstalling)
        } else {
            switch theme.price.type {
            case .oneTime:
                Button {
                    Task {
                        isPurchasing = true
                        let success = await store.purchaseTheme(theme)
                        isPurchasing = false
                        if success {
                            let installed = await store.downloadAndInstall(theme)
                            if installed { store.activateTheme(theme.id) }
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "cart.fill")
                        }
                        Text(isPurchasing ? "Processing..." : "Buy for $\(String(format: "%.2f", theme.price.amount))")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPurchasing)

            case .premium, .premiumPlus:
                VStack(spacing: 8) {
                    Text("Requires \(theme.price.type == .premium ? "Basic" : "Pro") subscription")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Subscribe to Access") {
                        // showSubscriptionSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

            default:
                EmptyView()
            }
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 { return String(format: "%.1fk", Double(count) / 1000.0) }
        return "\(count)"
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Subscription Sheet

struct SubscriptionSheet: View {
    @EnvironmentObject var store: StoreManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Choose Your Plan")
                .font(.title.bold())

            Text("Access premium cursor themes and exclusive content")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                planCard(
                    tier: .basic,
                    title: "Basic",
                    price: "$2.99/mo",
                    features: [
                        "Access all basic themes",
                        "50+ curated packs",
                        "Regular updates",
                        "Community support",
                    ]
                )

                planCard(
                    tier: .pro,
                    title: "Pro",
                    price: "$5.99/mo",
                    features: [
                        "Everything in Basic",
                        "All Pro exclusive packs",
                        "Early access to new themes",
                        "Custom cursor builder",
                        "Priority support",
                    ],
                    isPopular: true
                )
            }

            Button("Maybe Later") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(width: 600)
    }

    private func planCard(tier: StoreTheme.Pricing.SubscriptionTier, title: String, price: String, features: [String], isPopular: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isPopular {
                Text("MOST POPULAR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue)
                    .clipShape(Capsule())
            }

            Text(title)
                .font(.title3.bold())
            Text(price)
                .font(.title2.bold())
                .foregroundStyle(.blue)

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                    Text(feature)
                        .font(.system(size: 12))
                }
            }

            Spacer()

            Button {
                Task {
                    _ = await store.subscribe(tier: tier)
                    dismiss()
                }
            } label: {
                Text("Subscribe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 300)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPopular ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, proposal: proposal)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(subviews: Subviews, proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
