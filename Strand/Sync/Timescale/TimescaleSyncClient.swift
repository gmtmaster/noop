import Foundation

struct TimescaleSyncClient {
    var session: URLSession = .shared

    func testConnection(serverURL: String, bearerToken: String?) async throws {
        let url = try endpoint(serverURL: serverURL, path: "healthz")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await session.data(for: request)
        try validate(response: response, data: Data())
    }

    func send(_ batch: TimescaleSyncBatch,
              serverURL: String,
              bearerToken: String?) async throws -> TimescaleSyncResult {
        let url = try endpoint(serverURL: serverURL, path: "v1/sync/batch")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(batch)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode(TimescaleSyncResult.self, from: data)
    }

    private func endpoint(serverURL: String, path: String) throws -> URL {
        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed), components.scheme != nil else {
            throw TimescaleSyncError.invalidConfiguration("Enter a valid server URL.")
        }
        let basePath = (components.path as NSString).appendingPathComponent(path)
        components.path = basePath
        guard let url = components.url else {
            throw TimescaleSyncError.invalidConfiguration("Enter a valid server URL.")
        }
        return url
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TimescaleSyncError.server(http.statusCode, body)
        }
    }
}

enum TimescaleSyncError: LocalizedError {
    case invalidConfiguration(String)
    case server(Int, String)
    case emptyBatch

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return message
        case .server(let code, let body):
            let detail = body.isEmpty ? "" : ": \(body)"
            return "Server returned \(code)\(detail)"
        case .emptyBatch:
            return "No new local data to sync."
        }
    }
}
