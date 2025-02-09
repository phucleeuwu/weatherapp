import Foundation

// Main weather data model
struct WeatherData: Codable, Identifiable, Hashable {
    let id = UUID()
    let main: Main
    let weather: [Weather]
    let name: String
    let timestamp: Date
    
    struct Main: Codable, Hashable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
        let pressure: Int
        
        // Computed properties for different temperature units
        var tempFahrenheit: Double { temp * 9/5 + 32 }
        var feelsLikeFahrenheit: Double { feels_like * 9/5 + 32 }
    }
    
    struct Weather: Codable, Hashable {
        let description: String
        let icon: String
        let main: String
    }
    
    // Default initializer
    init(main: Main, weather: [Weather], name: String, timestamp: Date = Date()) {
        self.main = main
        self.weather = weather
        self.name = name
        self.timestamp = timestamp
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: WeatherData, rhs: WeatherData) -> Bool {
        lhs.id == rhs.id
    }
}

// Forecast data model
struct ForecastResponse: Codable, Hashable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable, Identifiable, Hashable {
        let dt: TimeInterval
        let main: WeatherData.Main
        let weather: [WeatherData.Weather]
        
        var id: TimeInterval { dt }
        var date: Date { Date(timeIntervalSince1970: dt) }
        
        // Formatted time string
        var timeString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        
        // Formatted day string
        var dayString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // Implement Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(dt)
        }
        
        static func == (lhs: ForecastItem, rhs: ForecastItem) -> Bool {
            lhs.dt == rhs.dt
        }
    }
}

// Weather condition codes and their corresponding SF Symbols
enum WeatherCondition: Int {
    case clearSky = 0
    case partlyCloudy = 1
    case cloudy = 2
    case overcast = 3
    case foggy = 45
    case depositingRimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case rainLight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case snowLight = 71
    case snowModerate = 73
    case snowHeavy = 75
    case snowGrains = 77
    case rainShowers = 80
    case rainShowersHeavy = 82
    case snowShowers = 85
    case thunderstorm = 95
    case thunderstormHail = 99
    
    var sfSymbol: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy, .overcast: return "cloud.fill"
        case .foggy, .depositingRimeFog: return "cloud.fog.fill"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "cloud.drizzle.fill"
        case .rainLight: return "cloud.rain.fill"
        case .rainModerate, .rainHeavy: return "cloud.heavyrain.fill"
        case .snowLight, .snowModerate, .snowHeavy, .snowGrains: return "cloud.snow.fill"
        case .rainShowers: return "cloud.rain.fill"
        case .rainShowersHeavy: return "cloud.heavyrain.fill"
        case .snowShowers: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .thunderstormHail: return "cloud.bolt.rain.fill"
        }
    }
    
    var description: String {
        switch self {
        case .clearSky: return "Clear sky"
        case .partlyCloudy: return "Partly cloudy"
        case .cloudy: return "Cloudy"
        case .overcast: return "Overcast"
        case .foggy: return "Foggy"
        case .depositingRimeFog: return "Freezing fog"
        case .drizzleLight: return "Light drizzle"
        case .drizzleModerate: return "Moderate drizzle"
        case .drizzleDense: return "Dense drizzle"
        case .rainLight: return "Light rain"
        case .rainModerate: return "Moderate rain"
        case .rainHeavy: return "Heavy rain"
        case .snowLight: return "Light snow"
        case .snowModerate: return "Moderate snow"
        case .snowHeavy: return "Heavy snow"
        case .snowGrains: return "Snow grains"
        case .rainShowers: return "Rain showers"
        case .rainShowersHeavy: return "Heavy rain showers"
        case .snowShowers: return "Snow showers"
        case .thunderstorm: return "Thunderstorm"
        case .thunderstormHail: return "Thunderstorm with hail"
        }
    }
} 