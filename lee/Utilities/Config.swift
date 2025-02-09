import Foundation

enum Config {
    enum URLs {
        static let weatherBaseURL = "https://api.open-meteo.com/v1"
    }
    
    enum Units {
        static let temperature = "celsius" // Can be "celsius" or "fahrenheit"
    }
    
    // Open-Meteo Benefits:
    // - Completely free
    // - No API key required
    // - No rate limits
    // - High accuracy weather data
    // - 16 days of weather forecast
    // For more details: https://open-meteo.com/
} 