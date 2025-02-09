import Foundation
import SwiftUI

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var forecast: [ForecastResponse.ForecastItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCity = "San Francisco"
    @AppStorage("useMetric") private var useMetric = true
    
    private let weatherService = WeatherService.shared
    private var refreshTask: Task<Void, Never>?
    
    // Computed properties for easy access
    var temperature: Double {
        let temp = currentWeather?.main.temp ?? 0.0
        return useMetric ? temp : (temp * 9/5 + 32)
    }
    
    var feelsLike: Double {
        let temp = currentWeather?.main.feels_like ?? 0.0
        return useMetric ? temp : (temp * 9/5 + 32)
    }
    
    var humidity: Int { currentWeather?.main.humidity ?? 0 }
    var description: String { currentWeather?.weather.first?.description ?? "" }
    var weatherIcon: String { currentWeather?.weather.first?.icon ?? "cloud" }
    
    // Background gradient based on time of day and weather
    var backgroundGradient: LinearGradient {
        let hour = Calendar.current.component(.hour, from: Date())
        let weatherCode = currentWeather?.weather.first?.icon ?? ""
        
        let colors: [Color]
        
        switch (hour, weatherCode) {
        case (6...8, _): // Sunrise
            colors = [
                Color(red: 0.85, green: 0.6, blue: 0.2),
                Color(red: 0.3, green: 0.3, blue: 0.6)
            ]
        case (9...17, "sun.max.fill"):  // Sunny day
            colors = [
                Color(red: 0.4, green: 0.6, blue: 0.9),
                Color(red: 0.2, green: 0.4, blue: 0.8)
            ]
        case (9...17, "cloud.fill"), (9...17, "cloud.sun.fill"):  // Cloudy day
            colors = [
                Color(red: 0.5, green: 0.5, blue: 0.6),
                Color(red: 0.3, green: 0.3, blue: 0.4)
            ]
        case (9...17, "cloud.rain.fill"), (9...17, "cloud.drizzle.fill"):  // Rainy day
            colors = [
                Color(red: 0.3, green: 0.3, blue: 0.4),
                Color(red: 0.2, green: 0.2, blue: 0.3)
            ]
        case (18...20, _): // Sunset
            colors = [
                Color(red: 0.8, green: 0.4, blue: 0.3),
                Color(red: 0.3, green: 0.2, blue: 0.5)
            ]
        default: // Night
            colors = [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ]
        }
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    func fetchWeather() {
        isLoading = true
        errorMessage = nil
        
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        refreshTask = Task {
            await fetchWeatherAsync()
        }
    }
    
    func fetchWeatherAsync() async {
        do {
            async let weatherData = weatherService.fetchWeather(for: selectedCity)
            async let forecastData = weatherService.fetchForecast(for: selectedCity)
            
            // Fetch both in parallel
            let (weather, forecast) = await (try weatherData, try forecastData)
            
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentWeather = weather
                    self.forecast = forecast.list
                    self.isLoading = false
                }
            }
        } catch {
            if !Task.isCancelled {
                withAnimation {
                    if let weatherError = error as? WeatherError {
                        self.errorMessage = weatherError.errorDescription
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    func toggleTemperatureUnit() {
        withAnimation(.easeInOut(duration: 0.3)) {
            useMetric.toggle()
            objectWillChange.send()
        }
    }
    
    // Format temperature based on current unit setting
    func formatTemperature(_ temp: Double) -> String {
        let temperature = useMetric ? temp : (temp * 9/5 + 32)
        return "\(Int(round(temperature)))°\(useMetric ? "C" : "F")"
    }
    
    // Get appropriate weather animation based on weather code and time
    func weatherAnimation(for icon: String) -> String {
        switch icon {
        case "sun.max.fill":
            return "clear_day"
        case "cloud.sun.fill":
            return "partly_cloudy"
        case "cloud.fill":
            return "cloudy"
        case "cloud.rain.fill", "cloud.drizzle.fill":
            return "rain"
        case "cloud.snow.fill":
            return "snow"
        case "cloud.bolt.fill", "cloud.bolt.rain.fill":
            return "thunder"
        default:
            return "clear_day"
        }
    }
    
    deinit {
        refreshTask?.cancel()
    }
} 