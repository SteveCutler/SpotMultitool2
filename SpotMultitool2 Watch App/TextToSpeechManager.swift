//
//  TextToSpeech.swift
//  GearMultiTool
//
//  Created by Steve Cutler on 2024-01-13.
//

import Foundation
import Alamofire
import AVFoundation

class TextToSpeechManager {
    // Text-to-Speech (TTS) API endpoint
    static let apiKey = "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"
    static let ttsEndpoint = "https://api.openai.com/v1/audio/speech"
   // let VoiceChoice = "shimmer"
   
    // TTS API response model
    struct TTSResponse: Decodable {
        let audio: String
    }
    static var audioPlayer: AVAudioPlayer?
    static var delegateProxy: AVAudioPlayerDelegateProxy?

    static func isAudioPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }

    // Function to generate audio from text using TTS API
    static func generateAudioFromText(text: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer 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",
            "Content-Type": "application/json",
        ]
        print("Attempting to generate audio from text")
        var voice = "shimmer"

        let parameters: [String: Any] = [
            "model": "tts-1-hd",
            "input": text,
            "voice": voice,
            "response_format": "mp3", // You can change the format if needed
        ]

        AF.request(ttsEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseData { response in
                print("Status Code: \(response.response?.statusCode ?? 0)")
           //     print("Response Headers: \(response.response?.allHeaderFields ?? [])")

                switch response.result {
                case .success(let data):
                    // Attempt to convert the data to a String and print it
                    if let rawJSONString = String(data: data, encoding: .utf8) {
                        print("Raw JSON response: \(rawJSONString)")
                    } else {
                        print("Data might be binary (audio), length: \(data.count) bytes")
                    }
                    completion(.success(data))
                case .failure(let error):
                    print("Error in TTS request: \(error.localizedDescription)")
                    if let data = response.data, let errorString = String(data: data, encoding: .utf8) {
                        print("Error response body: \(errorString)")
                    }
                    completion(.failure(error))
                }
            }
    }
    
    static func stopAudio() {
        audioPlayer?.stop()
    }


  
  

    static func playAudio(_ audioData: Data, completion: @escaping () -> Void) {
            do {
                // Configure the audio session
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                // Initialize and play the audio
                audioPlayer = try AVAudioPlayer(data: audioData)
                audioPlayer?.prepareToPlay()

                // Retain the delegate proxy
                delegateProxy = AVAudioPlayerDelegateProxy(completion: completion)
                audioPlayer?.delegate = delegateProxy

                audioPlayer?.play()
                print("Playing audio...")
            } catch {
                print("Error setting up audio session or playing audio: \(error)")
            }
        }
    }

    class AVAudioPlayerDelegateProxy: NSObject, AVAudioPlayerDelegate {
        var completion: () -> Void

        init(completion: @escaping () -> Void) {
            self.completion = completion
        }

        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            completion()
        }
    }


