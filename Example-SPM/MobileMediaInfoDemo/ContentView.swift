import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isImporting = false
    @State private var report = "Select a media file to inspect it."
    @State private var selectedFile = "No file selected"

    private let reader = MediaInfoReader()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MediaInfo \(reader.version)")
                        .font(.headline)
                    Text(selectedFile)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Button {
                    isImporting = true
                } label: {
                    Label("Choose Media File", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                ScrollView {
                    Text(report)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .navigationTitle("MediaInfo SPM Demo")
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.movie, .audio, .data]
            ) { result in
                inspect(result)
            }
        }
    }

    private func inspect(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            selectedFile = url.lastPathComponent
            report = try reader.report(for: url)
        } catch {
            report = "Unable to inspect the file:\n\(error.localizedDescription)"
        }
    }
}
