import CoreServices
import Foundation

final class FileWatcher {
    var onChange: (() -> Void)?
    private var streamRef: FSEventStreamRef?

    func start(path: String) {
        guard streamRef == nil else { return }

        let paths = [path] as CFArray

        var ctx = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passRetained(self).toOpaque(),
            retain: { ptr in ptr.map { UnsafeRawPointer(Unmanaged<FileWatcher>.fromOpaque($0).retain().toOpaque()) } },
            release: { ptr in ptr.map { Unmanaged<FileWatcher>.fromOpaque($0).release() } },
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue().onChange?()
        }

        let flags = UInt32(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagUseCFTypes
        )

        streamRef = FSEventStreamCreate(
            nil,
            callback,
            &ctx,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            flags
        )

        if let stream = streamRef {
            FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
            FSEventStreamStart(stream)
        }
    }

    func stop() {
        guard let stream = streamRef else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
    }

    deinit { stop() }
}
