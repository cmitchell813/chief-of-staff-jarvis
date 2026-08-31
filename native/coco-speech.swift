// =============================================================================
// coco-speech — native macOS speech recognition helper for Coco.
// ---------------------------------------------------------------------------
// Uses SFSpeechRecognizer + AVAudioEngine to transcribe microphone audio and
// stream results to stdout as line-delimited JSON. This is far more reliable
// inside Electron than the cloud Web Speech API (which needs real Chrome).
//
// Output lines (one JSON object per line):
//   {"type":"status","state":"listening"}
//   {"type":"partial","text":"..."}         (interim result)
//   {"type":"final","text":"..."}           (finalized utterance)
//   {"type":"error","message":"..."}
//
// Build:  swiftc -O -o coco-speech coco-speech.swift
// Run:    ./coco-speech        (prints JSON lines until killed)
// =============================================================================

import Foundation
import Speech
import AVFoundation

// Line-buffered stdout so Electron receives events immediately.
setbuf(stdout, nil)

func emit(_ obj: [String: Any]) {
    if let data = try? JSONSerialization.data(withJSONObject: obj),
       let line = String(data: data, encoding: .utf8) {
        print(line)
    }
}

final class Recognizer: NSObject, SFSpeechRecognizerDelegate {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start() {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            emit(["type": "error", "message": "Speech recognizer unavailable on this system."])
            exit(1)
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        // Prefer on-device recognition when supported (private + offline).
        if #available(macOS 13, *) {
            req.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        }
        self.request = req

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            emit(["type": "error", "message": "Could not start audio engine: \(error.localizedDescription)"])
            exit(1)
        }

        emit(["type": "status", "state": "listening"])

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                if result.isFinal {
                    emit(["type": "final", "text": text])
                    // Restart for continuous listening.
                    self?.restart()
                } else {
                    emit(["type": "partial", "text": text])
                }
            }
            if let error = error {
                emit(["type": "error", "message": error.localizedDescription])
                self?.restart()
            }
        }
    }

    private func restart() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        // Brief pause, then begin a fresh recognition session.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.start()
        }
    }
}

// Held strongly so the recognizer + its async callbacks are not deallocated.
var sharedRecognizer: Recognizer?

// Request authorization, then begin.
SFSpeechRecognizer.requestAuthorization { status in
    DispatchQueue.main.async {
        switch status {
        case .authorized:
            sharedRecognizer = Recognizer()
            sharedRecognizer?.start()
        case .denied:
            emit(["type": "error", "message": "Speech recognition permission denied."])
            exit(1)
        case .restricted:
            emit(["type": "error", "message": "Speech recognition restricted on this device."])
            exit(1)
        case .notDetermined:
            emit(["type": "error", "message": "Speech recognition not authorized yet."])
            exit(1)
        @unknown default:
            emit(["type": "error", "message": "Unknown speech authorization status."])
            exit(1)
        }
    }
}

RunLoop.main.run()
