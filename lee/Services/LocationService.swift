import Foundation

struct City: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String
    
    var fullName: String {
        "\(name), \(country)"
    }
}

@MainActor
class LocationService {
    static let shared = LocationService()
    private init() {}
    
    private let baseURL = "https://secure.geonames.org"
    private let username = "demo" // Replace with your GeoNames username
    
    private var citiesCache: [String: [City]] = [:]
    
    func searchCities(matching query: String) async throws -> [City] {
        guard query.count >= 2 else { return [] }
        
        if let cached = citiesCache[query] {
            return cached
        }
        
        let urlString = "\(baseURL)/searchJSON?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&maxRows=10&username=\(username)&orderby=relevance&cities=cities1000"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GeoNamesResponse.self, from: data)
        
        let cities = response.geonames.map { geoname in
            City(
                name: geoname.name,
                country: geoname.countryName,
                latitude: geoname.lat,
                longitude: geoname.lng,
                timezone: geoname.timezone?.timeZoneId ?? "UTC"
            )
        }
        
        citiesCache[query] = cities
        return cities
    }
}

// GeoNames API Response Models
private struct GeoNamesResponse: Codable {
    let geonames: [Geoname]
}

private struct Geoname: Codable {
    let name: String
    let countryName: String
    let lat: Double
    let lng: Double
    let timezone: TimeZone?
    
    struct TimeZone: Codable {
        let timeZoneId: String
    }
} 