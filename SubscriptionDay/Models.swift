import Foundation
import Observation

enum SubscriptionCategory: String, CaseIterable, Identifiable, Codable {
    case entertainment = "Entertainment"
    case productivity = "Productivity"
    case cloud = "Cloud Storage"
    case health = "Health & Fitness"
    case education = "Education"
    case shopping = "Shopping"
    case social = "Social"
    case other = "Other"

    var id: String { rawValue }
}

enum PaymentSchedule: String, CaseIterable, Identifiable, Codable {
    case monthly = "Monthly"
    case yearly = "Yearly"
    case weekly = "Weekly"
    case oneTime = "One-time"
    case trial = "Trial"

    var id: String { rawValue }
}

struct ServiceBrand: Identifiable, Hashable {
    let id: String
    let name: String
    let assetName: String?
    let fallbackSymbol: String
    let fallbackColor: String
    let category: SubscriptionCategory
    let isPopular: Bool

    init(
        _ name: String,
        asset: String? = nil,
        symbol: String = "sparkles",
        color: String = "6C6C70",
        category: SubscriptionCategory = .other,
        popular: Bool = false
    ) {
        self.id = name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.assetName = asset
        self.fallbackSymbol = symbol
        self.fallbackColor = color
        self.category = category
        self.isPopular = popular
    }
}

struct SubscriptionRecord: Identifiable, Hashable {
    let id: UUID
    var service: ServiceBrand
    var name: String
    var amount: Double
    var schedule: PaymentSchedule
    var startDate: Date
    var endDate: Date?
    var category: SubscriptionCategory
    var paymentMethod: String
    var listName: String
    var notifications: String

    init(
        id: UUID = UUID(),
        service: ServiceBrand,
        name: String,
        amount: Double,
        schedule: PaymentSchedule,
        startDate: Date,
        endDate: Date? = nil,
        category: SubscriptionCategory,
        paymentMethod: String = "None",
        listName: String = "Personal",
        notifications: String = "Default"
    ) {
        self.id = id
        self.service = service
        self.name = name
        self.amount = amount
        self.schedule = schedule
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.listName = listName
        self.notifications = notifications
    }

    var monthlyAmount: Double {
        switch schedule {
        case .monthly: amount
        case .yearly: amount / 12
        case .weekly: amount * 52 / 12
        case .oneTime, .trial: amount
        }
    }
}

enum ServiceCatalog {
    static let customTemplate = ServiceBrand(
        "Custom Subscription",
        symbol: "plus",
        color: "5F78F2",
        category: .other
    )

