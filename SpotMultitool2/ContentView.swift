//
//  ContentView.swift
//  GearMultiTool
//
//  Created by Steve Cutler on 2024-01-09.
//


import SwiftUI
import WatchConnectivity


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
}



    struct ContentView: View {
        @State private var query: String = ""
        @ObservedObject var viewModel = ChatViewModel()
        @State private var scrollToBottomID = UUID()
        @State private var isImageSheetPresented = false
        @State private var isButtonInSendMode = true // State to track button mode
        @State private var isRecording = false
        @State private var isPressed = false

    
        
        var body: some View {
              ZStack {
                  Color(hex: "#fcfcf0").edgesIgnoringSafeArea(.all)

                  VStack {
                      ScrollViewReader { scrollView in
                          ScrollView {
                              VStack(alignment: .leading, spacing: 10) {
                                  ForEach(viewModel.messages) { message in
                                      MessageView(message: message)
                                          .id(message.id) // Assign an ID to each message
                                  }
                              }
                              .onChange(of: viewModel.messages.count) { _ in
                                  scrollToBottom(scrollView: scrollView)
                              }
                          }
                      }

                      HStack {
                          ExpandingTextEditor(text: $query)
                              .padding(4)
                              .background(Color(hex: "#fcfcf0"))
                              .cornerRadius(10)
                              .overlay(
                                  RoundedRectangle(cornerRadius: 10)
                                      .stroke(Color.secondary, lineWidth: 1)
                              )

                          Button(action: {
                                                    if !query.isEmpty {
                                                        viewModel.sendQuery(query) {
                                                            // Add any actions you want to perform after the query is sent here
                                                            // If there's nothing to do, you can leave this empty
                                                        }
                                                        query = ""
                                                    } else if TextToSpeechManager.isAudioPlaying() {
                                                        TextToSpeechManager.stopAudio()
                                                    }
                                                }) {
                                                    Text(buttonLabel)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.white)
                                                        .frame(width: 30, height: 30)
                                                        .padding(.vertical, 20)
                                                        .padding(.horizontal, 20)
                                                        .background(buttonColor)
                                                        .cornerRadius(20)
                                                        .shadow(radius: 5)
                                                }
                                                .disabled(query.isEmpty && !isRecording && !TextToSpeechManager.isAudioPlaying())
                                                .simultaneousGesture(
                                                    LongPressGesture(minimumDuration: .infinity)
                                                        .onChanged { _ in
                                                            if query.isEmpty && !TextToSpeechManager.isAudioPlaying() {
                                                                startRecording()
                                                            }
                                                        }
                                                        .onEnded { _ in
                                                            if isRecording {
                                                                stopRecording()
                                                            }
                                                        }
                                                )

                                                                }.padding()
                  }
              }
              .onChange(of: viewModel.messages.count) { _ in
                  scrollToBottomID = UUID() // Update ID on new message
              }
          }
        
    


        private var buttonLabel: String {
            if isRecording {
                return ""
            } else if TextToSpeechManager.isAudioPlaying() {
                return ""
            } else {
                return ""
            }
        }

        private var buttonColor: Color {
            if isRecording {
                return Color.green
            } else if TextToSpeechManager.isAudioPlaying() {
                return Color.red
            } else {
                return Color.blue
            }
        }
        
        private func startRecording() {
               // Start recording logic
               isRecording = true
               viewModel.audioRecorderManager.startRecording()
           }
        private func stopRecording() {
            // Stop recording logic
            isRecording = false
            viewModel.audioRecorderManager.stopRecording()
            // Handle the recording file, transcribe and send the query
            print("preparing to send to whisper")
            if let recordingURL = viewModel.audioRecorderManager.currentRecordingURL {
                print("check")
                WhisperManager.shared.transcribeAudio(at: recordingURL) {  transcription in
                    if let transcription = transcription {
                        DispatchQueue.main.async {
                            print("sending transcription to server")
                           // self.query = transcription
                            self.viewModel.sendQuery(transcription) {
                                // Handle completion if needed
                            }
                        }
                    }
                }
            }
        }

        
          private func scrollToBottom(scrollView: ScrollViewProxy) {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  withAnimation {
                      scrollView.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                  }
              }
          }
      }

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isSentByUser {
                Spacer()
            }
            content
                .padding()
                .background(message.isSentByUser ? Color(hex: "#4a3432") : Color(hex: "#292b32")) // Differentiate color here
                .cornerRadius(10)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            if !message.isSentByUser {
                Spacer()
            }
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    var content: some View {
        switch message.type {
        case .text(let text):
            Text(text)
        
        case .chat(let response):
            ChatResponseView(response: response)
            

        case .imageSearch(let response):
            ImagesGridView(images: response.final_answer.images)
            
        case .movieShowtimes(let response):
            MovieShowtimesView(response: response)

        case .movieInfo(let response):
            // Assuming you want to display the first movie in the response
            if let firstMovie = response.response.first {
                MovieDetailView(movieResponse: firstMovie)
            } else {
                // Handle the case where there are no movies in the response
                Text("No movie details available")
            }


        case .mapGenerator(let response):
            MapGeneratorView(mapResponse: response)


        case .googleSearch(let response):
            GoogleSearchView(response: response)

        case .wikipedia(let response):
            WikipediaView(response: response)

        case .hourlyForecast(let response):
            HourlyForecastView(response: response)

        case .dailyForecast(let response):
            DailyForecastView(response: response)

        case .places(let response):
            PlacesView(response: response)
            
     
        }
    }
}


struct ExpandingTextEditor: View {
    @Binding var text: String
    @State private var dynamicHeight: CGFloat = 40 // Initial height for single line

    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
            .onChange(of: text) { _ in
                dynamicHeight = calculateHeight()
            }
            .onAppear {
                dynamicHeight = calculateHeight()
            }
    }

    private func calculateHeight() -> CGFloat {
        let textView = UITextView()
        textView.text = text
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        let size = textView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 50, height: CGFloat.infinity))
        return size.height
    }
}

