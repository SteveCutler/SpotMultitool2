import Foundation
import Combine
import WatchConnectivity


struct ImageData {
    let title: String
    let imageUrl: String
    let sourceUrl: String
}

enum MessageType {
    case text(String)
    case imageSearch(ImagesResponse)
    case movieShowtimes(MovieShowtimesResponse)
    case movieInfo(MovieInfoResponse)
    case mapGenerator(MapGeneratorResponse) // Update this line
    case googleSearch(GoogleSearchResponse)
    case wikipedia(WikipediaResponse)
    case hourlyForecast(HourlyForecastResponse)
    case dailyForecast(DailyForecastResponse)
    case places(PlacesResponse)
    case chat(ChatResponse)
}


struct Message: Identifiable {
    let id = UUID()
    let type: MessageType
    let isSentByUser: Bool
}


class ChatViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var messages: [Message] = []
    @Published var errorMessage: String?
    @Published var isButtonInSendMode = true
    
    var audioRecorderManager = AudioRecorderManager()
    // Update this function to accept a Message object
    private func addMessage(_ message: Message) {
        DispatchQueue.main.async {
            self.messages.append(message)
        }
    }
    
    override init() {
            super.init()
            setupWCSession()
        }

       private func setupWCSession() {
           if WCSession.isSupported() {
               let session = WCSession.default
               session.delegate = self
               session.activate()
           }
       }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let query = message["query"] as? String else { return }
        sendQuery(query) { response in
            // Send the response back to the watch
            session.sendMessage(["response": response], replyHandler: nil, errorHandler: nil)
        }
    }


    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation
    }
    
    func loadDummyData() {
        let dummyData = """
        
        {
            "final_answer": "The forecast for Toronto shows that the sun is expected to make an appearance on January 16, 2024, with intermittent clouds throughout the day and mostly cloudy conditions at night, but no precipitation.",
            "response": {
                "DailyForecasts": [
                    {
                        "Date": "2024-01-13T07:00:00-05:00",
                        "Day": {
                            "HasPrecipitation": true,
                            "Icon": 29,
                            "IconPhrase": "Rain and snow",
                            "PrecipitationIntensity": "Light",
                            "PrecipitationType": "Mixed"
                        },
                        "EpochDate": 1705147200,
                        "Link": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=1&unit=c&lang=en-us",
                        "MobileLink": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=1&unit=c&lang=en-us",
                        "Night": {
                            "HasPrecipitation": true,
                            "Icon": 19,
                            "IconPhrase": "Flurries",
                            "PrecipitationIntensity": "Light",
                            "PrecipitationType": "Snow"
                        },
                        "Sources": [
                            "AccuWeather"
                        ],
                        "Temperature": {
                            "Maximum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": 3.0
                            },
                            "Minimum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -5.4
                            }
                        }
                    },
                    {
                        "Date": "2024-01-14T07:00:00-05:00",
                        "Day": {
                            "HasPrecipitation": false,
                            "Icon": 6,
                            "IconPhrase": "Mostly cloudy"
                        },
                        "EpochDate": 1705233600,
                        "Link": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=2&unit=c&lang=en-us",
                        "MobileLink": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=2&unit=c&lang=en-us",
                        "Night": {
                            "HasPrecipitation": false,
                            "Icon": 35,
                            "IconPhrase": "Partly cloudy"
                        },
                        "Sources": [
                            "AccuWeather"
                        ],
                        "Temperature": {
                            "Maximum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -3.3
                            },
                            "Minimum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -10.6
                            }
                        }
                    },
                    {
                        "Date": "2024-01-15T07:00:00-05:00",
                        "Day": {
                            "HasPrecipitation": false,
                            "Icon": 6,
                            "IconPhrase": "Mostly cloudy"
                        },
                        "EpochDate": 1705320000,
                        "Link": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=3&unit=c&lang=en-us",
                        "MobileLink": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=3&unit=c&lang=en-us",
                        "Night": {
                            "HasPrecipitation": true,
                            "Icon": 19,
                            "IconPhrase": "Flurries",
                            "PrecipitationIntensity": "Light",
                            "PrecipitationType": "Snow"
                        },
                        "Sources": [
                            "AccuWeather"
                        ],
                        "Temperature": {
                            "Maximum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -6.7
                            },
                            "Minimum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -10.9
                            }
                        }
                    },
                    {
                        "Date": "2024-01-16T07:00:00-05:00",
                        "Day": {
                            "HasPrecipitation": false,
                            "Icon": 4,
                            "IconPhrase": "Intermittent clouds"
                        },
                        "EpochDate": 1705406400,
                        "Link": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=4&unit=c&lang=en-us",
                        "MobileLink": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=4&unit=c&lang=en-us",
                        "Night": {
                            "HasPrecipitation": false,
                            "Icon": 38,
                            "IconPhrase": "Mostly cloudy"
                        },
                        "Sources": [
                            "AccuWeather"
                        ],
                        "Temperature": {
                            "Maximum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -6.9
                            },
                            "Minimum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -12.5
                            }
                        }
                    },
                    {
                        "Date": "2024-01-17T07:00:00-05:00",
                        "Day": {
                            "HasPrecipitation": false,
                            "Icon": 7,
                            "IconPhrase": "Cloudy"
                        },
                        "EpochDate": 1705492800,
                        "Link": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=5&unit=c&lang=en-us",
                        "MobileLink": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?day=5&unit=c&lang=en-us",
                        "Night": {
                            "HasPrecipitation": false,
                            "Icon": 38,
                            "IconPhrase": "Mostly cloudy"
                        },
                        "Sources": [
                            "AccuWeather"
                        ],
                        "Temperature": {
                            "Maximum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -6.9
                            },
                            "Minimum": {
                                "Unit": "C",
                                "UnitType": 17,
                                "Value": -8.1
                            }
                        }
                    }
                ],
                "Headline": {
                    "Category": "snow/rain",
                    "EffectiveDate": "2024-01-12T19:00:00-05:00",
                    "EffectiveEpochDate": 1705104000,
                    "EndDate": "2024-01-14T07:00:00-05:00",
                    "EndEpochDate": 1705233600,
                    "Link": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?unit=c&lang=en-us",
                    "MobileLink": "http://www.accuweather.com/en/ca/toronto/m5h/daily-weather-forecast/55488?unit=c&lang=en-us",
                    "Severity": 2,
                    "Text": "Snow, mixed with rain at times continuing through late tonight and a storm total of 6-12 cm"
                }
            },
            "tool": "AccuWeather Daily Forecast"
        }
        
        """
        if let data = dummyData.data(using: .utf8) {
            handleResponse(data)
        }
    }
    
    func escapeControlCharacters(in jsonString: String) -> String {
        var escapedString = jsonString
        let controlChars = ["\n": "\\n", "\r": "\\r", "\t": "\\t"]
        controlChars.forEach { (char, escapeChar) in
            escapedString = escapedString.replacingOccurrences(of: char, with: escapeChar)
        }
        return escapedString
    }

    
    func handleResponse(_ data: Data) {
        do {
            // Print the raw JSON string
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("Raw JSON Response: \(rawJSONString)")
            }
            
            
            
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonDict = json as? [String: Any], let tool = jsonDict["tool"] as? String {
                switch tool {
                
                case "IMDb Showtimes":
                    let response = try JSONDecoder().decode(MovieShowtimesResponse.self, from: data)
                    let finalAnswer = response.final_answer // Extract the final answer
                    TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }

                    addMessage(.movieShowtimes(response))
                case "TMDB-API":
                    let response = try JSONDecoder().decode(MovieInfoResponse.self, from: data)
                    print("TMDB response received")
                    print("response =",response)
                    let finalAnswer = response.final_answer // Extract the final answer
           /*         TextToSpeechManager.generateAudioFromText(text: final_answer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }
*/
                    addMessage(.movieInfo(response))
                case "Maps Directions":
                    let response = try JSONDecoder().decode(MapGeneratorResponse.self, from: data)
                    addMessage(.mapGenerator(response))
                    handleNonTTSResponse()
                case "Google Search":
                     let response = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
                    let finalAnswer = response.final_answer // Extract the final answer
                    TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }

                     addMessage(.googleSearch(response))
                case "Wikipedia":
                    print("received wiki response")
                    let response = try JSONDecoder().decode(WikipediaResponse.self, from: data)
                    let finalAnswer = response.final_answer // Extract the final answer
                    TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }

                    addMessage(.wikipedia(response))
                case "AccuWeather Hourly Forecast":
                    let response = try JSONDecoder().decode(HourlyForecastResponse.self, from: data)
                    let finalAnswer = response.final_answer // Extract the final answer
                    TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }

                    addMessage(.hourlyForecast(response))
                case "AccuWeather Daily Forecast":
                    let response = try JSONDecoder().decode(DailyForecastResponse.self, from: data)
                    let finalAnswer = response.finalAnswer // Extract the final answer
                    TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }

                    addMessage(.dailyForecast(response))
                case "Google Serper Places":
                    let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
                    let finalAnswer = response.finalAnswer // Extract the final answer
                    TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                        switch result {
                        case .success(let audioData):
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = false // Set to false before playing audio
                            }
                            TextToSpeechManager.playAudio(audioData) {
                                DispatchQueue.main.async {
                                    self.isButtonInSendMode = true // Set back to true after audio finishes
                                }
                            }
                        case .failure(let error):
                            print("TTS Error: \(error)")
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true if there's an error
                            }
                        }
                    }

                    addMessage(.places(response))
                case "Image Search":
                    let response = try JSONDecoder().decode(ImagesResponse.self, from: data)
                    addMessage(Message(type: .imageSearch(response), isSentByUser: false))
                    handleNonTTSResponse()
                default:
                    addMessage(.text("Unsupported tool type"))
                    handleNonTTSResponse()
                }
            } else {
                            // Handle the plain chat response
                            let response = try JSONDecoder().decode(ChatResponse.self, from: data)
                            let finalAnswer = response.final_answer // Extract the final answer
                
                TextToSpeechManager.generateAudioFromText(text: finalAnswer) { result in
                    switch result {
                    case .success(let audioData):
                        DispatchQueue.main.async {
                            self.isButtonInSendMode = false // Set to false before playing audio
                        }
                        TextToSpeechManager.playAudio(audioData) {
                            DispatchQueue.main.async {
                                self.isButtonInSendMode = true // Set back to true after audio finishes
                            }
                        }
                    case .failure(let error):
                        print("TTS Error: \(error)")
                        DispatchQueue.main.async {
                            self.isButtonInSendMode = true // Set back to true if there's an error
                        }
                    }
                }

                            addMessage(.chat(response))
                        }
        } catch {
            print("Error parsing response: \(error)")
        }
    }
    
    private func addMessage(_ messageType: MessageType) {
        DispatchQueue.main.async {
            self.messages.append(Message(type: messageType, isSentByUser: false))
        }
    }
    
    func handleNonTTSResponse() {
        DispatchQueue.main.async {
            self.isButtonInSendMode = true
        }
    }
    
    func sendQuery(_ query: String, completion: @escaping () -> Void) {
        // Create a Message object with the query
      
              // Check if the query is not empty
              guard !query.isEmpty else { return }

              // Create a Message object with the query
              let message = Message(type: .text(query), isSentByUser: true)
              addMessage(message)

        
        guard let url = URL(string: "https://spotserver-43558f9aebfe.herokuapp.com/query") else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                // Print the raw JSON response as a string for debugging
                if let rawJSONString = String(data: data, encoding: .utf8) {
                   // print("Raw JSON Response: \(rawJSONString)")
                }
                
                // Use handleResponse to process the data
                print("sending to response handler")
                self.handleResponse(data)
                completion()
            }
        }.resume()
    }
}
struct ServerResponse: Codable {
    var action: String
    var actionInput: String

    enum CodingKeys: String, CodingKey {
        case action
        case actionInput = "action_input"
    }
}