    static let services: [ServiceBrand] = [
        ServiceBrand("Youtube", asset: "circle_youtube", symbol: "play.fill", color: "E53935", category: .entertainment, popular: true),
        ServiceBrand("Spotify", asset: "circle_spotify", symbol: "waveform", color: "26D965", category: .entertainment, popular: true),
        ServiceBrand("Netflix", asset: "logo_netflix", symbol: "n.square.fill", color: "181818", category: .entertainment, popular: true),
        ServiceBrand("Linkedin", asset: "circle_linkedin", symbol: "person.2.fill", color: "1672B8", category: .social, popular: true),
        ServiceBrand("Cursor", asset: "logo_cursor", symbol: "cursorarrow", color: "181818", category: .productivity, popular: true),
        ServiceBrand("Claude", asset: "logo_claude", symbol: "sun.max.fill", color: "D98D72", category: .productivity, popular: true),
        ServiceBrand("ChatGPT", asset: "logo_chatgpt", symbol: "hexagon", color: "F4F4F4", category: .productivity, popular: true),
        ServiceBrand("Apple iCloud", asset: "logo_icloud", symbol: "icloud.fill", color: "F4F4F4", category: .cloud, popular: true),
        ServiceBrand("Apple One", asset: "logo_apple_one", symbol: "apple.logo", color: "F4F4F4", category: .other, popular: true),
        ServiceBrand("Apple Music", asset: "logo_apple_music", symbol: "music.note", color: "F24D69", category: .entertainment, popular: true),
        ServiceBrand("Amazon Prime Video", asset: "logo_prime_video", symbol: "play.rectangle.fill", color: "1477A8", category: .entertainment, popular: true),
        ServiceBrand("1Password", asset: "logo_1password", symbol: "key.fill", color: "31427A", category: .productivity, popular: true),

        ServiceBrand("Adobe Cloud", asset: "logo_adobe_cloud", symbol: "scribble.variable", color: "F54D8C", category: .productivity),
        ServiceBrand("Amazon Music", asset: "logo_amazon_music", symbol: "music.note", color: "24C4D0", category: .entertainment),
        ServiceBrand("Amazon Prime", asset: "circle_amazon", symbol: "shippingbox.fill", color: "146EB4", category: .shopping),
        ServiceBrand("Apple Arcade", asset: "logo_apple_arcade", symbol: "gamecontroller.fill", color: "FF5A67", category: .entertainment),
        ServiceBrand("Apple Care+", asset: "logo_apple_care", symbol: "apple.logo", color: "F4F4F4", category: .other),
        ServiceBrand("Apple Developer", asset: "logo_apple_developer", symbol: "apple.logo", color: "D9E9FF", category: .productivity),
        ServiceBrand("Apple Fitness+", asset: "logo_apple_fitness", symbol: "figure.run", color: "A8F438", category: .health),
        ServiceBrand("Apple TV", asset: "logo_apple_tv", symbol: "appletv.fill", color: "151515", category: .entertainment),
        ServiceBrand("Audible", asset: "logo_audible", symbol: "wave.3.forward", color: "F59B2F", category: .education),
        ServiceBrand("Bumble", asset: "logo_bumble", symbol: "hexagon.fill", color: "F4C132", category: .social),
        ServiceBrand("Calm", asset: "logo_calm", symbol: "water.waves", color: "687EE1", category: .health),
        ServiceBrand("Canva", asset: "logo_canva", symbol: "paintpalette.fill", color: "23C4DE", category: .productivity),
        ServiceBrand("CleanShot", asset: "logo_cleanshot", symbol: "photo", color: "F4F4F4", category: .productivity),
        ServiceBrand("Crunchyroll", asset: "logo_crunchyroll", symbol: "play.circle.fill", color: "F57E37", category: .entertainment),
        ServiceBrand("Daily Burn", asset: "logo_daily_burn", symbol: "flame.fill", color: "F4F4F4", category: .health),
        ServiceBrand("Disney+", asset: "logo_disney", symbol: "sparkles.tv.fill", color: "293171", category: .entertainment),
        ServiceBrand("DoorDash", asset: "logo_doordash", symbol: "takeoutbag.and.cup.and.straw.fill", color: "F4F4F4", category: .shopping),
        ServiceBrand("Dropbox", asset: "circle_dropbox", symbol: "shippingbox.fill", color: "1768D8", category: .cloud),
        ServiceBrand("Duolingo", asset: "circle_duolingo", symbol: "bird.fill", color: "75D52A", category: .education),
        ServiceBrand("EA Play", asset: "circle_ea_play", symbol: "gamecontroller.fill", color: "F75F63", category: .entertainment),
        ServiceBrand("Etsy Plus", asset: "circle_etsy", symbol: "cart.fill", color: "EE6D2D", category: .shopping),
        ServiceBrand("Figma", asset: "logo_figma", symbol: "circle.hexagongrid.fill", color: "F4F4F4", category: .productivity),
        ServiceBrand("Framer", asset: "logo_framer", symbol: "f.square.fill", color: "2585E9", category: .productivity),
        ServiceBrand("Fubotv", asset: "logo_fubo", symbol: "tv.fill", color: "F4F4F4", category: .entertainment),
        ServiceBrand("Gemini", asset: "logo_gemini", symbol: "sparkle", color: "F4F4F4", category: .productivity),
        ServiceBrand("Google Drive", asset: "logo_google_drive", symbol: "triangle.fill", color: "F4F4F4", category: .cloud),
        ServiceBrand("Google One", asset: "logo_google_one", symbol: "g.circle.fill", color: "F4F4F4", category: .cloud),
        ServiceBrand("Google Play", asset: "circle_google_play", symbol: "play.fill", color: "5F6368", category: .entertainment),
        ServiceBrand("Grammarly", asset: "logo_grammarly", symbol: "textformat", color: "55BEA8", category: .productivity),
        ServiceBrand("HBO Max", asset: "logo_hbo", symbol: "tv.fill", color: "6930C9", category: .entertainment),
        ServiceBrand("Headspace", asset: "logo_headspace", symbol: "face.smiling", color: "F98B1D", category: .health),
        ServiceBrand("Hinge", asset: "logo_hinge", symbol: "h.square.fill", color: "F4F4F4", category: .social),
        ServiceBrand("Hulu", asset: "logo_hulu", symbol: "h.square.fill", color: "37E18B", category: .entertainment),
        ServiceBrand("Lifecell", asset: "logo_lifecell", symbol: "point.3.connected.trianglepath.dotted", color: "F6C12A", category: .other),
        ServiceBrand("Lyft Pink", asset: "logo_lyft", symbol: "car.fill", color: "ED31BA", category: .other),
        ServiceBrand("Microsoft 365", asset: "logo_microsoft365", symbol: "square.stack.3d.up.fill", color: "F4F4F4", category: .productivity),
        ServiceBrand("Midjourney", asset: "logo_midjourney", symbol: "sailboat.fill", color: "F4F4F4", category: .productivity),
        ServiceBrand("Nintendo Online", asset: "circle_nintendo", symbol: "gamecontroller.fill", color: "E5313C", category: .entertainment),
        ServiceBrand("Bitbucket", asset: "circle_bitbucket", symbol: "shippingbox.fill", color: "0052CC", category: .productivity),
        ServiceBrand("Discord Nitro", asset: "circle_discord", symbol: "bubble.left.and.bubble.right.fill", color: "7289DA", category: .social),
        ServiceBrand("Flickr Pro", asset: "circle_flickr", symbol: "photo.on.rectangle.angled", color: "0063DC", category: .cloud),
        ServiceBrand("GitHub", asset: "circle_github", symbol: "chevron.left.forwardslash.chevron.right", color: "24292D", category: .productivity),
        ServiceBrand("GitLab", asset: "circle_gitlab", symbol: "chevron.left.forwardslash.chevron.right", color: "FC6D26", category: .productivity),
        ServiceBrand("Ko-fi Gold", asset: "circle_kofi", symbol: "cup.and.saucer.fill", color: "29ABE0", category: .productivity),
        ServiceBrand("Last.fm Pro", asset: "circle_lastfm", symbol: "music.note.list", color: "D51007", category: .entertainment),
        ServiceBrand("Medium Membership", asset: "circle_medium", symbol: "text.book.closed.fill", color: "00AB6C", category: .education),
        ServiceBrand("Meetup", asset: "circle_meetup", symbol: "person.3.fill", color: "F64060", category: .social),
        ServiceBrand("Minecraft Realms", asset: "circle_minecraft", symbol: "cube.fill", color: "6B4F3A", category: .entertainment),
        ServiceBrand("Nexus Mods Premium", asset: "circle_nexus_mods", symbol: "wrench.and.screwdriver.fill", color: "2D6E9E", category: .entertainment),
        ServiceBrand("Notion", symbol: "square.text.square.fill", color: "F4F4F4", category: .productivity),
        ServiceBrand("Patreon", asset: "circle_patreon", symbol: "p.circle.fill", color: "F35B4C", category: .other),
        ServiceBrand("PlayStation Plus", asset: "circle_playstation", symbol: "gamecontroller.fill", color: "2364B8", category: .entertainment),
        ServiceBrand("Reddit Premium", asset: "circle_reddit", symbol: "bubble.left.and.bubble.right.fill", color: "FF4500", category: .social),
        ServiceBrand("RuneScape Membership", asset: "circle_runescape", symbol: "gamecontroller.fill", color: "2C5877", category: .entertainment),
        ServiceBrand("Slack", asset: "circle_slack", symbol: "number", color: "36C5F0", category: .productivity),
        ServiceBrand("Snapchat+", asset: "circle_snapchat", symbol: "message.fill", color: "FFFC00", category: .social),
        ServiceBrand("SoundCloud Go+", asset: "circle_soundcloud", symbol: "waveform", color: "FF5500", category: .entertainment),
        ServiceBrand("Substack", asset: "circle_substack", symbol: "newspaper.fill", color: "FF6719", category: .education),
        ServiceBrand("Telegram Premium", asset: "circle_telegram", symbol: "paperplane.fill", color: "229ED9", category: .social),
        ServiceBrand("Trello", asset: "circle_trello", symbol: "rectangle.split.2x1.fill", color: "0079BF", category: .productivity),
        ServiceBrand("Twitch", asset: "circle_twitch", symbol: "play.rectangle.fill", color: "9146FF", category: .entertainment),
        ServiceBrand("Ubisoft+", asset: "circle_ubisoft", symbol: "gamecontroller.fill", color: "FF0A8D", category: .entertainment),
        ServiceBrand("Ultimate Guitar Pro", asset: "circle_ultimate_guitar", symbol: "guitars.fill", color: "FFCC00", category: .education),
        ServiceBrand("Vimeo", asset: "circle_vimeo", symbol: "video.fill", color: "1AB7EA", category: .productivity),
        ServiceBrand("VSCO", asset: "circle_vsco", symbol: "camera.aperture", color: "F4F4F4", category: .productivity),
        ServiceBrand("X Premium", asset: "circle_x", symbol: "bubble.left.fill", color: "181818", category: .social),
        ServiceBrand("Xbox Game Pass", asset: "circle_xbox", symbol: "xbox.logo", color: "3AA638", category: .entertainment),
        ServiceBrand("Zoom", symbol: "video.fill", color: "2D78F4", category: .productivity)
    ]

