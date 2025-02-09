import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // Dynamic background
            viewModel.backgroundGradient
                .ignoresSafeArea()
            
            // Animated weather particles
            WeatherParticlesView(weatherType: viewModel.currentWeather?.weather.first?.icon ?? "")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                LoadingView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Search and location header
                        HStack {
                            Button(action: { showingSearch = true }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title3)
                                    Text(viewModel.selectedCity)
                                        .font(.title3.weight(.medium))
                                    Image(systemName: "chevron.down")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            
                            Spacer()
                            
                            Button(action: refreshWeather) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Current weather card
                        CurrentWeatherCard(viewModel: viewModel)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        
                        // Hourly forecast
                        if !viewModel.forecast.isEmpty {
                            HourlyForecastView(forecast: viewModel.forecast)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Weather details
                        WeatherDetailsGrid(viewModel: viewModel)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .padding(.top)
                }
                .refreshable {
                    await refreshWeatherAsync()
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            CitySearchView(selectedCity: $viewModel.selectedCity)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .onChange(of: viewModel.selectedCity) { _ in
            withAnimation {
                viewModel.fetchWeather()
            }
        }
        .onAppear {
            withAnimation {
                viewModel.fetchWeather()
            }
        }
    }
    
    private func refreshWeather() {
        withAnimation(.linear(duration: 1)) {
            isRefreshing = true
        }
        
        Task {
            await refreshWeatherAsync()
            
            withAnimation(.linear(duration: 0.2)) {
                isRefreshing = false
            }
        }
    }
    
    private func refreshWeatherAsync() async {
        await viewModel.fetchWeatherAsync()
    }
}

// MARK: - Supporting Views

struct CurrentWeatherCard: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Weather icon
            Image(systemName: viewModel.weatherIcon)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .shadow(color: .white.opacity(0.3), radius: 10)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            
            VStack(spacing: 8) {
                // Temperature
                Text(viewModel.formatTemperature(viewModel.temperature))
                    .font(.system(size: 76, weight: .bold))
                    .foregroundColor(.white)
                
                // Weather description
                Text(viewModel.description.capitalized)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal)
    }
}

struct HourlyForecastView: View {
    let forecast: [ForecastResponse.ForecastItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hourly Forecast")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(forecast) { item in
                        HourlyForecastCard(item: item)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.horizontal)
    }
}

struct HourlyForecastCard: View {
    let item: ForecastResponse.ForecastItem
    
    var body: some View {
        VStack(spacing: 12) {
            Text(item.timeString)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
            
            Image(systemName: item.weather.first?.icon ?? "cloud")
                .renderingMode(.original)
                .font(.system(size: 28))
            
            Text("\(Int(round(item.main.temp)))°")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 100, height: 120)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct WeatherDetailsGrid: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            WeatherDetailCard(
                icon: "thermometer",
                title: "Feels Like",
                value: viewModel.formatTemperature(viewModel.feelsLike)
            )
            
            WeatherDetailCard(
                icon: "humidity",
                title: "Humidity",
                value: "\(viewModel.humidity)%"
            )
        }
        .padding(.horizontal)
    }
}

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Image(systemName: "cloud.sun.fill")
                .renderingMode(.original)
                .font(.system(size: 70))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .scaleEffect(isAnimating ? 1.2 : 1)
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
            
            Text("Loading weather...")
                .font(.title3)
                .foregroundColor(.white)
                .padding(.top)
        }
    }
}

struct WeatherParticlesView: View {
    let weatherType: String
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<20) { index in
                    ParticleView(weatherType: weatherType)
                        .offset(x: randomOffset(for: index, in: geometry.size.width),
                                y: randomOffset(for: index, in: geometry.size.height))
                }
            }
        }
    }
    
    private func randomOffset(for index: Int, in size: CGFloat) -> CGFloat {
        let random = CGFloat.random(in: 0...size)
        return random
    }
}

struct ParticleView: View {
    let weatherType: String
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: particleSymbol)
            .foregroundColor(.white.opacity(0.3))
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
    
    private var particleSymbol: String {
        switch weatherType {
        case "cloud.rain.fill":
            return "drop.fill"
        case "cloud.snow.fill":
            return "snowflake"
        case "sun.max.fill":
            return "sparkle"
        default:
            return "circle.fill"
        }
    }
}

struct CitySearchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCity: String
    @StateObject private var searchViewModel = CitySearchViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(searchViewModel.searchResults) { city in
                    Button(action: {
                        selectedCity = city.fullName
                        dismiss()
                    }) {
                        VStack(alignment: .leading) {
                            Text(city.name)
                                .font(.headline)
                            Text(city.country)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchViewModel.searchQuery, prompt: "Search for a city")
            .navigationTitle("Search City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class CitySearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published private(set) var searchResults: [City] = []
    
    private var searchTask: Task<Void, Never>?
    
    init() {
        // Set up search query observation
        Task {
            for await _ in NotificationCenter.default.notifications(named: NSNotification.Name("searchQueryChanged")) {
                await search()
            }
        }
    }
    
    @MainActor
    private func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        do {
            searchResults = try await LocationService.shared.searchCities(matching: searchQuery)
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
}

#Preview {
    WeatherView()
} 