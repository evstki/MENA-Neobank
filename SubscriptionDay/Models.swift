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
    case mobile = "Mobile & Internet"
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
    let usesMonochromeLogo: Bool
    let usesWhiteLogoBackground: Bool
    let fillsLogoContainer: Bool
    let fallbackSymbol: String
    let fallbackColor: String
    let category: SubscriptionCategory
    let isPopular: Bool
    let usesCustomIcon: Bool

    init(
        _ name: String,
        asset: String? = nil,
        monochromeLogo: Bool = false,
        whiteLogoBackground: Bool = false,
        fillsLogoContainer: Bool = false,
        symbol: String = "sparkles",
        color: String = "6C6C70",
        category: SubscriptionCategory = .other,
        popular: Bool = false,
        customIcon: Bool = false
    ) {
        self.id = name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.assetName = asset
        self.usesMonochromeLogo = monochromeLogo
        self.usesWhiteLogoBackground = whiteLogoBackground
        self.fillsLogoContainer = fillsLogoContainer
        self.fallbackSymbol = symbol
        self.fallbackColor = color
        self.category = category
        self.isPopular = popular
        self.usesCustomIcon = customIcon
    }
}

struct SuggestedSubscriptionPrice: Hashable {
    let amount: Double
    let currency: AppCurrency
    let schedule: PaymentSchedule

    init(
        _ amount: Double,
        currency: AppCurrency = .usd,
        schedule: PaymentSchedule = .monthly
    ) {
        self.amount = amount
        self.currency = currency
        self.schedule = schedule
    }

    var formattedAmount: String {
        currency.formatted(amount, hidesCents: false)
    }
}

extension ServiceBrand {
    var suggestedPrice: SuggestedSubscriptionPrice? {
        ServiceCatalog.suggestedPrice(for: self)
    }
}

struct SubscriptionRecord: Identifiable, Hashable {
    let id: UUID
    var service: ServiceBrand
    var name: String
    var amount: Double
    var currency: AppCurrency
    var schedule: PaymentSchedule
    var startDate: Date
    var endDate: Date?
    var category: SubscriptionCategory
    var paymentMethod: String
    var cardName: String
    var notifications: String

