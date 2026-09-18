import Foundation
import MobileMediaInfo

final class MediaInfoReader {
    enum ReaderError: LocalizedError {
        case initializationFailed

        var errorDescription: String? {
            "MediaInfo could not be initialized."
        }
    }

    private let handle: UnsafeMutableRawPointer

    init() {
        guard let handle = MediaInfo_New() else {
            preconditionFailure(ReaderError.initializationFailed.localizedDescription)
        }
        self.handle = handle
    }

    deinit {
        MediaInfo_Delete(handle)
    }

    var version: String {
        option("Info_Version")
            .replacingOccurrences(of: "MediaInfoLib - v", with: "")
    }

    func report(for url: URL) throws -> String {
        _ = option("Inform", value: "Text")

        let file = try FileHandle(forReadingFrom: url)
        defer {
            file.closeFile()
            MediaInfo_Close(handle)
        }

        let fileSize = file.seekToEndOfFile()
        file.seek(toFileOffset: 0)
        MediaInfo_Open_Buffer_Init(handle, fileSize, 0)

        while true {
            let data = file.readData(ofLength: 1024 * 1024)
            if data.isEmpty {
                break
            }

            let buffer = UnsafeMutablePointer<MediaInfo_int8u>.allocate(capacity: data.count)
            defer { buffer.deallocate() }
            data.copyBytes(to: buffer, count: data.count)

            let status = MediaInfo_Open_Buffer_Continue(handle, buffer, data.count)
            if status & 0x08 != 0 {
                break
            }

            let seekOffset = MediaInfo_Open_Buffer_Continue_GoTo_Get(handle)
            if seekOffset != MediaInfo_int64u.max {
                file.seek(toFileOffset: seekOffset)
                MediaInfo_Open_Buffer_Init(handle, fileSize, file.offsetInFile)
            }
        }

        MediaInfo_Open_Buffer_Finalize(handle)
        return string(from: MediaInfo_Inform(handle, 0))
    }

    @discardableResult
    private func option(_ name: String, value: String = "") -> String {
        name.withWideCharacters { namePointer in
            value.withWideCharacters { valuePointer in
                string(from: MediaInfo_Option(handle, namePointer, valuePointer))
            }
        }
    }

    private func string(from pointer: UnsafePointer<wchar_t>?) -> String {
        guard let pointer else { return "" }
        return NSString(
            bytes: pointer,
            length: wcslen(pointer) * MemoryLayout<wchar_t>.size,
            encoding: String.Encoding.utf32LittleEndian.rawValue
        ) as String? ?? ""
    }
}

private extension String {
    func withWideCharacters<Result>(
        _ body: (UnsafePointer<wchar_t>) -> Result
    ) -> Result {
        let characters = unicodeScalars.map { wchar_t(bitPattern: $0.value) } + [0]
        return characters.withUnsafeBufferPointer { buffer in
            body(buffer.baseAddress!)
        }
    }
}
