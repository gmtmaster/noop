import Foundation

struct TimescaleSyncClient {
    var session: URLSession = .shared

    func testConnection(serverURL: String, bearerToken: String?) async throws {
        var lastError: Error?
        for path in ["health", "healthz"] {
            let url = try TimescaleSyncURL.endpoint(baseURL: serverURL, path: path)
            let request = makeRequest(url: url, method: "GET", bearerToken: bearerToken)
            #if DEBUG
            print("Timescale sync: test request start url=\(url.absoluteString)")
            #endif
            do {
                let (data, response) = try await session.data(for: request)
                try validate(response: response, data: data)
                return
            } catch {
                #if DEBUG
                print("Timescale sync: test request error url=\(url.absoluteString) error=\(error.localizedDescription)")
                #endif
                lastError = error
                guard shouldFallbackHealthRoute(after: error) else { throw error }
            }
        }
        throw lastError ?? TimescaleSyncError.invalidConfiguration("Could not reach a health endpoint.")
    }

    func send(_ batch: TimescaleSyncBatch,
              serverURL: String,
              bearerToken: String?) async throws -> TimescaleSyncResult {
        let url = try TimescaleSyncURL.endpoint(baseURL: serverURL, path: "v1/sync/batch")
        var request = makeRequest(url: url, method: "POST", bearerToken: bearerToken)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(batch)
        #if DEBUG
        print("Timescale sync: sync request start url=\(url.absoluteString)")
        #endif
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
        } catch {
            #if DEBUG
            print("Timescale sync: sync request error=\(error.localizedDescription)")
            #endif
            throw error
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode(TimescaleSyncResult.self, from: data)
    }

    private func makeRequest(url: URL, method: String, bearerToken: String?) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func shouldFallbackHealthRoute(after error: Error) -> Bool {
        guard let syncError = error as? TimescaleSyncError else { return true }
        guard case .server(let statusCode, _) = syncError else { return false }
        return statusCode == 404 || statusCode == 502
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        #if DEBUG
        print("Timescale sync: HTTP status=\(http.statusCode)")
        #endif
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
