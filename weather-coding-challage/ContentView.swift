//
//  ContentView.swift
//  weather-coding-challage
//
//  Created by sujan kota on 9/18/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter city name", text: $viewModel.city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Get Weather") {
                    viewModel.fetchWeather()
                }
                
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if let weatherData = viewModel.weatherData {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("City: \(weatherData.name)")
                        Text("Temperature: \(String(format: "%.1f", weatherData.main.temp))°C")
                        Text("Feels like: \(String(format: "%.1f", weatherData.main.feelsLike))°C")
                        Text("Min Temp: \(String(format: "%.1f", weatherData.main.tempMin))°C")
                        Text("Max Temp: \(String(format: "%.1f", weatherData.main.tempMax))°C")
                        Text("Pressure: \(weatherData.main.pressure) hPa")
                        Text("Humidity: \(weatherData.main.humidity)%")
                        if let weather = weatherData.weather.first {
                            Text("Description: \(weather.description)")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Current Weather")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
