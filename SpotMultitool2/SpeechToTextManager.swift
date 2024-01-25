//
//  SpeechToTextManager.swift
//  GearMultiTool
//
//  Created by Steve Cutler on 2024-01-13.
//

import Foundation
import AVFoundation
import Alamofire


class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
     var currentRecordingURL: URL?
    var onFinishRecording: ((URL?) -> Void)?


  
    func startRecording() {
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
            onFinishRecording?(nil)
            return
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        print("recording file: ",audioFilename)
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("start recording")
        } catch {
            onFinishRecording?(nil)
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        currentRecordingURL = audioRecorder?.url
        print("stop recording")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            currentRecordingURL = recorder.url
            onFinishRecording?(recorder.url)
            print("Recording finished successfully, file saved at: \(recorder.url)")
        } else {
            onFinishRecording?(nil)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}


class WhisperManager {
    static let shared = WhisperManager()
    
    func getAPIKey(named keyName: String) -> String? {
        if let path = Bundle.main.path(forResource: "SecretInfo", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return config[keyName] as? String
        }
        return nil
    }
    
    func transcribeAudio(at url: URL, completion: @escaping (String?) -> Void) {
        print("sending to  whisper")
       
        let OpenAIKey = ProcessInfo.processInfo.environment["OPENAIKEY"]
        print("API Key: \(OpenAIKey ?? "Key not found")")
    
        print("api key = ",OpenAIKey)
        let apiURL = "https://api.openai.com/v1/audio/transcriptions"
        let headers: HTTPHeaders = ["Authorization": "Bearer \(OpenAIKey)"]
  
        let parameters: [String: Any] = [
            "model": "whisper-1",
        ]
        AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                if let data = "\(value)".data(using: .utf8) {
                    multipartFormData.append(data, withName: key)
                }
            }
           
            multipartFormData.append(url, withName: "file", fileName: "recording.m4a", mimeType: "audio/m4a")
        }, to: apiURL, headers: headers).responseDecodable(of: TranscriptionResponse.self) { response in
            switch response.result {
            case .success(let transcriptionResponse):
                completion(transcriptionResponse.text)
                print("received transcription recording :",transcriptionResponse.text)
            case .failure:
                completion(nil)
                print("failed to transcribe")
            }
        }
    }
}

struct TranscriptionResponse: Decodable {
    let text: String
}