    static var popular: [ServiceBrand] { services.filter(\.isPopular) }
    static var all: [ServiceBrand] { services.filter { !$0.isPopular }.sorted { $0.name < $1.name } }

    static func contains(_ service: ServiceBrand) -> Bool {
        services.contains { $0.id == service.id }
    }

    static func service(named name: String, category: SubscriptionCategory = .other) -> ServiceBrand {
        services.first { $0.name == name } ?? ServiceBrand(name, category: category)
    }
}

@MainActor
@Observable
final class AppModel {
    var subscriptions: [SubscriptionRecord] = [] { didSet { persist() } }
    var selectedMonth: Date = AppModel.makeDate(year: 2026, month: 8, day: 1) { didSet { persist() } }
    var selectedDay = AppModel.calendar.component(.day, from: Date())
    var selectedDate = Date()
    var showingSettings = false
    var showingCatalog = false
    var showingSearch = false
    var showingAnalytics = false
    var showingDaySubscriptions = false
    var showingSubscriptionDetail = false
    var draftStartDate: Date?
    var selectedSubscriptionID: UUID?
    var searchText = ""

    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var isRestoring = true

    private static let storageKey = "subscription-day.records.v1"
    private static let monthKey = "subscription-day.selected-month.v1"

    let freeLimit = 5