    init(
        id: UUID = UUID(),
        service: ServiceBrand,
        name: String,
        amount: Double,
        currency: AppCurrency = .usd,
        schedule: PaymentSchedule,
        startDate: Date,
        endDate: Date? = nil,
        category: SubscriptionCategory,
        paymentMethod: String = "None",
        cardName: String = "",
        notifications: String = "Default"
    ) {
        self.id = id
        self.service = service
        self.name = name
        self.amount = amount
        self.currency = currency
        self.schedule = schedule
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.cardName = cardName
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

    func amount(convertedTo targetCurrency: AppCurrency) -> Double {
        currency.converted(amount, to: targetCurrency)
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
        ServiceBrand("YouTube Premium", asset: "circle_youtube", symbol: "play.fill", color: "E53935", category: .entertainment, popular: true),
        ServiceBrand("Spotify Premium", asset: "circle_spotify", symbol: "waveform", color: "26D965", category: .entertainment, popular: true),
        ServiceBrand("Netflix", asset: "logo_netflix", monochromeLogo: true, symbol: "n.square.fill", color: "E50914", category: .entertainment, popular: true),
        ServiceBrand("LinkedIn Premium", asset: "circle_linkedin", symbol: "person.2.fill", color: "1672B8", category: .social),
        ServiceBrand("Cursor", asset: "logo_cursor", monochromeLogo: true, symbol: "cursorarrow", color: "181818", category: .productivity),
        ServiceBrand("Claude", asset: "logo_claude", monochromeLogo: true, symbol: "sun.max.fill", color: "D97757", category: .productivity),
        ServiceBrand("ChatGPT", asset: "logo_chatgpt", monochromeLogo: true, symbol: "hexagon", color: "181818", category: .productivity, popular: true),
        ServiceBrand("iCloud+", asset: "logo_icloud", symbol: "icloud.fill", color: "F4F4F4", category: .cloud, popular: true),
        ServiceBrand("Apple One", asset: "logo_apple_one", monochromeLogo: true, symbol: "apple.logo", color: "181818", category: .other, popular: true),
        ServiceBrand("Apple Music", asset: "logo_apple_music", monochromeLogo: true, symbol: "music.note", color: "FA243C", category: .entertainment, popular: true),
        ServiceBrand("Amazon Prime Video", asset: "logo_prime_video", monochromeLogo: true, symbol: "play.rectangle.fill", color: "0779FF", category: .entertainment, popular: true),
        ServiceBrand("1Password", asset: "logo_1password", monochromeLogo: true, symbol: "key.fill", color: "3B66BC", category: .productivity),

        ServiceBrand("Adobe Creative Cloud", asset: "circle_adobe_creative_cloud", symbol: "scribble.variable", color: "F54D8C", category: .productivity),
        ServiceBrand("Amazon Music", asset: "logo_amazon_music", monochromeLogo: true, symbol: "music.note", color: "34D1D9", category: .entertainment),
        ServiceBrand("Amazon Prime", asset: "logo_amazon_prime", monochromeLogo: true, symbol: "shippingbox.fill", color: "0779FF", category: .shopping, popular: true),
        ServiceBrand("Apple Arcade", asset: "logo_apple_arcade", monochromeLogo: true, symbol: "gamecontroller.fill", color: "FF375F", category: .entertainment),
        ServiceBrand("Apple Care+", symbol: "apple.logo", color: "F4F4F4", category: .other),
        ServiceBrand("Apple Developer", symbol: "apple.logo", color: "D9E9FF", category: .productivity),
        ServiceBrand("Apple Fitness+", symbol: "figure.run", color: "A8F438", category: .health),
        ServiceBrand("Apple News+", asset: "logo_apple_news", monochromeLogo: true, symbol: "newspaper.fill", color: "FD415E", category: .education, popular: true),
        ServiceBrand("Apple TV+", asset: "logo_apple_tv", monochromeLogo: true, symbol: "appletv.fill", color: "151515", category: .entertainment, popular: true),
        ServiceBrand("Audible", asset: "logo_audible", monochromeLogo: true, symbol: "wave.3.forward", color: "F8991C", category: .education),
        ServiceBrand("Bumble", symbol: "hexagon.fill", color: "F4C132", category: .social, popular: true),
        ServiceBrand("Calm", symbol: "water.waves", color: "687EE1", category: .health),
        ServiceBrand("Canva Pro", asset: "logo_canva", symbol: "paintpalette.fill", color: "23C4DE", category: .productivity),
        ServiceBrand("CleanShot", symbol: "photo", color: "F4F4F4", category: .productivity),
        ServiceBrand("Costco Membership", asset: "logo_costco", whiteLogoBackground: true, symbol: "cart.fill", color: "E31837", category: .shopping, popular: true),
        ServiceBrand("Crave", symbol: "play.tv.fill", color: "6E2CF4", category: .entertainment, popular: true),
        ServiceBrand("Crunchyroll", asset: "logo_crunchyroll", symbol: "play.circle.fill", color: "F57E37", category: .entertainment),
        ServiceBrand("DAZN", asset: "logo_dazn", monochromeLogo: true, symbol: "sportscourt.fill", color: "171717", category: .entertainment, popular: true),
        ServiceBrand("Daily Burn", symbol: "flame.fill", color: "F4F4F4", category: .health),
        ServiceBrand("DashPass", asset: "logo_doordash", monochromeLogo: true, symbol: "takeoutbag.and.cup.and.straw.fill", color: "FF3008", category: .shopping, popular: true),
        ServiceBrand("Disney+", asset: "logo_disney", monochromeLogo: true, symbol: "sparkles.tv.fill", color: "293171", category: .entertainment, popular: true),
        ServiceBrand("Dropbox", asset: "circle_dropbox", symbol: "shippingbox.fill", color: "1768D8", category: .cloud),
        ServiceBrand("Duolingo", asset: "circle_duolingo", symbol: "bird.fill", color: "75D52A", category: .education),
        ServiceBrand("EA Play", asset: "circle_ea_play", symbol: "gamecontroller.fill", color: "F75F63", category: .entertainment),
        ServiceBrand("eharmony", symbol: "heart.fill", color: "6A52A2", category: .social, popular: true),
        ServiceBrand("ESPN+", asset: "logo_espn", monochromeLogo: true, symbol: "sportscourt.fill", color: "FF0033", category: .entertainment, popular: true),
        ServiceBrand("Etsy Plus", asset: "circle_etsy", symbol: "cart.fill", color: "EE6D2D", category: .shopping),
        ServiceBrand("Figma Professional", asset: "logo_figma", monochromeLogo: true, symbol: "circle.hexagongrid.fill", color: "A259FF", category: .productivity),
        ServiceBrand("Framer", asset: "logo_framer", monochromeLogo: true, symbol: "f.square.fill", color: "0055FF", category: .productivity),
        ServiceBrand("Fubotv", asset: "logo_fubo", monochromeLogo: true, symbol: "tv.fill", color: "C83D1E", category: .entertainment),
        ServiceBrand("Gemini", asset: "logo_gemini", monochromeLogo: true, symbol: "sparkle", color: "8E75B2", category: .productivity),
        ServiceBrand("Google Drive", asset: "logo_google_drive", symbol: "triangle.fill", color: "F4F4F4", category: .cloud),
        ServiceBrand("Google One", asset: "logo_google_one", symbol: "g.circle.fill", color: "F4F4F4", category: .cloud, popular: true),
        ServiceBrand("Google Play", asset: "circle_google_play", symbol: "play.fill", color: "5F6368", category: .entertainment),
        ServiceBrand("Grammarly", asset: "logo_grammarly", symbol: "textformat", color: "55BEA8", category: .productivity),
        ServiceBrand("Grindr", symbol: "person.2.fill", color: "F9D54B", category: .social, popular: true),
        ServiceBrand("HBO Max", asset: "logo_hbo", monochromeLogo: true, symbol: "tv.fill", color: "000000", category: .entertainment, popular: true),
        ServiceBrand("Headspace", asset: "logo_headspace", whiteLogoBackground: true, symbol: "face.smiling", color: "F98B1D", category: .health),
        ServiceBrand("HelloFresh", asset: "logo_hellofresh", monochromeLogo: true, symbol: "takeoutbag.and.cup.and.straw.fill", color: "78BE20", category: .shopping, popular: true),
        ServiceBrand("Hinge", symbol: "h.square.fill", color: "6B6B6B", category: .social, popular: true),
        ServiceBrand("Hulu", asset: "logo_hulu", monochromeLogo: true, symbol: "h.square.fill", color: "37E18B", category: .entertainment, popular: true),
        ServiceBrand("Instacart+", asset: "logo_instacart", monochromeLogo: true, symbol: "basket.fill", color: "43B02A", category: .shopping, popular: true),
        ServiceBrand("Kindle Unlimited", symbol: "books.vertical.fill", color: "146EB4", category: .education, popular: true),
        ServiceBrand("Lifecell", symbol: "point.3.connected.trianglepath.dotted", color: "F6C12A", category: .other),
        ServiceBrand("Lyft Pink", asset: "logo_lyft", monochromeLogo: true, symbol: "car.fill", color: "FF00BF", category: .other),
        ServiceBrand("Match", symbol: "heart.circle.fill", color: "006FCF", category: .social, popular: true),
        ServiceBrand("Microsoft 365", asset: "logo_microsoft365", symbol: "square.stack.3d.up.fill", color: "F4F4F4", category: .productivity, popular: true),
        ServiceBrand("Midjourney", asset: "logo_midjourney", monochromeLogo: true, symbol: "sailboat.fill", color: "181818", category: .productivity),
        ServiceBrand("Nintendo Online", asset: "circle_nintendo", symbol: "gamecontroller.fill", color: "E5313C", category: .entertainment),
        ServiceBrand("Bitbucket", asset: "circle_bitbucket", symbol: "shippingbox.fill", color: "0052CC", category: .productivity),
        ServiceBrand("Discord Nitro", asset: "circle_discord", symbol: "bubble.left.and.bubble.right.fill", color: "7289DA", category: .social),
        ServiceBrand("Flickr Pro", asset: "circle_flickr", symbol: "photo.on.rectangle.angled", color: "0063DC", category: .cloud),
        ServiceBrand("GitHub Pro", asset: "circle_github", symbol: "chevron.left.forwardslash.chevron.right", color: "24292D", category: .productivity),
        ServiceBrand("GitLab", asset: "circle_gitlab", symbol: "chevron.left.forwardslash.chevron.right", color: "FC6D26", category: .productivity),
        ServiceBrand("Ko-fi Gold", asset: "circle_kofi", symbol: "cup.and.saucer.fill", color: "29ABE0", category: .productivity),
        ServiceBrand("Last.fm Pro", asset: "circle_lastfm", symbol: "music.note.list", color: "D51007", category: .entertainment),
        ServiceBrand("Medium Membership", asset: "circle_medium", symbol: "text.book.closed.fill", color: "00AB6C", category: .education),
        ServiceBrand("Meetup", asset: "circle_meetup", symbol: "person.3.fill", color: "F64060", category: .social),
        ServiceBrand("Minecraft Realms", asset: "circle_minecraft", symbol: "cube.fill", color: "6B4F3A", category: .entertainment),
        ServiceBrand("Nexus Mods Premium", asset: "circle_nexus_mods", symbol: "wrench.and.screwdriver.fill", color: "2D6E9E", category: .entertainment),
        ServiceBrand("NordVPN", asset: "logo_nordvpn", monochromeLogo: true, symbol: "shield.lefthalf.filled", color: "4687FF", category: .productivity, popular: true),
        ServiceBrand("Notion Plus", asset: "logo_notion", symbol: "square.text.square.fill", color: "181818", category: .productivity),
        ServiceBrand("Paramount+", asset: "logo_paramount", monochromeLogo: true, symbol: "play.tv.fill", color: "0064FF", category: .entertainment, popular: true),
        ServiceBrand("Patreon", asset: "circle_patreon", symbol: "p.circle.fill", color: "F35B4C", category: .other),
        ServiceBrand("Peacock", asset: "logo_peacock", symbol: "play.tv.fill", color: "000000", category: .entertainment, popular: true),
        ServiceBrand("Peloton", asset: "logo_peloton", monochromeLogo: true, symbol: "figure.indoor.cycle", color: "181A1D", category: .health, popular: true),
        ServiceBrand("PlayStation Plus", asset: "circle_playstation", symbol: "gamecontroller.fill", color: "2364B8", category: .entertainment, popular: true),
        ServiceBrand("Reddit Premium", asset: "circle_reddit", symbol: "bubble.left.and.bubble.right.fill", color: "FF4500", category: .social),
        ServiceBrand("RuneScape Membership", asset: "circle_runescape", symbol: "gamecontroller.fill", color: "2C5877", category: .entertainment),
        ServiceBrand("Slack", asset: "circle_slack", symbol: "number", color: "36C5F0", category: .productivity),
        ServiceBrand("Snapchat+", asset: "circle_snapchat", symbol: "message.fill", color: "FFFC00", category: .social),
        ServiceBrand("SiriusXM", symbol: "radio.fill", color: "0085CA", category: .entertainment, popular: true),
        ServiceBrand("SoundCloud Go+", asset: "circle_soundcloud", symbol: "waveform", color: "FF5500", category: .entertainment),
        ServiceBrand("Sportsnet+", symbol: "sportscourt.fill", color: "DA291C", category: .entertainment, popular: true),
        ServiceBrand("Strava", asset: "logo_strava", monochromeLogo: true, symbol: "figure.run", color: "FC4C02", category: .health, popular: true),
        ServiceBrand("Substack", asset: "circle_substack", symbol: "newspaper.fill", color: "FF6719", category: .education),
        ServiceBrand("Telegram Premium", asset: "circle_telegram", symbol: "paperplane.fill", color: "229ED9", category: .social),
        ServiceBrand("The New York Times", asset: "logo_new_york_times", monochromeLogo: true, symbol: "newspaper.fill", color: "000000", category: .education, popular: true),
        ServiceBrand("Tinder", asset: "logo_tinder", monochromeLogo: true, symbol: "flame.fill", color: "FF6B6B", category: .social, popular: true),
        ServiceBrand("Trello", asset: "circle_trello", symbol: "rectangle.split.2x1.fill", color: "0079BF", category: .productivity),
        ServiceBrand("TSN+", symbol: "sportscourt.fill", color: "E31837", category: .entertainment, popular: true),
        ServiceBrand("Twitch Turbo", asset: "circle_twitch", symbol: "play.rectangle.fill", color: "9146FF", category: .entertainment),
        ServiceBrand("Ubisoft+", asset: "circle_ubisoft", symbol: "gamecontroller.fill", color: "FF0A8D", category: .entertainment),
        ServiceBrand("Uber One", asset: "logo_uber", monochromeLogo: true, symbol: "car.fill", color: "000000", category: .shopping, popular: true),
        ServiceBrand("Ultimate Guitar Pro", asset: "circle_ultimate_guitar", symbol: "guitars.fill", color: "FFCC00", category: .education),
        ServiceBrand("Vimeo", asset: "circle_vimeo", symbol: "video.fill", color: "1AB7EA", category: .productivity),
        ServiceBrand("VSCO", asset: "circle_vsco", symbol: "camera.aperture", color: "F4F4F4", category: .productivity),
        ServiceBrand("X Premium", asset: "circle_x", symbol: "bubble.left.fill", color: "181818", category: .social),
        ServiceBrand("Walmart+", asset: "logo_walmart", monochromeLogo: true, symbol: "cart.fill", color: "0071CE", category: .shopping, popular: true),
        ServiceBrand("Xbox Game Pass", asset: "circle_xbox", symbol: "xbox.logo", color: "3AA638", category: .entertainment, popular: true),
        ServiceBrand("Zoom", asset: "logo_zoom", fillsLogoContainer: true, symbol: "video.fill", color: "2D78F4", category: .productivity)
    ]

    static let americanMobileServices: [ServiceBrand] = [
        ServiceBrand("AT&T", symbol: "antenna.radiowaves.left.and.right", color: "009FDB", category: .mobile, popular: true),
        ServiceBrand("T-Mobile", symbol: "antenna.radiowaves.left.and.right", color: "E20074", category: .mobile, popular: true),
        ServiceBrand("Verizon", asset: "logo_verizon", monochromeLogo: true, symbol: "antenna.radiowaves.left.and.right", color: "CD040B", category: .mobile, popular: true),
        ServiceBrand("Mint Mobile", symbol: "antenna.radiowaves.left.and.right", color: "00B389", category: .mobile, popular: true),
        ServiceBrand("Visible", symbol: "antenna.radiowaves.left.and.right", color: "181818", category: .mobile, popular: true),
        ServiceBrand("Cricket Wireless", symbol: "antenna.radiowaves.left.and.right", color: "60A630", category: .mobile, popular: true),
        ServiceBrand("Metro by T-Mobile", symbol: "antenna.radiowaves.left.and.right", color: "6B2C91", category: .mobile, popular: true),
        ServiceBrand("Google Fi Wireless", symbol: "antenna.radiowaves.left.and.right", color: "4285F4", category: .mobile, popular: true),
        ServiceBrand("Boost Mobile", asset: "logo_boost_mobile", monochromeLogo: true, symbol: "antenna.radiowaves.left.and.right", color: "F7901E", category: .mobile, popular: true),
        ServiceBrand("US Mobile", symbol: "antenna.radiowaves.left.and.right", color: "181818", category: .mobile, popular: true)
    ]

    static let russianServices: [ServiceBrand] = [
        ServiceBrand("Яндекс Плюс", asset: "circle_yandex_plus", symbol: "plus", color: "EB469F", category: .entertainment, popular: true),
        ServiceBrand("Okko", asset: "logo_okko", monochromeLogo: true, symbol: "play.tv.fill", color: "5B2EFF", category: .entertainment, popular: true),
        ServiceBrand("Иви", asset: "logo_ivi", monochromeLogo: true, symbol: "play.tv.fill", color: "EA003D", category: .entertainment, popular: true),
        ServiceBrand("Wink", asset: "logo_wink", monochromeLogo: true, symbol: "play.tv.fill", color: "E93578", category: .entertainment, popular: true),
        ServiceBrand("KION", asset: "logo_kion", monochromeLogo: true, symbol: "play.tv.fill", color: "6B22B8", category: .entertainment, popular: true),
        ServiceBrand("СберПрайм", asset: "logo_sberprime", whiteLogoBackground: true, symbol: "creditcard.fill", color: "21A038", category: .other, popular: true),
        ServiceBrand("Т-Банк Pro", asset: "logo_tbank", whiteLogoBackground: true, symbol: "creditcard.fill", color: "B38B00", category: .other, popular: true),
        ServiceBrand("Ozon Premium", symbol: "cart.fill", color: "005BFF", category: .shopping, popular: true),
        ServiceBrand("VK Музыка", asset: "circle_vk_music", symbol: "music.note", color: "0077FF", category: .entertainment, popular: true),
        ServiceBrand("Звук", symbol: "waveform", color: "171717", category: .entertainment, popular: true),
        ServiceBrand("Яндекс 360", asset: "logo_yandex", monochromeLogo: true, symbol: "cloud.fill", color: "FB3E1C", category: .cloud, popular: true),
        ServiceBrand("Облако Mail", asset: "logo_mailru", monochromeLogo: true, symbol: "cloud.fill", color: "005FF9", category: .cloud, popular: true),
        ServiceBrand("Kaspersky Plus", symbol: "shield.checkered", color: "006D5C", category: .productivity, popular: true)
    ]

    static let russianMobileServices: [ServiceBrand] = [
        ServiceBrand("МТС", asset: "circle_mts", symbol: "antenna.radiowaves.left.and.right", color: "FF0032", category: .mobile, popular: true),
        ServiceBrand("МегаФон", asset: "logo_megafon_monochrome", monochromeLogo: true, symbol: "antenna.radiowaves.left.and.right", color: "00B956", category: .mobile, popular: true),
        ServiceBrand("билайн", asset: "circle_beeline", symbol: "antenna.radiowaves.left.and.right", color: "FFCC00", category: .mobile, popular: true),
        ServiceBrand("t2", asset: "circle_t2", symbol: "antenna.radiowaves.left.and.right", color: "181818", category: .mobile, popular: true),
        ServiceBrand("Yota", asset: "logo_yota_monochrome", monochromeLogo: true, symbol: "antenna.radiowaves.left.and.right", color: "2FB5FF", category: .mobile, popular: true),
        ServiceBrand("Т-Мобайл", asset: "circle_tmobile", symbol: "antenna.radiowaves.left.and.right", color: "5546C8", category: .mobile, popular: true),
        ServiceBrand("СберМобайл", asset: "circle_sbermobile", symbol: "antenna.radiowaves.left.and.right", color: "FF5C00", category: .mobile, popular: true),
        ServiceBrand("ВТБ Мобайл", asset: "circle_vtbmobile", symbol: "antenna.radiowaves.left.and.right", color: "0A4DBE", category: .mobile, popular: true),
        ServiceBrand("Ростелеком", asset: "circle_rostelecom", symbol: "antenna.radiowaves.left.and.right", color: "7700FF", category: .mobile, popular: true)
    ]

    // Regular entry-level retail prices. Trials and promotional offers are intentionally excluded.
    private static let suggestedPrices: [String: SuggestedSubscriptionPrice] = [
        "youtube-premium": SuggestedSubscriptionPrice(13.99),
        "spotify-premium": SuggestedSubscriptionPrice(12.99),
        "netflix": SuggestedSubscriptionPrice(7.99),
        "linkedin-premium": SuggestedSubscriptionPrice(39.99),
        "cursor": SuggestedSubscriptionPrice(20),
        "claude": SuggestedSubscriptionPrice(20),
        "chatgpt": SuggestedSubscriptionPrice(20),
        "icloud+": SuggestedSubscriptionPrice(0.99),
        "apple-one": SuggestedSubscriptionPrice(19.95),
        "apple-music": SuggestedSubscriptionPrice(11.99),
        "apple-news+": SuggestedSubscriptionPrice(12.99),
        "amazon-prime-video": SuggestedSubscriptionPrice(8.99),
        "1password": SuggestedSubscriptionPrice(3.99),
        "adobe-creative-cloud": SuggestedSubscriptionPrice(59.99),
        "amazon-music": SuggestedSubscriptionPrice(11.99),
        "amazon-prime": SuggestedSubscriptionPrice(14.99),
        "apple-arcade": SuggestedSubscriptionPrice(6.99),
        "apple-developer": SuggestedSubscriptionPrice(99, schedule: .yearly),
        "apple-fitness+": SuggestedSubscriptionPrice(9.99),
        "apple-tv+": SuggestedSubscriptionPrice(12.99),
        "audible": SuggestedSubscriptionPrice(14.95),
        "bumble": SuggestedSubscriptionPrice(39.99),
        "calm": SuggestedSubscriptionPrice(69.99, schedule: .yearly),
        "canva-pro": SuggestedSubscriptionPrice(15),
        "costco-membership": SuggestedSubscriptionPrice(65, schedule: .yearly),
        "crave": SuggestedSubscriptionPrice(11.99, currency: .cad),
        "crunchyroll": SuggestedSubscriptionPrice(7.99),
        "dazn": SuggestedSubscriptionPrice(29.99),
        "daily-burn": SuggestedSubscriptionPrice(19.95),
        "dashpass": SuggestedSubscriptionPrice(9.99),
        "disney+": SuggestedSubscriptionPrice(11.99),
        "dropbox": SuggestedSubscriptionPrice(11.99),
        "duolingo": SuggestedSubscriptionPrice(12.99),
        "ea-play": SuggestedSubscriptionPrice(5.99),
        "etsy-plus": SuggestedSubscriptionPrice(10),
        "eharmony": SuggestedSubscriptionPrice(35.90),
        "espn+": SuggestedSubscriptionPrice(12.99),
        "figma-professional": SuggestedSubscriptionPrice(20),
        "framer": SuggestedSubscriptionPrice(10),
        "fubotv": SuggestedSubscriptionPrice(84.99),
        "gemini": SuggestedSubscriptionPrice(19.99),
        "google-one": SuggestedSubscriptionPrice(1.99),
        "google-play": SuggestedSubscriptionPrice(4.99),
        "grammarly": SuggestedSubscriptionPrice(30),
        "grindr": SuggestedSubscriptionPrice(19.99),
        "hbo-max": SuggestedSubscriptionPrice(9.99),
        "headspace": SuggestedSubscriptionPrice(12.99),
        "hellofresh": SuggestedSubscriptionPrice(59.94, schedule: .weekly),
        "hinge": SuggestedSubscriptionPrice(34.99),
        "hulu": SuggestedSubscriptionPrice(11.99),
        "instacart+": SuggestedSubscriptionPrice(9.99),
        "kindle-unlimited": SuggestedSubscriptionPrice(11.99),
        "lyft-pink": SuggestedSubscriptionPrice(9.99),
        "match": SuggestedSubscriptionPrice(44.99),
        "microsoft-365": SuggestedSubscriptionPrice(9.99),
        "midjourney": SuggestedSubscriptionPrice(10),
        "nintendo-online": SuggestedSubscriptionPrice(3.99),
        "bitbucket": SuggestedSubscriptionPrice(3.30),
        "discord-nitro": SuggestedSubscriptionPrice(9.99),
        "flickr-pro": SuggestedSubscriptionPrice(9.49),
        "github-pro": SuggestedSubscriptionPrice(4),
        "gitlab": SuggestedSubscriptionPrice(29),
        "ko-fi-gold": SuggestedSubscriptionPrice(12),
        "last.fm-pro": SuggestedSubscriptionPrice(3),
        "medium-membership": SuggestedSubscriptionPrice(5),
        "meetup": SuggestedSubscriptionPrice(3.99),
        "minecraft-realms": SuggestedSubscriptionPrice(7.99),
        "nexus-mods-premium": SuggestedSubscriptionPrice(7.49, currency: .gbp),
        "nordvpn": SuggestedSubscriptionPrice(12.99),
        "notion-plus": SuggestedSubscriptionPrice(12),
        "paramount+": SuggestedSubscriptionPrice(8.99),
        "peacock": SuggestedSubscriptionPrice(10.99),
        "peloton": SuggestedSubscriptionPrice(15.99),
        "playstation-plus": SuggestedSubscriptionPrice(9.99),
        "reddit-premium": SuggestedSubscriptionPrice(5.99),
        "runescape-membership": SuggestedSubscriptionPrice(13.99),
        "slack": SuggestedSubscriptionPrice(10),
        "snapchat+": SuggestedSubscriptionPrice(3.99),
        "siriusxm": SuggestedSubscriptionPrice(9.99),
        "soundcloud-go+": SuggestedSubscriptionPrice(10.99),
        "sportsnet+": SuggestedSubscriptionPrice(29.99, currency: .cad),
        "strava": SuggestedSubscriptionPrice(79.99, schedule: .yearly),
        "telegram-premium": SuggestedSubscriptionPrice(4.99),
        "the-new-york-times": SuggestedSubscriptionPrice(25),
        "tinder": SuggestedSubscriptionPrice(9.99),
        "trello": SuggestedSubscriptionPrice(6),
        "tsn+": SuggestedSubscriptionPrice(8, currency: .cad),
        "twitch-turbo": SuggestedSubscriptionPrice(11.99),
        "ubisoft+": SuggestedSubscriptionPrice(17.99),
        "uber-one": SuggestedSubscriptionPrice(9.99),
        "ultimate-guitar-pro": SuggestedSubscriptionPrice(99.99, schedule: .yearly),
        "vimeo": SuggestedSubscriptionPrice(20),
        "vsco": SuggestedSubscriptionPrice(7.99),
        "x-premium": SuggestedSubscriptionPrice(8),
        "walmart+": SuggestedSubscriptionPrice(12.95),
        "xbox-game-pass": SuggestedSubscriptionPrice(19.99),
        "zoom": SuggestedSubscriptionPrice(15.99),
        "яндекс-плюс": SuggestedSubscriptionPrice(449, currency: .rub),
        "okko": SuggestedSubscriptionPrice(399, currency: .rub),
        "иви": SuggestedSubscriptionPrice(399, currency: .rub),
        "wink": SuggestedSubscriptionPrice(399, currency: .rub),
        "kion": SuggestedSubscriptionPrice(299, currency: .rub),
        "сберпрайм": SuggestedSubscriptionPrice(299, currency: .rub),
        "т-банк-pro": SuggestedSubscriptionPrice(299, currency: .rub),
        "ozon-premium": SuggestedSubscriptionPrice(199, currency: .rub),
        "vk-музыка": SuggestedSubscriptionPrice(299, currency: .rub),
        "звук": SuggestedSubscriptionPrice(299, currency: .rub),
        "яндекс-360": SuggestedSubscriptionPrice(299, currency: .rub),
        "облако-mail": SuggestedSubscriptionPrice(149, currency: .rub),
        "kaspersky-plus": SuggestedSubscriptionPrice(1_999, currency: .rub, schedule: .yearly)
    ]

    static func suggestedPrice(for service: ServiceBrand) -> SuggestedSubscriptionPrice? {
        suggestedPrices[service.id]
    }

    private static let popularServiceIDs = [
        "youtube-premium", "netflix", "spotify-premium", "amazon-prime",
        "disney+", "hulu", "hbo-max", "apple-tv+", "paramount+", "peacock",
        "crave", "amazon-prime-video", "apple-music", "icloud+", "apple-one",
        "google-one", "microsoft-365", "playstation-plus", "xbox-game-pass",
        "dashpass", "walmart+", "uber-one", "instacart+", "costco-membership",
        "espn+", "dazn", "sportsnet+", "tsn+", "tinder", "bumble", "hinge",
        "match", "eharmony", "grindr", "siriusxm", "kindle-unlimited",
        "the-new-york-times", "apple-news+", "peloton", "strava", "nordvpn",
        "hellofresh", "chatgpt"
    ]

    private static let legacyServiceNames: [String: String] = [
        "youtube": "YouTube Premium",
        "spotify": "Spotify Premium",
        "linkedin": "LinkedIn Premium",
        "apple icloud": "iCloud+",
        "apple tv": "Apple TV+",
        "adobe cloud": "Adobe Creative Cloud",
        "doordash": "DashPass",
        "twitch": "Twitch Turbo",
        "canva": "Canva Pro",
        "github": "GitHub Pro",
        "figma": "Figma Professional",
        "notion": "Notion Plus"
    ]

    static func popular(locale: Locale) -> [ServiceBrand] {
        guard !isRussian(locale) else { return russianServices }
        let servicesByID = Dictionary(uniqueKeysWithValues: services.map { ($0.id, $0) })
        return popularServiceIDs.compactMap { servicesByID[$0] }
    }

    static func mobileProviders(locale: Locale) -> [ServiceBrand] {
        isRussian(locale) ? russianMobileServices : americanMobileServices
    }

    static func all(locale: Locale) -> [ServiceBrand] {
        let featuredIDs = Set((popular(locale: locale) + mobileProviders(locale: locale)).map(\.id))
        return visibleServices(locale: locale)
            .filter { !featuredIDs.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func visibleServices(locale: Locale) -> [ServiceBrand] {
        if isRussian(locale) {
            return russianServices + russianMobileServices + services
        }
        return services + americanMobileServices
    }

    static func contains(_ service: ServiceBrand) -> Bool {
        knownServices.contains { $0.id == service.id }
    }

    static func service(named name: String, category: SubscriptionCategory = .other) -> ServiceBrand {
        let canonicalName = legacyServiceNames[name.lowercased()] ?? name
        return knownServices.first {
            $0.name.localizedCaseInsensitiveCompare(canonicalName) == .orderedSame
        } ?? ServiceBrand(name, category: category)
    }

    private static var knownServices: [ServiceBrand] {
        services + russianServices + americanMobileServices + russianMobileServices
    }

    private static func isRussian(_ locale: Locale) -> Bool {
        locale.language.languageCode?.identifier == "ru"
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
    var draftStartDate: Date?
    var editingSubscription: SubscriptionRecord?
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
        if editingSubscription?.id == id { editingSubscription = nil }
    }

    func deleteAllSubscriptions() {
        subscriptions.removeAll()
        editingSubscription = nil
        showingDaySubscriptions = false
    }

    func presentAnalytics() {
        showingAnalytics = true
    }

    func select(date: Date) {
        let date = Self.calendar.startOfDay(for: date)
        selectedMonth = Self.monthStart(for: date)
        selectedDay = Self.calendar.component(.day, from: date)
        selectedDate = date
    }

    func presentSelectedDate() {
        if subscriptions(on: selectedDate).isEmpty {
            draftStartDate = selectedDate
            showingCatalog = true
        } else {
            showingDaySubscriptions = true
        }
    }

    func total(
        in month: Date,
        category: SubscriptionCategory? = nil,
        convertedTo currency: AppCurrency
    ) -> Double {
        visibleSubscriptions
            .filter { category == nil || $0.category == category }
            .reduce(0) { $0 + chargeAmount(for: $1, in: month, convertedTo: currency) }
    }

    func subscriptions(on date: Date) -> [SubscriptionRecord] {
        visibleSubscriptions.filter { isDue($0, on: date) }
    }

    func nextPayment(
        from date: Date = Date(),
        convertedTo currency: AppCurrency
    ) -> (date: Date, amount: Double)? {
        let start = Self.calendar.startOfDay(for: date)
        for offset in 0...366 {
            guard let candidate = Self.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let due = subscriptions(on: candidate)
            if !due.isEmpty {
                return (candidate, due.reduce(0) { $0 + $1.amount(convertedTo: currency) })
            }
        }
        return nil
    }

    func activeSubscriptions(in year: Int, category: SubscriptionCategory? = nil) -> [SubscriptionRecord] {
        visibleSubscriptions.filter { subscription in
            guard category == nil || subscription.category == category else { return false }
            return months(in: year).contains { !datesDue(for: subscription, in: $0).isEmpty }
        }
    }

    func forecast(
        in year: Int,
        category: SubscriptionCategory? = nil,
        convertedTo currency: AppCurrency
    ) -> Double {
        months(in: year).reduce(0) {
            $0 + total(in: $1, category: category, convertedTo: currency)
        }
    }

    func lifetimePaidTotal(
        asOf date: Date = Date(),
        convertedTo currency: AppCurrency
    ) -> Double {
        subscriptions.reduce(0) { total, subscription in
            total + lifetimePaidAmount(for: subscription, asOf: date, convertedTo: currency)
        }
    }

    func lifetimePaidTotalsByService(
        asOf date: Date = Date(),
        convertedTo currency: AppCurrency
    ) -> [(service: ServiceBrand, amount: Double)] {
        Dictionary(grouping: subscriptions, by: \.service)
            .map { service, records in
                let amount = records.reduce(0) { total, subscription in
                    total + lifetimePaidAmount(for: subscription, asOf: date, convertedTo: currency)
                }
                return (service: service, amount: amount)
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    func categoryForecasts(
        in year: Int,
        convertedTo currency: AppCurrency
    ) -> [(category: SubscriptionCategory, amount: Double)] {
        SubscriptionCategory.allCases
            .map { ($0, forecast(in: year, category: $0, convertedTo: currency)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    private func lifetimePaidAmount(
        for subscription: SubscriptionRecord,
        asOf date: Date,
        convertedTo currency: AppCurrency
    ) -> Double {
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
            paid += Double(completedCharges.count) * subscription.amount(convertedTo: currency)

            guard let nextMonth = Self.calendar.date(byAdding: .month, value: 1, to: month) else {
                break
            }
            month = nextMonth
        }

        return paid
    }

    func serviceForecasts(
        in year: Int,
        category: SubscriptionCategory? = nil,
        convertedTo currency: AppCurrency
    ) -> [(service: ServiceBrand, amount: Double)] {
        Dictionary(grouping: activeSubscriptions(in: year, category: category), by: \.service)
            .map { service, subscriptions -> (service: ServiceBrand, amount: Double) in
                let amount = months(in: year).reduce(0) { total, month in
                    total + subscriptions.reduce(0) {
                        $0 + chargeAmount(for: $1, in: month, convertedTo: currency)
                    }
                }
                return (service, amount)
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    func months(in year: Int) -> [Date] {
        (1...12).map { Self.makeDate(year: year, month: $0, day: 1) }
    }

    private func chargeAmount(
        for subscription: SubscriptionRecord,
        in month: Date,
        convertedTo currency: AppCurrency
    ) -> Double {
        let monthDates = datesDue(for: subscription, in: month)
        return Double(monthDates.count) * subscription.amount(convertedTo: currency)
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
            let savedMainCurrency = defaults.string(forKey: "subscription-day.main-currency")
                .flatMap(AppCurrency.init(rawValue:)) ?? .usd
            let restoredSubscriptions = records.map { $0.record(defaultCurrency: savedMainCurrency) }
            subscriptions = restoredSubscriptions

            let needsCatalogMigration = zip(records, restoredSubscriptions).contains {
                $0.serviceName != $1.service.name || $0.name != $1.name
            }
            if records.contains(where: { $0.currency == nil }) || needsCatalogMigration,
               let migratedData = try? JSONEncoder().encode(restoredSubscriptions.map(PersistedSubscription.init)) {
                defaults.set(migratedData, forKey: Self.storageKey)
            }
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
    let currency: AppCurrency?
    let schedule: PaymentSchedule
    let startDate: Date
    let endDate: Date?
    let category: SubscriptionCategory
    let paymentMethod: String
    let cardName: String?
    let notifications: String
    let serviceSymbol: String?
    let serviceColor: String?
    let serviceUsesCustomIcon: Bool?

    init(_ record: SubscriptionRecord) {
        id = record.id
        serviceName = record.service.name
        name = record.name
        amount = record.amount
        currency = record.currency
        schedule = record.schedule
        startDate = record.startDate
        endDate = record.endDate
        category = record.category
        paymentMethod = record.paymentMethod
        cardName = record.cardName.isEmpty ? nil : record.cardName
        notifications = record.notifications
        serviceSymbol = record.service.usesCustomIcon ? record.service.fallbackSymbol : nil
        serviceColor = record.service.usesCustomIcon ? record.service.fallbackColor : nil
        serviceUsesCustomIcon = record.service.usesCustomIcon ? true : nil
    }

    func record(defaultCurrency: AppCurrency) -> SubscriptionRecord {
        let service: ServiceBrand
        if serviceUsesCustomIcon == true {
            service = ServiceBrand(
                serviceName,
                symbol: serviceSymbol ?? "initial",
                color: serviceColor ?? "7354E8",
                category: category,
                customIcon: true
            )
        } else {
            service = ServiceCatalog.service(named: serviceName, category: category)
        }
        let restoredName = name.localizedCaseInsensitiveCompare(serviceName) == .orderedSame
            ? service.name
            : name

        return SubscriptionRecord(
            id: id,
            service: service,
            name: restoredName,
            amount: amount,
            currency: currency ?? defaultCurrency,
            schedule: schedule,
            startDate: startDate,
            endDate: endDate,
            category: category,
            paymentMethod: paymentMethod,
            cardName: cardName ?? "",
            notifications: notifications
        )
    }
}