struct ChatResponseView: View {
    let response: ChatResponse
    
    var body: some View{
        Text(response.final_answer)
            .font(.headline)
            .padding(.bottom, 5)
    }
}



struct CustomImageView: View {
    let imageData: ImageData

    var body: some View {
        VStack(alignment: .leading) {
            Text(imageData.title)
                .font(.headline)
                .padding(.bottom, 5)

            Link(destination: URL(string: imageData.sourceUrl) ?? URL(string: "https://example.com")!) {
                AsyncImage(url: URL(string: imageData.imageUrl)) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 300)
            }

            if let url = URL(string: imageData.sourceUrl) {
                Text(url.host ?? url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.purple)
        .cornerRadius(10)
        .foregroundColor(.white)
        .padding(.horizontal, 20)
    }
}
struct ImagesGridView: View {
    let images: [ImagesResponse.ImageInfo]
    
    struct ImageURL: Identifiable {
        var id = UUID()
        var url: URL
    }
    
    @State private var selectedImageURL: ImageURL?

    let bubbleColors: [Color] = [Color(hex: "#4a3432"), Color(hex: "#8f6c49"), Color(hex: "#e07e3d"), Color(hex: "#ebe5d5")]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                ForEach(images, id: \.imageUrl) { imageInfo in
                    VStack {
                        Button(action: {
                            selectedImageURL = ImageURL(url: URL(string: imageInfo.imageUrl)!)
                        }) {
                            ImageView(url: URL(string: imageInfo.imageUrl)!)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(contentMode: .fit)
                                .background(Color(hex: "#ebe5d5"))
                                .cornerRadius(10) // Set corner radius here
                                .padding(.bottom, 5)
                        }

                        Link(destination: URL(string: imageInfo.sourceUrl)!) {
                            Text(imageInfo.title)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, 5)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(5)
                    .background(interpolatedColor(for: imageInfo))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .fullScreenCover(item: $selectedImageURL) { imageUrl in
            AsyncImage(url: imageUrl.url) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .aspectRatio(contentMode: .fit)
            .ignoresSafeArea()
            .onTapGesture {
                selectedImageURL = nil
            }
        
    }
}







    // Function to interpolate color based on image index
    private func interpolatedColor(for imageInfo: ImagesResponse.ImageInfo) -> Color {
        guard let index = images.firstIndex(where: { $0.imageUrl == imageInfo.imageUrl }) else {
            return .gray // Default color if image not found
        }

        let startColor = bubbleColors[index % bubbleColors.count]
        let endColor = bubbleColors[(index + 1) % bubbleColors.count]

        let interpolationFactor = CGFloat(index % bubbleColors.count) / CGFloat(bubbleColors.count)
        return interpolateColor(startColor, endColor, factor: interpolationFactor)
    }

    // Custom color interpolation function
    private func interpolateColor(_ startColor: Color, _ endColor: Color, factor: CGFloat) -> Color {
        var startRed: CGFloat = 0
        var startGreen: CGFloat = 0
        var startBlue: CGFloat = 0
        var startAlpha: CGFloat = 0
        var endRed: CGFloat = 0
        var endGreen: CGFloat = 0
        var endBlue: CGFloat = 0
        var endAlpha: CGFloat = 0

        UIColor(startColor).getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        UIColor(endColor).getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

        let interpolatedRed = startRed + factor * (endRed - startRed)
        let interpolatedGreen = startGreen + factor * (endGreen - startGreen)
        let interpolatedBlue = startBlue + factor * (endBlue - startBlue)
        let interpolatedAlpha = startAlpha + factor * (endAlpha - startAlpha)

        return Color(UIColor(red: interpolatedRed, green: interpolatedGreen, blue: interpolatedBlue, alpha: interpolatedAlpha))
    }
}




struct ImageView: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable()
        } placeholder: {
            ProgressView()
        }
        .aspectRatio(contentMode: .fit)
    }
}


struct ImagesResponse: Codable {
    let final_answer: ImageResponse
    let response: ImageResponse
    let tool: String

    struct ImageResponse: Codable {
        let images: [ImageInfo]
    }

    struct ImageInfo: Codable {
        let imageUrl: String
        let sourceUrl: String
        let title: String
    }
}

/*
struct MovieShowtimesResponse: Codable {
    let final_answer: String
    let response: [Movie]
    let tool: String

    struct Movie: Codable {
        let imdbPageURL: String
        let movie: String
        let posterURL: String
        let showtimes: [String]
        let theatre: String
        
        enum CodingKeys: String, CodingKey {
            case imdbPageURL = "imdb_page_url"
            case movie
            case posterURL = "poster_url"
            case showtimes
            case theatre
        }
    }
}
 */
struct MovieShowtimesView: View {
    let response: MovieShowtimesResponse