    init() {
        restore()
        isRestoring = false
    }

    var remainingSlots: Int { max(0, freeLimit - subscriptions.count) }

    var daySubscriptionsSheetHeight: CGFloat {
        let count = subscriptions(on: selectedDate).count
        return max(370, min(650, 294 + CGFloat(count) * 76))
    }

    var displayedMonthTotal: Double {
        total(in: selectedMonth)
    }

    var visibleSubscriptions: [SubscriptionRecord] {
        subscriptions
    }

    var filteredSubscriptions: [SubscriptionRecord] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return subscriptions }
        let query = searchText.lowercased()
        return subscriptions.filter {
            $0.name.lowercased().contains(query)
                || $0.schedule.rawValue.lowercased().contains(query)
                || $0.category.rawValue.lowercased().contains(query)
        }
    }

    func add(_ subscription: SubscriptionRecord) {
        subscriptions.append(subscription)
        selectedMonth = Self.monthStart(for: subscription.startDate)
        draftStartDate = nil
    }

    func update(_ subscription: SubscriptionRecord) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }
        subscriptions[index] = subscription
        selectedMonth = Self.monthStart(for: subscription.startDate)
    }

    func deleteSubscription(id: UUID) {
        subscriptions.removeAll { $0.id == id }
        if selectedSubscriptionID == id { selectedSubscriptionID = nil }
    }

    func subscription(id: UUID) -> SubscriptionRecord? {
        subscriptions.first { $0.id == id }
    }

    func presentAnalytics() {
        showingAnalytics = true
    }

    func select(day: Int, in month: Date) {
        var components = Self.calendar.dateComponents([.year, .month], from: month)
        components.day = day
        guard let date = Self.calendar.date(from: components) else { return }
        selectedMonth = Self.monthStart(for: date)
        selectedDay = day
        selectedDate = date
        if subscriptions(on: date).isEmpty {
            draftStartDate = date
            showingCatalog = true
        } else {
            showingDaySubscriptions = true
        }
    }

    func total(in month: Date, category: SubscriptionCategory? = nil) -> Double {
        visibleSubscriptions
            .filter { category == nil || $0.category == category }
            .reduce(0) { $0 + chargeAmount(for: $1, in: month) }
    }

    func subscriptions(on date: Date) -> [SubscriptionRecord] {
        visibleSubscriptions.filter { isDue($0, on: date) }
    }

    func nextPayment(from date: Date = Date()) -> (date: Date, amount: Double)? {
        let start = Self.calendar.startOfDay(for: date)
        for offset in 0...366 {
            guard let candidate = Self.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let due = subscriptions(on: candidate)
            if !due.isEmpty {
                return (candidate, due.reduce(0) { $0 + $1.amount })
            }
        }
        return nil
    }

    func activeSubscriptions(in year: Int, category: SubscriptionCategory? = nil) -> [SubscriptionRecord] {
        visibleSubscriptions.filter { subscription in
            guard category == nil || subscription.category == category else { return false }
            return months(in: year).contains { chargeAmount(for: subscription, in: $0) > 0 }
        }
    }

    func forecast(in year: Int, category: SubscriptionCategory? = nil) -> Double {
        months(in: year).reduce(0) { $0 + total(in: $1, category: category) }
    }

    func lifetimePaidTotal(asOf date: Date = Date()) -> Double {
        subscriptions.reduce(0) { total, subscription in
            total + lifetimePaidAmount(for: subscription, asOf: date)
        }
    }

    func lifetimePaidTotalsByService(asOf date: Date = Date()) -> [(service: ServiceBrand, amount: Double)] {
        Dictionary(grouping: subscriptions, by: \.service)
            .map { service, records in
                let amount = records.reduce(0) { total, subscription in
                    total + lifetimePaidAmount(for: subscription, asOf: date)
                }
                return (service: service, amount: amount)
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    func categoryForecasts(in year: Int) -> [(category: SubscriptionCategory, amount: Double)] {
        SubscriptionCategory.allCases
            .map { ($0, forecast(in: year, category: $0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    private func lifetimePaidAmount(for subscription: SubscriptionRecord, asOf date: Date) -> Double {
        let cutoff = Self.calendar.startOfDay(for: date)
        let start = Self.calendar.startOfDay(for: subscription.startDate)
        let end = min(
            cutoff,
            subscription.endDate.map { Self.calendar.startOfDay(for: $0) } ?? cutoff
        )
        guard start <= end else { return 0 }

        var month = Self.monthStart(for: start)
        let finalMonth = Self.monthStart(for: end)
        var paid = 0.0

        while month <= finalMonth {
            let completedCharges = datesDue(for: subscription, in: month)
                .filter { Self.calendar.startOfDay(for: $0) <= end }
            paid += Double(completedCharges.count) * subscription.amount

            guard let nextMonth = Self.calendar.date(byAdding: .month, value: 1, to: month) else {
                break
            }
            month = nextMonth
        }

        return paid
    }

    func serviceForecasts(
        in year: Int,
        category: SubscriptionCategory? = nil
    ) -> [(service: ServiceBrand, amount: Double)] {
        Dictionary(grouping: activeSubscriptions(in: year, category: category), by: \.service)
            .map { service, subscriptions -> (service: ServiceBrand, amount: Double) in
                let amount = months(in: year).reduce(0) { total, month in
                    total + subscriptions.reduce(0) { $0 + chargeAmount(for: $1, in: month) }
                }
                return (service, amount)
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    func months(in year: Int) -> [Date] {
        (1...12).map { Self.makeDate(year: year, month: $0, day: 1) }
    }

    private func chargeAmount(for subscription: SubscriptionRecord, in month: Date) -> Double {
        let monthDates = datesDue(for: subscription, in: month)
        return Double(monthDates.count) * subscription.amount
    }

    private func datesDue(for subscription: SubscriptionRecord, in month: Date) -> [Date] {
        let monthStart = Self.monthStart(for: month)
        guard let nextMonth = Self.calendar.date(byAdding: .month, value: 1, to: monthStart),
              let monthEnd = Self.calendar.date(byAdding: .day, value: -1, to: nextMonth),
              subscription.startDate <= monthEnd,
              subscription.endDate.map({ $0 >= monthStart }) ?? true else { return [] }

        switch subscription.schedule {
        case .monthly:
            guard Self.monthDistance(from: subscription.startDate, to: monthStart) >= 0 else { return [] }
            return dueDate(day: Self.calendar.component(.day, from: subscription.startDate), in: monthStart)
                .map { isWithinSubscription($0, subscription) ? [$0] : [] } ?? []
        case .yearly:
            let distance = Self.monthDistance(from: subscription.startDate, to: monthStart)
            guard distance >= 0, distance.isMultiple(of: 12) else { return [] }
            return dueDate(day: Self.calendar.component(.day, from: subscription.startDate), in: monthStart)
                .map { isWithinSubscription($0, subscription) ? [$0] : [] } ?? []
        case .weekly:
            var result: [Date] = []
            var date = subscription.startDate
            if date < monthStart {
                let elapsed = Self.calendar.dateComponents([.day], from: date, to: monthStart).day ?? 0
                date = Self.calendar.date(byAdding: .day, value: max(0, (elapsed / 7) * 7), to: date) ?? date
                while date < monthStart {
                    date = Self.calendar.date(byAdding: .day, value: 7, to: date) ?? nextMonth
                }
            }
            while date < nextMonth {
                if isWithinSubscription(date, subscription) { result.append(date) }
                date = Self.calendar.date(byAdding: .day, value: 7, to: date) ?? nextMonth
            }
            return result
        case .oneTime, .trial:
            return Self.calendar.isDate(subscription.startDate, equalTo: monthStart, toGranularity: .month)
                ? [subscription.startDate] : []
        }
    }

    private func dueDate(day: Int, in month: Date) -> Date? {
        let days = Self.calendar.range(of: .day, in: .month, for: month)?.count ?? 28
        var components = Self.calendar.dateComponents([.year, .month], from: month)
        components.day = min(day, days)
        return Self.calendar.date(from: components)
    }

    private func isWithinSubscription(_ date: Date, _ subscription: SubscriptionRecord) -> Bool {
        date >= Self.calendar.startOfDay(for: subscription.startDate)
            && (subscription.endDate.map { date <= Self.calendar.startOfDay(for: $0) } ?? true)
    }

    private func isDue(_ subscription: SubscriptionRecord, on date: Date) -> Bool {
        datesDue(for: subscription, in: date).contains { Self.calendar.isDate($0, inSameDayAs: date) }
    }

    private func persist() {
        guard !isRestoring else { return }
        let records = subscriptions.map(PersistedSubscription.init)
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Self.storageKey)
        }
        defaults.set(selectedMonth.timeIntervalSince1970, forKey: Self.monthKey)
    }

    private func restore() {
        if let data = defaults.data(forKey: Self.storageKey),
           let records = try? JSONDecoder().decode([PersistedSubscription].self, from: data) {
            subscriptions = records.map(\.record)
        }
        if defaults.object(forKey: Self.monthKey) != nil {
            selectedMonth = Self.monthStart(for: Date(timeIntervalSince1970: defaults.double(forKey: Self.monthKey)))
        }
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    static func monthStart(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private static func monthDistance(from startDate: Date, to month: Date) -> Int {
        calendar.dateComponents([.month], from: monthStart(for: startDate), to: monthStart(for: month)).month ?? -1
    }

    static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date ?? Date()
    }
}

private struct PersistedSubscription: Codable {
    let id: UUID
    let serviceName: String
    let name: String
    let amount: Double
    let schedule: PaymentSchedule
    let startDate: Date
    let endDate: Date?
    let category: SubscriptionCategory
    let paymentMethod: String
    let listName: String
    let notifications: String

    init(_ record: SubscriptionRecord) {
        id = record.id
        serviceName = record.service.name
        name = record.name
        amount = record.amount
        schedule = record.schedule
        startDate = record.startDate
        endDate = record.endDate
        category = record.category
        paymentMethod = record.paymentMethod
        listName = record.listName
        notifications = record.notifications
    }

    var record: SubscriptionRecord {
        SubscriptionRecord(
            id: id,
            service: ServiceCatalog.service(named: serviceName, category: category),
            name: name,
            amount: amount,
            schedule: schedule,
            startDate: startDate,
            endDate: endDate,
            category: category,
            paymentMethod: paymentMethod,
            listName: listName,
            notifications: notifications
        )
    }
}
