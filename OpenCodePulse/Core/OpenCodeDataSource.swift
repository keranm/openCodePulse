import Foundation

enum DataSourceStatus: Equatable {
    case connected(String)
    case noData
    case unsupported(String)
    case permissionDenied
}

final class OpenCodeDataSource {
    private let openCodeDir: URL
    private let fileManager = FileManager.default
    private var cachedFormat: DataSourceStatus?

    private(set) var status: DataSourceStatus = .noData

    init() {
        openCodeDir = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/opencode")
    }

    func detectStorageFormat() -> DataSourceStatus {
        if let cached = cachedFormat { return cached }

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: openCodeDir.path, isDirectory: &isDir), isDir.boolValue else {
            status = .noData
            cachedFormat = status
            return status
        }

        let dbPath = openCodeDir.appendingPathComponent("opencode.db")
        if fileManager.fileExists(atPath: dbPath.path) {
            status = .connected("SQLite")
            cachedFormat = status
            return status
        }

        let storageDir = openCodeDir.appendingPathComponent("storage/message")
        if fileManager.fileExists(atPath: storageDir.path) {
            status = .connected("JSON")
            cachedFormat = status
            return status
        }

        let logDir = openCodeDir.appendingPathComponent("log")
        if fileManager.fileExists(atPath: logDir.path) {
            status = .connected("Logs")
            cachedFormat = status
            return status
        }