    let bubbleColors: [Color] = [Color(hex: "#4a3432"), Color(hex: "#8f6c49"), Color(hex: "#e07e3d"), Color(hex: "#ebe5d5")]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading ) {
                if let firstMovie = response.response.first {
                    Text("Movie Showtimes at \(firstMovie.theatre.uppercased())")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding()
                }

                ForEach(response.response) { movie in
                    // Outer VStack to center the bubble
                    VStack {
                        // Bubble VStack
                        VStack {
                            Text(movie.movie.uppercased())
                                .font(.title3)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center) // Center-align text

                            HStack (spacing: 30){
                                VStack{
                                    if let url = URL(string: movie.posterURL) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 67, height: 98)
                                        .cornerRadius(8)
                                        .shadow(radius: 3)
                                    }
                                 
                                    if let imdbURL = URL(string: movie.imdbPageURL) {
                                                                Link(destination: imdbURL) {
                                                                    Image("imdb-logo-small") // Replace "imdb_logo" with your image name in the asset library
                                                                        .resizable()
                                                                        .scaledToFit()
                                                                        .frame(height: 30) // Adjust the size as needed
                                                                }
                                                            }
                                    
                                }

                                VStack(alignment: .leading) {
                                    ForEach(movie.showtimes, id: \.self) { showtime in
                                        Text(showtime)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .padding(.vertical, 2)
                                    }
                                }
                            }
                            
                           
                        }
                        .padding()
                        .background(interpolatedColor(for: movie))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .frame(maxWidth: .infinity) // Outer VStack takes full width
                }
            }
        }
    }



     // Function to interpolate color based on movie
     private func interpolatedColor(for movie: MovieShowtimesResponse.Movie) -> Color {
         guard let index = response.response.firstIndex(where: { $0.movie == movie.movie }) else {
             return .gray // Default color if movie not found
         }

         let startColor = bubbleColors[index % bubbleColors.count]
         let endColor = bubbleColors[(index + 1) % bubbleColors.count]

         let interpolationFactor = CGFloat(index % bubbleColors.count) / CGFloat(bubbleColors.count)
         return interpolateColor(startColor, endColor, factor: interpolationFactor)
     }

     // Custom color interpolation function
     private func interpolateColor(_ startColor: Color, _ endColor: Color, factor: CGFloat) -> Color {
         var startRed: CGFloat = 0
         var startGreen: CGFloat = 0
         var startBlue: CGFloat = 0
         var startAlpha: CGFloat = 0
         var endRed: CGFloat = 0
         var endGreen: CGFloat = 0
         var endBlue: CGFloat = 0
         var endAlpha: CGFloat = 0

         UIColor(startColor).getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
         UIColor(endColor).getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

         let interpolatedRed = startRed + factor * (endRed - startRed)
         let interpolatedGreen = startGreen + factor * (endGreen - startGreen)
         let interpolatedBlue = startBlue + factor * (endBlue - startBlue)
         let interpolatedAlpha = startAlpha + factor * (endAlpha - startAlpha)

         return Color(UIColor(red: interpolatedRed, green: interpolatedGreen, blue: interpolatedBlue, alpha: interpolatedAlpha))
     }
 }

