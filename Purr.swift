import AVFoundation
import CoreHaptics

/// Муркотіння: синтезований звук + вібрація. level: 0...1
final class Purr {
    /// One shared instance: SwiftUI can re-create a view's @State default many times,
    /// and several audio/haptic engines at once fight over the hardware.
    static let shared = Purr()

    private let engine = AVAudioEngine()
    private let haptics: HapticPurr
    fileprivate var level: Float = 0
    fileprivate var pitch: Float = 110
    fileprivate var rate: Float = 24
    fileprivate var rough: Float = 0.2

    init() {
        let session = AVAudioSession.sharedInstance()
        // .playback грає і при вимкненому дзвінку (беззвучний перемикач), .ambient — ні
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        haptics = HapticPurr()

        // Fixed rate: the mixer converts to the hardware rate, and we don't have to
        // query the output format before the session is active.
        let sampleRate: Double = 44100
        let rate = Float(sampleRate)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        var current: Float = 0
        var modPhase: Float = 0
        var carPhase: Float = 0
        var lowpass: Float = 0

        let node = AVAudioSourceNode(format: format) { [unowned self] _, _, frames, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let target = self.level
            let pitchHz = self.pitch, rateHz = self.rate, rough = self.rough
            for i in 0..<Int(frames) {
                current += (target - current) * 0.0004
                modPhase += 2 * Float.pi * rateHz / rate     // ~24 Гц — "ритм" муркотіння
                carPhase += 2 * Float.pi * pitchHz / rate    // низький тон
                if modPhase > 2 * Float.pi { modPhase -= 2 * Float.pi }
                if carPhase > 2 * Float.pi { carPhase -= 2 * Float.pi }
                lowpass += 0.03 * (Float.random(in: -1...1) - lowpass)
                let envelope: Float = 0.6 + 0.4 * sin(modPhase)
                let tone: Float = sin(carPhase) * (0.6 - 0.3 * rough) + lowpass * (1.0 + 2.0 * rough)
                let sample: Float = tone * envelope * current * 0.35
                for buffer in buffers {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[i] = sample
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        restart()   // activates the session and starts the engine off the main thread

        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                               object: nil, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.restart()
        }
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                               object: engine, queue: .main) { [weak self] _ in
            self?.restart()
        }
    }

    private var restarting = false   // main thread only

    /// Activating the audio session can block, so it never runs on the main thread.
    private func restart() {
        guard !restarting else { return }
        restarting = true
        DispatchQueue.global(qos: .userInitiated).async { [engine] in
            try? AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning { try? engine.start() }
            DispatchQueue.main.async { [weak self] in self?.restarting = false }
        }
    }

    func update(level value: Float, pitch: Float, rate: Float, rough: Float) {
        self.pitch = pitch
        self.rate = rate
        self.rough = rough
        setLevel(value)
    }

    func setLevel(_ value: Float) {
        level = value * 0.9
        if value > 0.04, !engine.isRunning { restart() }
        haptics.setLevel(value)
    }
}

/// Вібрація-муркотіння: короткі імпульси ~20 разів на секунду в циклі.
final class HapticPurr {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var running = false
    private var needsRebuild = false
    private var lastSent: Float = -1
    private var lastRebuild = Date.distantPast
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    init() { prepare() }

    private func prepare() {
        guard supported else { return }
        do {
            let e = try CHHapticEngine()
            e.isAutoShutdownEnabled = false
            // Called on a private queue: hop to main before touching our state.
            e.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async { self?.running = false; self?.needsRebuild = true }
            }
            e.resetHandler = { [weak self] in
                DispatchQueue.main.async { self?.running = false; self?.needsRebuild = true }
            }
            try e.start()
            engine = e
            makePlayer()
        } catch {
            engine = nil
            player = nil
        }
    }

    private func rebuild() {
        guard Date().timeIntervalSince(lastRebuild) > 0.5 else { return }   // no rebuild storms
        lastRebuild = Date()
        needsRebuild = false
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop()
        engine = nil
        running = false
        lastSent = -1
        prepare()
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
        } catch {
            player = nil
        }
    }

    func setLevel(_ value: Float) {
        guard supported else { return }
        if value > 0.04 {
            if engine == nil || player == nil || needsRebuild { rebuild() }
            guard let player else { return }
            do {
                if !running {
                    try player.start(atTime: CHHapticTimeImmediate)
                    running = true
                    lastSent = -1
                }
                let v = min(1, 0.25 + value)
                if abs(v - lastSent) > 0.02 {
                    let dp = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                      value: v,
                                                      relativeTime: 0)
                    try player.sendParameters([dp], atTime: CHHapticTimeImmediate)
                    lastSent = v
                }
            } catch {
                running = false
                needsRebuild = true
            }
        } else if running {
            try? player?.stop(atTime: CHHapticTimeImmediate)
            running = false
        }
    }
}