        status = .noData
        cachedFormat = status
        return status
    }

    func resetCachedFormat() {
        cachedFormat = nil
    }

    func fetchEntries() -> [OpenCodeEntry] {
        switch detectStorageFormat() {
        case .connected("SQLite"):
            return fetchFromSQLite()
        case .connected("JSON"):
            return fetchFromJSON()
        case .connected("Logs"):
            return fetchFromLogs()
        default:
            return []
        }
    }

    private func fetchFromSQLite() -> [OpenCodeEntry] {
        let dbPath = openCodeDir.appendingPathComponent("opencode.db").path
        var entries: [OpenCodeEntry] = []

        // Query the session table — columns: id (sessionID), model (JSON), time_created (ms),
        // tokens_input, tokens_output, cost, agent, project_id
        let query = """
        SELECT json_object(
            'id', COALESCE(id, ''),
            'model_json', COALESCE(model, '{}'),
            'time_ms', COALESCE(time_created, 0),
            'time_updated_ms', COALESCE(time_updated, 0),
            'tokens_input', COALESCE(tokens_input, 0),
            'tokens_output', COALESCE(tokens_output, 0),
            'cost', COALESCE(cost, 0.0),
            'agent', COALESCE(agent, ''),
            'project_id', COALESCE(project_id, '')
        ) FROM session WHERE time_created > (\(Int(Date().timeIntervalSince1970 * 1000)) - 172800000)
        ORDER BY time_created DESC LIMIT 500
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = [dbPath, query]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return [] }

            for line in output.split(separator: "\n") {
                guard let lineData = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

                let sessionID = json["id"] as? String ?? ""
                let modelJSONStr = json["model_json"] as? String ?? "{}"
                let timeMS = int64(from: json["time_ms"]) ?? 0
                let timeUpdatedMS = int64(from: json["time_updated_ms"]) ?? timeMS
                let inputTokens = json["tokens_input"] as? Int ?? 0
                let outputTokens = json["output_tokens"] as? Int ?? 0
                let cost = json["cost"] as? Double ?? 0

                var provider = ""
                var modelID = ""
                if let modelData = modelJSONStr.data(using: .utf8),
                   let modelObj = try? JSONSerialization.jsonObject(with: modelData) as? [String: Any] {
                    provider = modelObj["providerID"] as? String ?? ""
                    modelID = modelObj["id"] as? String ?? ""
                }

                let date = Date(timeIntervalSince1970: TimeInterval(timeMS) / 1000.0)
                let lastActivity = Date(timeIntervalSince1970: TimeInterval(timeUpdatedMS) / 1000.0)

                let estimatedCost = cost > 0 ? cost : ModelPricing.estimatedCost(provider: provider, model: modelID, inputTokens: inputTokens, outputTokens: outputTokens)

                entries.append(OpenCodeEntry(
                    provider: provider, model: modelID, timestamp: date,
                    lastActivity: lastActivity,
                    inputTokens: inputTokens, outputTokens: outputTokens,
                    cost: estimatedCost, sessionID: sessionID
                ))
            }
        } catch {
            print("OpenCodeDataSource: SQLite query failed: \(error)")
        }

        return entries
    }

    private func fetchFromJSON() -> [OpenCodeEntry] {
        let messagesDir = openCodeDir.appendingPathComponent("storage/message")
        var entries: [OpenCodeEntry] = []

        guard let sessionDirs = try? fileManager.contentsOfDirectory(
            at: messagesDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        for sessionDir in sessionDirs {
            guard let files = try? fileManager.contentsOfDirectory(
                at: sessionDir,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) else { continue }

            for file in files where file.pathExtension == "json" {
                guard let data = try? Data(contentsOf: file),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }

                let provider = json["provider"] as? String ?? ""
                let model = json["model"] as? String ?? ""
                let timestampStr = json["timestamp"] as? String ?? ""
                let inputTokens = json["input_tokens"] as? Int ?? 0
                let outputTokens = json["output_tokens"] as? Int ?? 0
                let sessionID = json["session_id"] as? String

                let cost = ModelPricing.estimatedCost(provider: provider, model: model, inputTokens: inputTokens, outputTokens: outputTokens)
                let date = ISO8601DateFormatter().date(from: timestampStr) ?? Date()

                entries.append(OpenCodeEntry(
                    provider: provider, model: model, timestamp: date,
                    lastActivity: date,
                    inputTokens: inputTokens, outputTokens: outputTokens,
                    cost: cost, sessionID: sessionID
                ))
            }
        }

        return entries
    }

    private static let logDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let logDateFormatterPlain = ISO8601DateFormatter()

    /// Safely extract an Int64 from a JSON value that may be Int, Int64, or NSNumber.
    private func int64(from value: Any?) -> Int64? {
        switch value {
        case let v as Int64:   return v
        case let v as Int:     return Int64(v)
        case let v as NSNumber: return v.int64Value
        case let v as Double where v <= Double(Int64.max): return Int64(v)
        default: return nil
        }
    }

    private func fetchFromLogs() -> [OpenCodeEntry] {
        let logDir = openCodeDir.appendingPathComponent("log")
        var entries: [OpenCodeEntry] = []

        guard let files = try? fileManager.contentsOfDirectory(
            at: logDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        for file in files where file.pathExtension == "jsonl" || file.pathExtension == "log" {
            guard let content = try? String(contentsOf: file, encoding: .utf8) else { continue }

            for line in content.split(separator: "\n") {
                guard let lineData = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

                let provider = (json["provider"] as? String) ?? (json["source"] as? String) ?? ""
                let model = json["model"] as? String ?? ""
                let timestampStr = (json["timestamp"] as? String) ?? (json["time"] as? String) ?? ""
                let inputTokens = (json["input_tokens"] as? Int) ?? (json["input"] as? Int) ?? 0
                let outputTokens = (json["output_tokens"] as? Int) ?? (json["output"] as? Int) ?? 0
                let sessionID = json["session_id"] as? String

                let cost = ModelPricing.estimatedCost(provider: provider, model: model, inputTokens: inputTokens, outputTokens: outputTokens)
                let date = Self.logDateFormatter.date(from: timestampStr)
                    ?? Self.logDateFormatterPlain.date(from: timestampStr)
                    ?? Date()

                entries.append(OpenCodeEntry(
                    provider: provider, model: model, timestamp: date,
                    lastActivity: date,
                    inputTokens: inputTokens, outputTokens: outputTokens,
                    cost: cost, sessionID: sessionID
                ))
            }
        }

        return entries
    }
}

// Per-model pricing in USD per 1M tokens for known OpenCode providers
struct ModelPricing {
    let inputPerToken: Double
    let outputPerToken: Double

    // Rates per 1M tokens
    static let table: [String: (input: Double, output: Double)] = [
        // Anthropic
        "anthropic/claude-sonnet-4-6":        (3.0, 15.0),
        "anthropic/claude-sonnet-4-5":        (3.0, 15.0),
        "anthropic/claude-haiku-4-5":         (0.80, 4.0),
        "anthropic/claude-opus-4-7":          (15.0, 75.0),
        "anthropic/claude-opus-4-6":          (15.0, 75.0),
        // Short forms
        "claude-sonnet-4-6":                  (3.0, 15.0),
        "claude-sonnet-4-5":                  (3.0, 15.0),
        "claude-haiku-4-5":                   (0.80, 4.0),
        "claude-opus-4-7":                    (15.0, 75.0),
        "claude-opus-4-6":                    (15.0, 75.0),
        // OpenAI
        "openai/gpt-4o":                      (2.50, 10.0),
        "openai/gpt-4o-mini":                 (0.15, 0.60),
        "openai/gpt-4":                       (30.0, 60.0),
        "openai/gpt-4-turbo":                 (10.0, 30.0),
        "openai/o1":                          (15.0, 60.0),
        "openai/o3-mini":                     (1.10, 4.40),
        // Google
        "google/gemini-2.0-flash":            (0.10, 0.40),
        "google/gemini-2.0-pro":              (2.0, 8.0),
        "google/gemini-2.5-pro":              (1.25, 10.0),
        // Local — zero cost estimates (run locally)
        "local/qwen":                         (0, 0),
        "local/llama":                        (0, 0),
        "local/mistral":                      (0, 0),
        "local/codellama":                    (0, 0),
    ]

    static let fallback = (input: 3.0, output: 15.0)

    static func forModel(_ model: String) -> (input: Double, output: Double) {
        if let exact = table[model] { return exact }
        for (key, pricing) in table where model.hasPrefix(key) || key.hasPrefix(model) {
            return pricing
        }
        return fallback
    }

    static func estimatedCost(provider: String, model: String, inputTokens: Int, outputTokens: Int) -> Double {
        let lookupKey = provider.isEmpty ? model : "\(provider)/\(model)"
        let rates = forModel(lookupKey)
        return (Double(inputTokens) * rates.input / 1_000_000) +
               (Double(outputTokens) * rates.output / 1_000_000)
    }
}