struct MovieDetailView: View {
    let movieResponse: MovieResponse
    @State private var isShowingFullSizePoster = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(movieResponse.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                let fullPosterURL = "https://image.tmdb.org/t/p/original" + movieResponse.poster_url

                
                if let posterURL = URL(string: fullPosterURL) {
                                    Button(action: {
                                        isShowingFullSizePoster = true
                                    }) {
                                        AsyncImage(url: posterURL) {
                                            $0.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 200, height: 300)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                    }
                                    .sheet(isPresented: $isShowingFullSizePoster) {
                                        // Full-size image view
                                        AsyncImage(url: posterURL) {
                                            $0.resizable()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .aspectRatio(contentMode: .fit)
                                        .padding()
                                    }
                                }

                Text("Release Date: \(movieResponse.release_date)")
                    .font(.headline)

                Text(movieResponse.overview)
                    .font(.body)

                Text("Runtime: \(movieResponse.details.runtime) minutes")
                    .font(.subheadline)

                Text("Genres: \(movieResponse.details.genres.map { $0.name }.joined(separator: ", "))")
                    .font(.subheadline)

                    //       Text("Tagline: \(movieResponse.details.tagline)")
                   // .font(.subheadline)

                if !movieResponse.details.production_companies.isEmpty {
                    Text("Production Companies: \(movieResponse.details.production_companies.map { $0.name }.joined(separator: ", "))")
                        .font(.subheadline)
                }

                if movieResponse.details.budget > 0 {
                    Text("Budget: $\(movieResponse.details.budget)")
                        .font(.subheadline)
                }

                if movieResponse.details.revenue > 0 {
                    Text("Revenue: $\(movieResponse.details.revenue)")
                        .font(.subheadline)
                }

                Text("Spoken Languages: \(movieResponse.details.spoken_languages.map { $0.english_name }.joined(separator: ", "))")
                    .font(.subheadline)

                Text("Recommendations")
                    .font(.headline)
                    .padding(.top, 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(movieResponse.recommendations, id: \.self) { recommendation in
                            Text(recommendation)
                                .padding(5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
struct MapGeneratorView: View {
    let mapResponse: MapGeneratorResponse

    var body: some View {
        VStack(alignment: .center) {
            (Text("Here are your Directions from\n") +
             Text("'\(mapResponse.finalAnswer.origin)'").bold() +
             Text(" \nto\n") +
             Text("'\(mapResponse.finalAnswer.destination)'").bold())
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()

            HStack(alignment: .center, spacing: 30) {
                if let googleMapsURL = URL(string: mapResponse.finalAnswer.googleMapsUrl) {
                    Link(destination: googleMapsURL) {
                        Image("googleMaps_logo") // Ensure this is the correct name in your asset catalog
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                }
                
                if let appleMapsURL = URL(string: mapResponse.finalAnswer.appleMapsUrl) {
                    Link(destination: appleMapsURL) {
                        Image("AppleMaps_logo.svg") // Ensure this is the correct name in your asset catalog
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                    
                }
            }
            .padding(.bottom, 10)

                               // Additional Text
                               Text("(click for maps)")
                                   .font(.subheadline)
                                   .fontWeight(.bold)
                                   .multilineTextAlignment(.center)
                           
                
            
        }
    }
}


struct GoogleSearchView: View {
    let response: GoogleSearchResponse
    let bubbleColors: [Color] = [Color(hex: "#4a3432"), Color(hex: "#8f6c49"), Color(hex: "#e07e3d"), Color(hex: "#ebe5d5")]

    @State private var isSearchResultsExpanded: Bool = false
    @State private var isPeopleAlsoAskExpanded: Bool = false
    @State private var isRelatedSearchesExpanded: Bool = false
    @State private var isAnswerBoxExpanded: Bool = true // or false, depending on default behavior
    @State private var isTopStoriesExpanded: Bool = false
    
    var body: some View {
           ScrollView {
               VStack(alignment: .leading, spacing: 10) {
                   Text(response.final_answer)
                       .font(.headline)
                       .padding()
                   
                   if let answerBox = response.response.answerBox {
                       DisclosureGroup {
                           VStack(alignment: .leading) {
                               // Check if title is available
                               if let title = answerBox.title {
                                   Text(title)
                                       .font(.headline)
                                       .foregroundColor(.blue)
                               }

                               // Check if snippet is available
                               if let snippet = answerBox.snippet {
                                   Text(snippet)
                                       .font(.subheadline)
                               } else {
                                   Text("No additional details available.")
                                       .font(.subheadline)
                                       .italic()
                               }

                               // Check if link is available and valid
                               if let linkString = answerBox.link, let url = URL(string: linkString) {
                                   Link(destination: url) {
                                       Text("Read more")
                                           .underline()
                                           .font(.subheadline)
                                           .foregroundColor(.blue)
                                   }
                               }
                           }
                       } label: {
                           Text("Answer Box")
                               .font(.title2)
                               .fontWeight(.bold)
                               .foregroundColor(.white)
                               .frame(maxWidth: .infinity)
                               .background(Color(hex: "#8f6c49"))
                               .cornerRadius(15)
                       }
                       .padding()
                       .background(Color(hex: "#8f6c49"))
                       .cornerRadius(15)
                   }

                   
             
                   if let topStories = response.response.topStories, !topStories.isEmpty {
                       DisclosureGroup(isExpanded: $isTopStoriesExpanded) {
                           ForEach(topStories.indices, id: \.self) { index in
                               let story = topStories[index]
                               topStoryBubble(story: story, color: bubbleColors[index % bubbleColors.count])
                           }
                       } label: {
                           Text("Top Stories")
                               .font(.title2)
                               .fontWeight(.bold)
                               .foregroundColor(.white)
                               .frame(maxWidth: .infinity)
                               .background(Color(hex: "#4a3432"))
                               .cornerRadius(15)
                       }
                       .padding()
                       .background(Color(hex: "#4a3432"))
                       .cornerRadius(15)
                   }
                   
                   
                DisclosureGroup{
                                  ForEach(response.response.organic.indices, id: \.self) { index in
                                      let result = response.response.organic[index]
                                      Button(action: { openURL(result.link) }) {
                                          bubbleView(title: result.title, snippet: result.snippet, color: interpolatedColor(for: index))
                                      }
                                  }
                } label: {
                    // Customized label for the disclosure group
                    Text("Search Results")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white) // Text color
                        .frame(maxWidth: .infinity) // Make the label take full width
                  //      .padding() // Add padding around the text
                //       .background(Color(hex: "#4a3432")) // Background color
                        .cornerRadius(15) // Optional: Rounded corners
                }
                .padding()
                .background(Color(hex: "#4a3432")) // Background color for the disclosure group
                .cornerRadius(15)
                              


                   if let peopleAlsoAsk = response.response.peopleAlsoAsk, !peopleAlsoAsk.isEmpty {
                       DisclosureGroup(isExpanded: $isPeopleAlsoAskExpanded) {
                           ForEach(peopleAlsoAsk.indices, id: \.self) { index in
                               let question = peopleAlsoAsk[index]
                               // Updated bubbleView call
                               bubbleView(title: question.question ?? "No title", snippet: question.snippet ?? "No details available", color: interpolatedColor(for: index))
                           }
                       } label: {
                           HStack {
                               Text("People Also Ask")
                                   .font(.title2)
                                   .fontWeight(.bold)
                                   .foregroundColor(.white)
                                   .frame(maxWidth: .infinity)
                           }
                           .background(Color(hex: "#e1e1e1"))
                           .cornerRadius(15)
                       }
                       .padding()
                       .background(Color(hex: "#e1e1e1"))
                       .cornerRadius(15)
                   }


                   if let relatedSearches = response.response.relatedSearches, !relatedSearches.isEmpty {
                       DisclosureGroup(isExpanded: $isRelatedSearchesExpanded) {
                                          ForEach(relatedSearches.indices, id: \.self) { index in
                                              let search = relatedSearches[index]
                                              Button(action: { openURL("https://www.google.com/search?q=\(search.query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") }) {
                                                  bubbleView(title: search.query, snippet: "", color: interpolatedColor(for: index))
                                              }
                                          }
                                      } label: {
                                          HStack {
                               Text("Related Searches")
                                   .font(.title2)
                                   .fontWeight(.bold)
                                   .foregroundColor(.white)
                                   .frame(maxWidth: .infinity)
                               //    Spacer() // Pushes the text to the left
                           }
                           //       .padding()
                           .background(Color(hex: "#e07e3d"))
                           .cornerRadius(15)
                       }
                       .padding()
                       .background(Color(hex: "#e07e3d")) // Match the inner background color
                       .cornerRadius(15)
                   }
                
            }
        }
    }
    
    private func topStoryBubble(story: GoogleSearchResponse.GoogleSearchDetails.TopStory, color: Color) -> some View {
          Group {
              if let url = story.link.flatMap(URL.init) {
                  Link(destination: url) {
                      topStoryContent(story: story)
                  }
              } else {
                  topStoryContent(story: story)
              }
          }
          .padding()
          .background(color)
          .cornerRadius(15)
          .shadow(radius: 5)
      }

      private func topStoryContent(story: GoogleSearchResponse.GoogleSearchDetails.TopStory) -> some View {
          VStack(alignment: .trailing) {
              if let title = story.title {
                  Text(title).fontWeight(.bold)
              }
              if let source = story.source {
                  Text(source).italic()
              }
              if let date = story.date {
                  Text(date).foregroundColor(.gray)
              }
          }
      }
  


    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }

    
    private func bubbleView(title: String, snippet: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
            }
            if !snippet.isEmpty {
                Text(snippet)
                    .font(.subheadline)
            }
        }
        .padding()
        .background(color)
        .cornerRadius(15)
        .shadow(radius: 5)
    }


    private func interpolatedColor(for index: Int) -> Color {
        let startColor = bubbleColors[index % bubbleColors.count]
        let endColor = bubbleColors[(index + 1) % bubbleColors.count]
        let interpolationFactor = CGFloat(index % bubbleColors.count) / CGFloat(bubbleColors.count)
        return interpolateColor(startColor, endColor, factor: interpolationFactor)
    }
    private func interpolateColor(_ startColor: Color, _ endColor: Color, factor: CGFloat) -> Color {
        var startRed: CGFloat = 0
        var startGreen: CGFloat = 0
        var startBlue: CGFloat = 0
        var startAlpha: CGFloat = 0
        var endRed: CGFloat = 0
        var endGreen: CGFloat = 0
        var endBlue: CGFloat = 0
        var endAlpha: CGFloat = 0

        UIColor(startColor).getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        UIColor(endColor).getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

        let interpolatedRed = startRed + factor * (endRed - startRed)
        let interpolatedGreen = startGreen + factor * (endGreen - startGreen)
        let interpolatedBlue = startBlue + factor * (endBlue - startBlue)
        let interpolatedAlpha = startAlpha + factor * (endAlpha - startAlpha)

        return Color(UIColor(red: interpolatedRed, green: interpolatedGreen, blue: interpolatedBlue, alpha: interpolatedAlpha))
    }
}



/*
struct WikipediaResponse: Codable {
    let final_answer: String
    let image_url: String
    let page_url: String
    let response: String
    let tool: String
}
*/
struct WikipediaView: View {
    let response: WikipediaResponse
    @State private var isImageSheetPresented = false

    var body: some View {
        VStack(alignment: .leading) {
            // Display the image as a thumbnail if available
            if let imageUrlString = response.image_url,
               let imageUrl = URL(string: imageUrlString) {
                Button(action: {
                    isImageSheetPresented = true
                }) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 250, maxHeight: 250)
                    .padding(10)
                }
                .sheet(isPresented: $isImageSheetPresented) {
                    // Full-screen image view
                    if let fullImageUrl = URL(string: imageUrlString) {
                        AsyncImage(url: fullImageUrl) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .aspectRatio(contentMode: .fit)
                    }
                }
            }

            // Display the response text
            Text(response.final_answer)
                .font(.headline)
                .padding(.bottom, 5)

            Link(destination: URL(string: response.page_url) ?? URL(string: "https://wikipedia.org")!) {
                Text("Check out \(response.tool) for more details")
                    .underline()
                    .font(.headline)
                    .foregroundColor(.white)  // Changed to blue for a more standard link appearance
                    .frame(maxWidth: .infinity)  // Use maximum width
                    .multilineTextAlignment(.center)  // Align text to center
            }
            .padding(.top, 5)
        }
        .padding()  // Added padding for overall view
    }
}


struct HourlyForecastView: View {
    let response: HourlyForecastResponse
    let bubbleColors: [Color] = [Color(hex: "#4a3432"), Color(hex: "#8f6c49"), Color(hex: "#e07e3d"), Color(hex: "#ebe5d5")]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(response.final_answer)
                .font(.headline)
                .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) { // Changed alignment to .top
                    ForEach(response.response, id: \.epochDateTime) { forecast in
                        VStack {
                            HStack(spacing: 15) { // Added spacing between elements
                                Image(systemName: weatherIconName(forecast.weatherIcon))
                                    .resizable() // This makes the image resizable
                                    .scaledToFit()
                                    .frame(width: 60, height: 60) // Increased the frame size
                                VStack(alignment: .leading) {
                                    Text(formatDateTime(forecast.dateTime))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("\(forecast.temperature.value, specifier: "%.1f")°\(forecast.temperature.unit)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("Condition: \(forecast.iconPhrase)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text("🌧️: \(forecast.precipitationProbability)%")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding()
                            .background(interpolatedColor(for: forecast))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func interpolatedColor(for forecast: HourlyForecastResponse.HourlyForecast) -> Color {
        guard let index = response.response.firstIndex(where: { $0.epochDateTime == forecast.epochDateTime }) else {
            return .gray // Default color if forecast not found
        }

        let startColor = bubbleColors[index % bubbleColors.count]
        let endColor = bubbleColors[(index + 1) % bubbleColors.count]

        let interpolationFactor = CGFloat(index % bubbleColors.count) / CGFloat(bubbleColors.count)
        return interpolateColor(startColor, endColor, factor: interpolationFactor)
    }

    // Custom color interpolation function
    private func interpolateColor(_ startColor: Color, _ endColor: Color, factor: CGFloat) -> Color {
        var startRed: CGFloat = 0
        var startGreen: CGFloat = 0
        var startBlue: CGFloat = 0
        var startAlpha: CGFloat = 0
        var endRed: CGFloat = 0
        var endGreen: CGFloat = 0
        var endBlue: CGFloat = 0
        var endAlpha: CGFloat = 0

        UIColor(startColor).getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        UIColor(endColor).getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

        let interpolatedRed = startRed + factor * (endRed - startRed)
        let interpolatedGreen = startGreen + factor * (endGreen - startGreen)
        let interpolatedBlue = startBlue + factor * (endBlue - startBlue)
        let interpolatedAlpha = startAlpha + factor * (endAlpha - startAlpha)

        return Color(UIColor(red: interpolatedRed, green: interpolatedGreen, blue: interpolatedBlue, alpha: interpolatedAlpha))
    }
    

    private func formatDateTime(_ dateTimeString: String) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        if let date = dateFormatter.date(from: dateTimeString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "h a" // "h a" for hour and AM/PM, change format as needed

            let hourString = outputFormatter.string(from: date)
            let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: date)
            let nextHourString = nextHour.map { outputFormatter.string(from: $0) } ?? ""

            return "\(hourString) - \(nextHourString)"
        }

        return dateTimeString // Fallback to original string if parsing fails
    }
    private func weatherIconName(_ iconCode: Int) -> String {
        switch iconCode {
        case 1: // Sunny
            return "sun.max.fill"
        case 2: // Mostly Sunny
            return "cloud.sun.fill"
        case 3: // Partly Sunny
            return "cloud.sun.fill"
        case 4: // Intermittent Clouds
            return "cloud.sun.fill"
        case 5: // Hazy Sunshine
            return "sun.haze.fill"
        case 6: // Mostly Cloudy
            return "cloud.sun.fill"
        case 7: // Cloudy
            return "cloud.fill"
        case 8: // Dreary (Overcast)
            return "cloud.fill"
        case 11: // Fog
            return "cloud.fog.fill"
        case 12: // Showers
            return "cloud.drizzle.fill"
        case 13: // Mostly Cloudy w/ Showers
            return "cloud.rain.fill"
        case 14: // Partly Sunny w/ Showers
            return "cloud.sun.rain.fill"
        case 15: // T-Storms
            return "cloud.bolt.rain.fill"
        case 16: // Mostly Cloudy w/ T-Storms
            return "cloud.bolt.fill"
        case 17: // Partly Sunny w/ T-Storms
            return "cloud.sun.bolt.fill"
        case 18: // Rain
            return "cloud.rain.fill"
        case 19: // Flurries
            return "cloud.snow.fill"
        case 20: // Mostly Cloudy w/ Flurries
            return "cloud.snow.fill"
        case 21: // Partly Sunny w/ Flurries
            return "cloud.sun.snow.fill"
        case 22: // Snow
            return "snowflake"
        case 23: // Mostly Cloudy w/ Snow
            return "cloud.snow.fill"
        case 24: // Ice
            return "thermometer.snowflake"
        case 25: // Sleet
            return "cloud.sleet.fill"
        case 26: // Freezing Rain
            return "cloud.hail.fill"
        case 29: // Rain and Snow
            return "cloud.sun.hail.fill"
        case 30: // Hot
            return "thermometer.sun.fill"
        case 31: // Cold
            return "thermometer.snowflake"
        case 32: // Windy
            return "wind"
        case 33: // Clear (Night)
            return "moon.stars.fill"
        case 34: // Mostly Clear (Night)
            return "cloud.moon.fill"
        case 35: // Partly Cloudy (Night)
            return "cloud.moon.fill"
        case 36: // Intermittent Clouds (Night)
            return "cloud.moon.fill"
        case 37: // Hazy Moonlight
            return "moon.haze.fill"
        case 38: // Mostly Cloudy (Night)
            return "cloud.moon.fill"
        case 39: // Partly Cloudy w/ Showers (Night)
            return "cloud.moon.rain.fill"
        case 40: // Mostly Cloudy w/ Showers (Night)
            return "cloud.moon.rain.fill"
        case 41: // Partly Cloudy w/ T-Storms (Night)
            return "cloud.moon.bolt.fill"
        case 42: // Mostly Cloudy w/ T-Storms (Night)
            return "cloud.moon.bolt.fill"
        case 43: // Mostly Cloudy w/ Flurries (Night)
            return "cloud.moon.snow.fill"
        case 44: // Mostly Cloudy w/ Snow (Night)
            return "cloud.moon.snow.fill"
        default:
            return "questionmark.circle.fill" // Default placeholder for unknown conditions
        }
    }
}
struct DailyForecastView: View {
    let response: DailyForecastResponse

    let bubbleColors: [Color] = [Color(hex: "#4a3432"), Color(hex: "#8f6c49"), Color(hex: "#e07e3d"), Color(hex: "#c4bfb1")]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(response.finalAnswer)
                    .font(.headline)
                    .padding()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) { // Add spacing between bubbles
                        ForEach(response.response.dailyForecasts.indices, id: \.self) { index in
                            let forecast = response.response.dailyForecasts[index]
                            VStack(alignment: .leading) {
                                Text(formattedDate(forecast.date))
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("🌡️: \(String(format: "%.1f", forecast.temperature.maximum.value))°\(forecast.temperature.maximum.unit) / \(String(format: "%.1f", forecast.temperature.minimum.value))°\(forecast.temperature.minimum.unit)")

                                HStack {
                                    VStack(alignment: .leading) {
                                        Image(systemName: weatherIconName(forecast.day.icon))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                        Text("Day: \n\(forecast.day.iconPhrase)")
                                        if forecast.day.hasPrecipitation {
                                            Text("🌧️: \(forecast.day.precipitationType ?? "N/A")")
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .leading) {
                                        Image(systemName: weatherIconName(forecast.night.icon))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                        Text("Night: \n\(forecast.night.iconPhrase)")
                                        if forecast.night.hasPrecipitation {
                                            Text("🌧️: \(forecast.night.precipitationType ?? "N/A")")
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(bubbleColors[index % bubbleColors.count])
                            .cornerRadius(10)
                            .shadow(radius: 2)
                        }
                    }
                }
            }
        }
    }




    private func formattedDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            // Set your desired date format here
            outputFormatter.dateFormat = "EEEE, MMMM dd" // Example: "Tuesday, January 14"
            return outputFormatter.string(from: date)
        }
        return dateString
    }

    private func weatherIconName(_ iconCode: Int) -> String {
        switch iconCode {
        case 1: // Sunny
            return "sun.max.fill"
        case 2: // Mostly Sunny
            return "cloud.sun.fill"
        case 3: // Partly Sunny
            return "cloud.sun.fill"
        case 4: // Intermittent Clouds
            return "cloud.sun.fill"
        case 5: // Hazy Sunshine
            return "sun.haze.fill"
        case 6: // Mostly Cloudy
            return "cloud.sun.fill"
        case 7: // Cloudy
            return "cloud.fill"
        case 8: // Dreary (Overcast)
            return "cloud.fill"
        case 11: // Fog
            return "cloud.fog.fill"
        case 12: // Showers
            return "cloud.drizzle.fill"
        case 13: // Mostly Cloudy w/ Showers
            return "cloud.rain.fill"
        case 14: // Partly Sunny w/ Showers
            return "cloud.sun.rain.fill"
        case 15: // T-Storms
            return "cloud.bolt.rain.fill"
        case 16: // Mostly Cloudy w/ T-Storms
            return "cloud.bolt.fill"
        case 17: // Partly Sunny w/ T-Storms
            return "cloud.sun.bolt.fill"
        case 18: // Rain
            return "cloud.rain.fill"
        case 19: // Flurries
            return "cloud.snow.fill"
        case 20: // Mostly Cloudy w/ Flurries
            return "cloud.snow.fill"
        case 21: // Partly Sunny w/ Flurries
            return "cloud.sun.snow.fill"
        case 22: // Snow
            return "snowflake"
        case 23: // Mostly Cloudy w/ Snow
            return "cloud.snow.fill"
        case 24: // Ice
            return "thermometer.snowflake"
        case 25: // Sleet
            return "cloud.sleet.fill"
        case 26: // Freezing Rain
            return "cloud.hail.fill"
        case 29: // Rain and Snow
            return "cloud.sun.hail.fill"
        case 30: // Hot
            return "thermometer.sun.fill"
        case 31: // Cold
            return "thermometer.snowflake"
        case 32: // Windy
            return "wind"
        case 33: // Clear (Night)
            return "moon.stars.fill"
        case 34: // Mostly Clear (Night)
            return "cloud.moon.fill"
        case 35: // Partly Cloudy (Night)
            return "cloud.moon.fill"
        case 36: // Intermittent Clouds (Night)
            return "cloud.moon.fill"
        case 37: // Hazy Moonlight
            return "moon.haze.fill"
        case 38: // Mostly Cloudy (Night)
            return "cloud.moon.fill"
        case 39: // Partly Cloudy w/ Showers (Night)
            return "cloud.moon.rain.fill"
        case 40: // Mostly Cloudy w/ Showers (Night)
            return "cloud.moon.rain.fill"
        case 41: // Partly Cloudy w/ T-Storms (Night)
            return "cloud.moon.bolt.fill"
        case 42: // Mostly Cloudy w/ T-Storms (Night)
            return "cloud.moon.bolt.fill"
        case 43: // Mostly Cloudy w/ Flurries (Night)
            return "cloud.moon.snow.fill"
        case 44: // Mostly Cloudy w/ Snow (Night)
            return "cloud.moon.snow.fill"
        default:
            return "questionmark.circle.fill" // Default placeholder for unknown conditions
        }
    }
}

struct PlacesView: View {
    let response: PlacesResponse

    var body: some View {
        VStack {
            Text(response.finalAnswer)
            // Display places details
        }
    }
}

//
//  MovieShowtimes.swift
//  GearMultiTool
//
//  Created by Steve Cutler on 2024-01-11.
//



struct MovieShowtimesResponse: Codable {
    let final_answer: String
    let response: [Movie]
    let tool: String

    struct Movie: Codable, Identifiable {
        let id = UUID() // Unique identifier for Identifiable
        let imdbPageURL: String
        let movie: String
        let posterURL: String
        let showtimes: [String]
        let theatre: String
        
        enum CodingKeys: String, CodingKey {
            case imdbPageURL = "imdb_page_url"
            case movie
            case posterURL = "poster_url"
            case showtimes
            case theatre
        }
    }
}

struct ChatResponse: Codable {
    let final_answer: String
}
struct MovieInfoResponse: Codable {
    let final_answer: [MovieResponse]
    let response: [MovieResponse]
    let tool: String
}

struct MovieResponse: Codable {
    let details: MovieDetails
    let overview: String
    let poster_url: String
    let recommendations: [String]
    let release_date: String
    let title: String
}

struct MovieDetails: Codable {
    let adult: Bool
    let backdrop_path: String?
    let budget: Int
    let genres: [Genre]
    let homepage: String?
    let id: Int
    let imdb_id: String
    let original_language: String
    let original_title: String
    let overview: String
    let popularity: Double
    let poster_path: String?
    let production_companies: [ProductionCompany]
    let production_countries: [ProductionCountry]
    let release_date: String
    let revenue: Int
    let runtime: Int
    let spoken_languages: [SpokenLanguage]
    let status: String
    let tagline: String?
    let title: String
    let video: Bool
    let vote_average: Double
    let vote_count: Int
}

struct ProductionCompany: Codable {
    let id: Int
    let logo_path: String?
    let name: String
    let origin_country: String
}

struct ProductionCountry: Codable {
    let iso_3166_1: String
    let name: String
}

struct SpokenLanguage: Codable {
    let english_name: String
    let iso_639_1: String
    let name: String
}

struct Genre: Codable {
    let id: Int
    let name: String
}

// Define other nested structs like ProductionCompany, ProductionCountry, SpokenLanguage, etc.


struct MapGeneratorResponse: Codable {
    let finalAnswer: DirectionsInfo
    let response: DirectionsInfo
    let tool: String

    enum CodingKeys: String, CodingKey {
        case finalAnswer = "final_answer"
        case response
        case tool
    }
}

struct DirectionsInfo: Codable {
    let appleMapsUrl: String
    let destination: String
    let googleMapsUrl: String
    let origin: String

    enum CodingKeys: String, CodingKey {
        case appleMapsUrl = "apple_maps_url"
        case destination
        case googleMapsUrl = "google_maps_url"
        case origin
    }
}


struct GoogleSearchResponse: Codable {
    let final_answer: String
    let response: GoogleSearchDetails
    let tool: String

    struct GoogleSearchDetails: Codable {
        let searchParameters: SearchParameters
        let answerBox: AnswerBox?
        let organic: [OrganicResult]
        let peopleAlsoAsk: [PeopleAlsoAsk]?
        let relatedSearches: [RelatedSearch]?
        let topStories: [TopStory]?

        struct TopStory: Codable {
            let date: String?
            let imageUrl: String?
            let link: String?
            let source: String?
            let title: String?
        }

        struct AnswerBox: Codable {
            let snippet: String?
            let title: String?
            let link: String?
        }

        struct SearchParameters: Codable {
            let q: String
            let gl: String
            let hl: String
            let num: Int
            let type: String
            let engine: String
        }

        struct OrganicResult: Codable {
            let title: String
            let link: String
            let snippet: String
            let position: Int
            let date: String?
            let sitelinks: [SiteLink]?
            
            struct SiteLink: Codable {
                let title: String
                let link: String
            }
        }

        struct PeopleAlsoAsk: Codable {
            let question: String?
            let snippet: String?
            let title: String?
            let link: String?
        }

        struct RelatedSearch: Codable {
            let query: String
        }
    }
}


struct WikipediaResponse: Codable {
    let final_answer: String
    let image_url: String?  // Make this optional
    let page_url: String
    let response: String
    let tool: String
}


struct HourlyForecastResponse: Codable {
    let final_answer: String
    let response: [HourlyForecast]
    let tool: String

    struct HourlyForecast: Codable {
        let dateTime: String
        let epochDateTime: Int
        let hasPrecipitation: Bool
        let iconPhrase: String
        let isDaylight: Bool
        let link: String
        let mobileLink: String
        let precipitationProbability: Int
        let temperature: Temperature
        let weatherIcon: Int

        enum CodingKeys: String, CodingKey {
            case dateTime = "DateTime"
            case epochDateTime = "EpochDateTime"
            case hasPrecipitation = "HasPrecipitation"
            case iconPhrase = "IconPhrase"
            case isDaylight = "IsDaylight"
            case link = "Link"
            case mobileLink = "MobileLink"
            case precipitationProbability = "PrecipitationProbability"
            case temperature = "Temperature"
            case weatherIcon = "WeatherIcon"
        }

        struct Temperature: Codable {
            let unit: String
            let unitType: Int
            let value: Double

            enum CodingKeys: String, CodingKey {
                case unit = "Unit"
                case unitType = "UnitType"
                case value = "Value"
            }
        }
    }
}
struct DailyForecastResponse: Codable {
    let finalAnswer: String
    let response: ResponseDetails
    let tool: String

    enum CodingKeys: String, CodingKey {
        case finalAnswer = "final_answer"
        case response
        case tool
    }

    struct ResponseDetails: Codable {
        let dailyForecasts: [DailyForecast]
        let headline: Headline

        enum CodingKeys: String, CodingKey {
            case dailyForecasts = "DailyForecasts"
            case headline = "Headline"
        }

        struct DailyForecast: Codable {
            let date: String
            let day: WeatherDetails
            let epochDate: Int
            let link: String
            let mobileLink: String
            let night: WeatherDetails
            let sources: [String]
            let temperature: TemperatureDetails

            enum CodingKeys: String, CodingKey {
                case date = "Date"
                case day = "Day"
                case epochDate = "EpochDate"
                case link = "Link"
                case mobileLink = "MobileLink"
                case night = "Night"
                case sources = "Sources"
                case temperature = "Temperature"
            }

            struct WeatherDetails: Codable {
                let hasPrecipitation: Bool
                let icon: Int
                let iconPhrase: String
                let precipitationIntensity: String?
                let precipitationType: String?

                enum CodingKeys: String, CodingKey {
                    case hasPrecipitation = "HasPrecipitation"
                    case icon = "Icon"
                    case iconPhrase = "IconPhrase"
                    case precipitationIntensity = "PrecipitationIntensity"
                    case precipitationType = "PrecipitationType"
                }
            }

            struct TemperatureDetails: Codable {
                let maximum: TemperatureValue
                let minimum: TemperatureValue

                enum CodingKeys: String, CodingKey {
                    case maximum = "Maximum"
                    case minimum = "Minimum"
                }

                struct TemperatureValue: Codable {
                    let unit: String
                    let unitType: Int
                    let value: Double

                    enum CodingKeys: String, CodingKey {
                        case unit = "Unit"
                        case unitType = "UnitType"
                        case value = "Value"
                    }
                }
            }
        }

        struct Headline: Codable {
            let category: String
            let effectiveDate: String
            let effectiveEpochDate: Int
            let endDate: String
            let endEpochDate: Int
            let link: String
            let mobileLink: String
            let severity: Int
            let text: String

            enum CodingKeys: String, CodingKey {
                case category = "Category"
                case effectiveDate = "EffectiveDate"
                case effectiveEpochDate = "EffectiveEpochDate"
                case endDate = "EndDate"
                case endEpochDate = "EndEpochDate"
                case link = "Link"
                case mobileLink = "MobileLink"
                case severity = "Severity"
                case text = "Text"
            }
        }
    }
}

// Usage example

struct PlacesResponse: Codable {
    let finalAnswer: String
    let response: PlacesResponse
    let tool: String

    struct PlacesResponse: Codable {
        let places: [Place]

        struct Place: Codable {
            let address: String
            let category: String
            let cid: String
            let latitude: Double
            let longitude: Double
            let position: Int
            let rating: Double
            let ratingCount: Int
            let thumbnailUrl: String
            let title: String
        }
    }
}



