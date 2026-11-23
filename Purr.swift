import AVFoundation
import CoreHaptics

/// Муркотіння: синтезований звук + вібрація. level: 0...1
final class Purr {
    private let engine = AVAudioEngine()
    private let haptics = HapticPurr()
    fileprivate var level: Float = 0

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)   // поважає беззвучний режим
        try? session.setActive(true)

        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let rate = Float(sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        var current: Float = 0
        var modPhase: Float = 0
        var carPhase: Float = 0
        var lowpass: Float = 0

        let node = AVAudioSourceNode(format: format) { [unowned self] _, _, frames, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let target = self.level
            for i in 0..<Int(frames) {
                current += (target - current) * 0.0004
                modPhase += 2 * Float.pi * 24 / rate     // ~24 Гц — "ритм" муркотіння
                carPhase += 2 * Float.pi * 110 / rate    // низький тон
                if modPhase > 2 * Float.pi { modPhase -= 2 * Float.pi }
                if carPhase > 2 * Float.pi { carPhase -= 2 * Float.pi }
                lowpass += 0.03 * (Float.random(in: -1...1) - lowpass)
                let envelope: Float = 0.6 + 0.4 * sin(modPhase)
                let tone: Float = sin(carPhase) * 0.5 + lowpass * 2.0
                let sample: Float = tone * envelope * current * 0.35
                for buffer in buffers {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[i] = sample
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    func setLevel(_ value: Float) {
        level = value * 0.9
        haptics.setLevel(value)
    }
}

/// Вібрація-муркотіння: короткі імпульси ~20 разів на секунду в циклі.
final class HapticPurr {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var running = false

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = false
            e.resetHandler = { [weak self] in
                try? self?.engine?.start()
                self?.makePlayer()
            }
            try e.start()
            engine = e
            makePlayer()
        } catch {}
    }

    private func makePlayer() {
        var events: [CHHapticEvent] = []
        for i in 0..<20 {
            let params = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
            ]
            events.append(CHHapticEvent(eventType: .hapticContinuous,
                                        parameters: params,
                                        relativeTime: Double(i) * 0.05,
                                        duration: 0.03))
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let p = try engine?.makeAdvancedPlayer(with: pattern)
            p?.loopEnabled = true
            player = p
            running = false
        } catch {}
    }

    func setLevel(_ value: Float) {
        guard let player else { return }
        if value > 0.04 {
            do {
                if !running {
                    try player.start(atTime: CHHapticTimeImmediate)
                    running = true
                }
                let dp = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                  value: min(1, 0.25 + value),
                                                  relativeTime: 0)
                try player.sendParameters([dp], atTime: CHHapticTimeImmediate)
            } catch {}
        } else if running {
            try? player.stop(atTime: CHHapticTimeImmediate)
            running = false
        }
    }
}
