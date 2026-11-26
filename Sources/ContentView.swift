import SwiftUI

struct ContentView: View {

    @State private var urlText = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    @State private var fps: Double = 0
    @State private var intervalMs: Double = 33
    @State private var width: Double = 800
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kaynak") {
                    TextField("HLS URL", text: $urlText)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    Button("Oynat") {
                        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)) else {
                            message = "Geçersiz URL"
                            return
                        }
                        PlayerEngine.shared.setPump(intervalMs: Int(intervalMs), artworkWidth: CGFloat(width))
                        PlayerEngine.shared.play(url: url)
                        message = "çalıyor"
                    }
                    Button("Durdur") {
                        PlayerEngine.shared.stop()
                        message = "durdu"
                    }
                }
                Section("POC parametreleri") {
                    Stepper("Pump aralığı: \(Int(intervalMs)) ms (~\(Int(1000 / intervalMs)) Hz)",
                            value: $intervalMs, in: 16...100, step: 8)
                    Stepper("Artwork genişliği: \(Int(width)) px",
                            value: $width, in: 320...1280, step: 160)
                    Text("Değişiklik pump çalışırken uygulanır.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Ölçüm") {
                    Text(String(format: "Gönderilen frame: %.1f fps", fps))
                        .monospacedDigit()
                    if !message.isEmpty {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Frame POC")
            .onAppear {
                PlayerEngine.shared.onStats = { value in fps = value }
            }
        }
    }
}
