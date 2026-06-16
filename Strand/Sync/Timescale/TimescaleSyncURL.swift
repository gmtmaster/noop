import Foundation

enum TimescaleSyncURL {
    static func normalizedBaseURL(from raw: String) throws -> URL {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TimescaleSyncError.invalidConfiguration("Server URL is required.")
        }
        guard var components = URLComponents(string: trimmed) else {
            throw TimescaleSyncError.invalidConfiguration("Enter a valid server URL.")
        }
        guard let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw TimescaleSyncError.invalidConfiguration("Server URL must start with http:// or https://.")
        }
        components.scheme = scheme
        guard let host = components.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty else {
            throw TimescaleSyncError.invalidConfiguration("Server URL must include a host name, localhost, or LAN IP.")
        }
        components.host = host
        components.query = nil
        components.fragment = nil

        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = path.isEmpty ? "" : "/" + path

        guard let url = components.url else {
            throw TimescaleSyncError.invalidConfiguration("Enter a valid server URL.")
        }

        #if DEBUG
        print("Timescale sync: normalized URL=\(url.absoluteString)")
        #endif
        return url
    }

    static func endpoint(baseURL raw: String, path: String) throws -> URL {
        let base = try normalizedBaseURL(from: raw)
        return base.appendingPathComponent(path)
    }

    static func validationMessage(for raw: String) -> String? {
        do {
            _ = try normalizedBaseURL(from: raw)
            #if DEBUG
            print("Timescale sync: URL validation=valid")
            #endif
            return nil
        } catch let error as TimescaleSyncError {
            #if DEBUG
            print("Timescale sync: URL validation=invalid error=\(error.localizedDescription)")
            #endif
            return error.localizedDescription
        } catch {
            #if DEBUG
            print("Timescale sync: URL validation=invalid error=\(error.localizedDescription)")
            #endif
            return "Enter a valid server URL."
        }
    }
}
