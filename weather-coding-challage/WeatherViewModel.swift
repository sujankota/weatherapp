//
//  WeatherViewModel.swift
//  weather-coding-challage
//
//  Created by sujan kota on 9/18/24.
//

import Foundation

struct WeatherData: Codable {
    let name: String
    let main: MainWeather
    let weather: [Weather]
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Int
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }
}

struct Weather: Codable, Identifiable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct ErrorResponse: Codable {
    let cod: String
    let message: String
}

enum WeatherError: Error, Identifiable {
    case invalidCity
    case invalidURL
    case networkError(String)
    case serverError(Int)
    case cityNotFound
    case noData
    case decodingError(String)

    var id: String { localizedDescription }

    var localizedDescription: String {
        switch self {
        case .invalidCity:
            return "Invalid city name"
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let description):
            return "Network error: \(description)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .cityNotFound:
            return "City not found"
        case .noData:
            return "No data received"
        case .decodingError(let description):
            return "Error decoding data: \(description)"
        }
    }
}

class WeatherViewModel: ObservableObject {
    @Published var weatherData: WeatherData?
    @Published var city: String = ""
    @Published var error: WeatherError?
    
    private let apiKey = "2f7c0a6906ef2f9d12be9b3f1ca7be52"
    
    func fetchWeather() {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            self.error = .invalidCity
            return
        }
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&APPID=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            self.error = .invalidURL
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = .networkError(error.localizedDescription)
                    self.logResponse(error: self.error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.error = .networkError("Invalid response type")
                    self.logResponse(error: self.error)
                    return
                }
                
                self.logResponse(statusCode: httpResponse.statusCode, headers: httpResponse.allHeaderFields)
                
                guard let data = data else {
                    self.error = .noData
                    return
                }
                
                self.logResponse(data: data)
                
                if httpResponse.statusCode == 404 {
                    do {
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        if errorResponse.message == "city not found" {
                            self.error = .cityNotFound
                        } else {
                            self.error = .serverError(httpResponse.statusCode)
                        }
                    } catch {
                        self.error = .decodingError(error.localizedDescription)
                    }
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    self.error = .serverError(httpResponse.statusCode)
                    return
                }
                
                do {
                    let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
                    self.weatherData = weatherData
                    self.error = nil
                } catch {
                    self.error = .decodingError(error.localizedDescription)
                    self.logResponse(error: self.error)
                }
            }
        }.resume()
    }
    
    private func logResponse(statusCode: Int? = nil, headers: [AnyHashable: Any]? = nil, data: Data? = nil, error: Error? = nil) {
        var logMessage = "API Response Log:\n"
        
        if let statusCode = statusCode {
            logMessage += "Status Code: \(statusCode)\n"
        }
        
        if let headers = headers {
            logMessage += "Headers: \(headers)\n"
        }
        
        if let data = data {
            if let jsonString = String(data: data, encoding: .utf8) {
                logMessage += "Data: \(jsonString)\n"
            } else {
                logMessage += "Data: Unable to convert to string\n"
            }
        }
        
        if let error = error {
            logMessage += "Error: \(error.localizedDescription)\n"
        }
        
        print(logMessage)
    }
}
