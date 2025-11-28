import SwiftUI
import PhotosUI
import AVFoundation

@main
struct LocalPictureSaverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var mediaItems: [MediaItem] = []
    @State private var isUploading = false
    @State private var serverAddress: String = UserDefaults.standard.string(forKey: "serverAddress") ?? "http://localhost:8000"
    @State private var apiToken: String = UserDefaults.standard.string(forKey: "apiToken") ?? "changeme"
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            VStack {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos]),
                    photoLibrary: .shared()) {
                        Text("Select Media")
                    }
                    .onChange(of: selectedItems) { newItems in
                        Task {
                            mediaItems = []
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    mediaItems.append(MediaItem(type: .image, data: data, thumbnail: image, filename: "photo.jpg"))
                                } else if let url = try? await item.loadTransferable(type: URL.self) {
                                    // Load video data
                                    if let videoData = try? Data(contentsOf: url) {
                                        let thumbnail = generateVideoThumbnail(url: url)
                                        mediaItems.append(MediaItem(type: .video, data: videoData, thumbnail: thumbnail, filename: url.lastPathComponent))
                                    }
                                }
                            }
                        }
                    }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(mediaItems, id: \ .self) { item in
                            if let thumbnail = item.thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        item.type == .video ? Image(systemName: "play.circle.fill").foregroundColor(.white).font(.system(size: 30)).padding(4) : nil,
                                        alignment: .center
                                    )
                            }
                        }
                    }
                }
                Button(action: uploadSelected) {
                    if isUploading {
                        ProgressView()
                    } else {
                        Text("Upload Selected")
                    }
                }
                .disabled(mediaItems.isEmpty || isUploading)
                Button("Settings") {
                    showSettings = true
                }
                .padding(.top)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(serverAddress: $serverAddress, apiToken: $apiToken)
            }
            .navigationTitle("LocalPictureSaver")
        }
    }
    
    func uploadSelected() {
        guard !mediaItems.isEmpty else { return }
        isUploading = true
        Task {
            defer { isUploading = false }
            for item in mediaItems {
                await uploadMedia(item: item)
            }
        }
    }

    func uploadMedia(item: MediaItem) async {
        guard let url = URL(string: "\(serverAddress)/upload") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        let filename = item.filename
        let mimeType = item.type == .image ? "image/jpeg" : "video/mp4"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(item.data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Success
            } else {
                // Handle error
            }
        } catch {
            // Handle error
        }
    }

// MARK: - MediaItem Model
enum MediaType: String, Hashable {
    case image
    case video
}

struct MediaItem: Hashable {
    let type: MediaType
    let data: Data
    let thumbnail: UIImage?
    let filename: String
}

// MARK: - Video Thumbnail Helper
import AVFoundation
func generateVideoThumbnail(url: URL) -> UIImage? {
    let asset = AVAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let time = CMTime(seconds: 0.1, preferredTimescale: 600)
    if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
        return UIImage(cgImage: cgImage)
    }
    return nil
}
}

struct SettingsView: View {
    @Binding var serverAddress: String
    @Binding var apiToken: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server")) {
                    TextField("Server Address", text: $serverAddress)
                    TextField("API Token", text: $apiToken)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        UserDefaults.standard.set(serverAddress, forKey: "serverAddress")
                        UserDefaults.standard.set(apiToken, forKey: "apiToken")
                        dismiss()
                    }
                }
            }
        }
    }
}
