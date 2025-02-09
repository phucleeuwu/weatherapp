import Foundation

enum WeatherError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case invalidCoordinates
    case networkError(Error)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .noData:
            return "No weather data available."
        case .decodingError:
            return "Error processing weather data."
        case .invalidCoordinates:
            return "Invalid city coordinates."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error (Code: \(code))"
        }
    }
}

@MainActor
class WeatherService {
    static let shared = WeatherService()
    private init() {}
    
    private let baseURL = "https://api.open-meteo.com/v1"
    private let cache = NSCache<NSString, CachedWeatherData>()
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // Dictionary of city coordinates (latitude, longitude)
    private let cities: [String: (lat: Double, lon: Double)] = [
        "San Francisco": (37.7749, -122.4194),
        "New York": (40.7128, -74.0060),
        "London": (51.5074, -0.1278),
        "Tokyo": (35.6762, 139.6503),
        "Sydney": (-33.8688, 151.2093),
        "Paris": (48.8566, 2.3522),
        "Dubai": (25.2048, 55.2708),
        "Singapore": (1.3521, 103.8198),
        "Hong Kong": (22.3193, 114.1694),
        "Mumbai": (19.0760, 72.8777)
    ]
    
    func fetchWeather(for city: String, useCacheIfAvailable: Bool = true) async throws -> WeatherData {
        // Check cache first if enabled
        if useCacheIfAvailable {
            if let cachedData = cache.object(forKey: city as NSString),
               Date().timeIntervalSince(cachedData.timestamp) < cacheTimeout {
                return cachedData.weatherData
            }
        }
        
        guard let coordinates = cities[city] else {
            throw WeatherError.invalidCoordinates
        }
        
        // Updated URL with correct parameters for current weather
        let urlString = "\(baseURL)/forecast?latitude=\(coordinates.lat)&longitude=\(coordinates.lon)&current_weather=true&temperature_unit=celsius&windspeed_unit=kmh&precipitation_unit=mm&timezone=auto"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.networkError(NSError(domain: "", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw WeatherError.serverError(httpResponse.statusCode)
            }
            
            let openMeteoResponse = try decoder.decode(OpenMeteoResponse.self, from: data)
            
            let weatherData = WeatherData(
                main: .init(
                    temp: openMeteoResponse.current_weather.temperature,
                    feels_like: openMeteoResponse.current_weather.temperature, // Open-Meteo free tier doesn't provide feels_like
                    humidity: 0, // Not available in current_weather
                    pressure: 0  // Not available in current_weather
                ),
                weather: [
                    .init(
                        description: WeatherCondition(rawValue: openMeteoResponse.current_weather.weathercode)?.description ?? "Unknown",
                        icon: WeatherCondition(rawValue: openMeteoResponse.current_weather.weathercode)?.sfSymbol ?? "cloud",
                        main: WeatherCondition(rawValue: openMeteoResponse.current_weather.weathercode)?.description ?? "Unknown"
                    )
                ],
                name: city,
                timestamp: Date()
            )
            
            // Cache the result
            cache.setObject(CachedWeatherData(weatherData: weatherData), forKey: city as NSString)
            
            return weatherData
        } catch {
            throw WeatherError.networkError(error)
        }
    }
    
    func fetchForecast(for city: String) async throws -> ForecastResponse {
        guard let coordinates = cities[city] else {
            throw WeatherError.invalidCoordinates
        }
        
        // Updated URL with correct parameters for hourly forecast
        let urlString = "\(baseURL)/forecast?latitude=\(coordinates.lat)&longitude=\(coordinates.lon)&hourly=temperature_2m,weathercode,precipitation_probability&temperature_unit=celsius&timezone=auto"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.networkError(NSError(domain: "", code: -1))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw WeatherError.serverError(httpResponse.statusCode)
            }
            
            let openMeteoResponse = try decoder.decode(OpenMeteoForecastResponse.self, from: data)
            
            let forecastItems = openMeteoResponse.hourly.time.indices
                .filter { $0 % 3 == 0 } // Every 3 hours
                .prefix(8) // Next 24 hours
                .map { index -> ForecastResponse.ForecastItem in
                    let time = openMeteoResponse.hourly.time[index]
                    let temp = openMeteoResponse.hourly.temperature_2m[index]
                    let code = openMeteoResponse.hourly.weathercode[index]
                    let precip = openMeteoResponse.hourly.precipitation_probability[index]
                    
                    return ForecastResponse.ForecastItem(
                        dt: time.timeIntervalSince1970,
                        main: .init(
                            temp: temp,
                            feels_like: temp,
                            humidity: precip,
                            pressure: 0
                        ),
                        weather: [
                            .init(
                                description: WeatherCondition(rawValue: code)?.description ?? "Unknown",
                                icon: WeatherCondition(rawValue: code)?.sfSymbol ?? "cloud",
                                main: WeatherCondition(rawValue: code)?.description ?? "Unknown"
                            )
                        ]
                    )
                }
            
            return ForecastResponse(list: Array(forecastItems))
        } catch {
            throw WeatherError.networkError(error)
        }
    }
}

// Cache wrapper
private class CachedWeatherData {
    let weatherData: WeatherData
    let timestamp: Date
    
    init(weatherData: WeatherData, timestamp: Date = Date()) {
        self.weatherData = weatherData
        self.timestamp = timestamp
    }
}

// Updated Open-Meteo API Response Models
struct OpenMeteoResponse: Codable {
    let current_weather: CurrentWeather
    
    struct CurrentWeather: Codable {
        let temperature: Double
        let weathercode: Int
        let windspeed: Double
        let winddirection: Double
        let time: String
    }
}

struct OpenMeteoForecastResponse: Codable {
    let hourly: HourlyForecast
    
    struct HourlyForecast: Codable {
        let time: [Date]
        let temperature_2m: [Double]
        let weathercode: [Int]
        let precipitation_probability: [Int]
    }
} 