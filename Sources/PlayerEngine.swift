import AVFoundation
import CarPlay
import CoreImage
import MediaPlayer
import UIKit

/// Frame-pump POC:
/// AVPlayerItemVideoOutput ile video karelerini yakala,
/// now playing artwork'üne olabildiğince hızlı bas,
/// gönderilen frame hızını ölç (CarPlay'in kaçını gerçek gösterdiğini gözlemle).
final class PlayerEngine {

    static let shared = PlayerEngine()

    // MARK: POC parametreleri (Phone UI'dan ayarlanır)
    var pumpIntervalMs = 33            // 20 Hz'den başla
    var artworkWidth: CGFloat = 800   // artwork genişliği (yükseklik oranla)

    // MARK: Ölçüm
    private(set) var lastFPS: Double = 0
    var onStats: ((Double) -> Void)?

    private let player = AVPlayer()
    private var videoOutput: AVPlayerItemVideoOutput?
    private var pumpTimer: DispatchSourceTimer?
    private let pumpQueue = DispatchQueue(label: "carplay.frame.pump")
    private let ciContext = CIContext()

    private var framesSinceStat = 0
    private var lastStatAt = Date()

    private var interfaceController: CPInterfaceController?

    // MARK: - Audio session / remote commands

    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        let cmd = MPRemoteCommandCenter.shared()
        cmd.playCommand.addTarget { [weak self] _ in
            self?.player.play()
            return .success
        }
        cmd.pauseCommand.addTarget { [weak self] _ in
            self?.player.pause()
            return .success
        }
        cmd.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.player.timeControlStatus == .playing { self.player.pause() } else { self.player.play() }
            return .success
        }

        let info: [String: Any] = [
            MPMediaItemPropertyTitle: "Frame POC",
            MPMediaItemPropertyArtist: "POC",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Oynatma

    func play(url: URL) {
        stopPump()

        let item = AVPlayerItem(url: url)
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        item.add(output)
        videoOutput = output

        player.replaceCurrentItem(with: item)
        player.play()
        updateNowPlaying(title: url.host ?? url.absoluteString)
        startPump()
    }

    func stop() {
        stopPump()
        player.pause()
    }

    /// Pump çalışırken parametre değiştir.
    func setPump(intervalMs: Int, artworkWidth: CGFloat) {
        self.pumpIntervalMs = intervalMs
        self.artworkWidth = artworkWidth
        if pumpTimer != nil { startPump() }
    }

    // MARK: - Frame pump

    private func startPump() {
        stopPump()
        let timer = DispatchSource.makeTimerSource(queue: pumpQueue)
        timer.schedule(deadline: .now() + .milliseconds(pumpIntervalMs),
                        repeating: .milliseconds(pumpIntervalMs))
        timer.setEventHandler { [weak self] in self?.pumpOnce() }
        timer.resume()
        pumpTimer = timer
    }

    private func stopPump() {
        pumpTimer?.cancel()
        pumpTimer = nil
    }

    private func pumpOnce() {
        guard let output = videoOutput,
              let item = player.currentItem else { return }
        let t = item.currentTime()
        guard output.hasNewPixelBuffer(forItemTime: t) else { return }
        var displayTime = CMTime.invalid
        guard let buffer = output.copyPixelBuffer(forItemTime: t, itemTimeForDisplay: &displayTime),
              let image = image(from: buffer) else { return }

        pushArtwork(image)
        bumpStats()
    }

    /// CVPixelBuffer -> küçültülmüş UIImage
    private func image(from buffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let srcW = CGFloat(cgImage.width)
        let srcH = CGFloat(cgImage.height)
        guard srcW > 0, srcH > 0 else { return nil }
        let dstW = artworkWidth
        let dstH = dstW * srcH / srcW
        let dstSize = CGSize(width: dstW, height: dstH)
        return UIGraphicsImageRenderer(size: dstSize).image { _ in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: dstSize))
        }
    }

    private func pushArtwork(_ image: UIImage) {
        DispatchQueue.main.async {
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func updateNowPlaying(title: String) {
        DispatchQueue.main.async {
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyTitle] = title
            info[MPMediaItemPropertyArtist] = "Frame POC"
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func bumpStats() {
        framesSinceStat += 1
        let now = Date()
        let dt = now.timeIntervalSince(lastStatAt)
        if dt >= 1.0 {
            lastFPS = Double(framesSinceStat) / dt
            framesSinceStat = 0
            lastStatAt = now
            let value = lastFPS
            DispatchQueue.main.async { [weak self] in self?.onStats?(value) }
        }
    }

    // MARK: - CarPlay

    func attachCarPlay(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        let testItem = CPListItem(text: "Apple Test Stream", detailText: "ses + video örnek HLS")
        testItem.handler = { [weak self] _, completion in
            guard let self = self else { completion(); return }
            let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!
            self.play(url: url)
            completion()
        }
        let list = CPListTemplate(title: "Frame POC", sections: [CPListSection(items: [testItem])])
        interfaceController.setRootTemplate(list, animated: false, completion: nil)
    }

    func detachCarPlay() {
        interfaceController = nil
    }
}
