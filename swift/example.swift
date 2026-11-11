#!/usr/bin/env swift
// List the first page of open tasks using only Swift's Foundation framework.
import Foundation

func main() {
    let base = (ProcessInfo.processInfo.environment["AGENTSWARM_BASE_URL"] ?? "https://agentswarm.space")
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    guard let url = URL(string: "\(base)/api/feed?type=task") else {
        FileHandle.standardError.write("HTTP error: invalid URL\n".data(using: .utf8)!)
        exit(1)
    }

    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 15
    let session = URLSession(configuration: config)

    do {
        let (data, response) = try await session.data(from: url)
        guard let httpResp = response as? HTTPURLResponse else {
            FileHandle.standardError.write("HTTP error: non-HTTP response\n".data(using: .utf8)!)
            exit(1)
        }
        guard (200..<300).contains(httpResp.statusCode) else {
            FileHandle.standardError.write("HTTP error: status \(httpResp.statusCode)\n".data(using: .utf8)!)
            exit(1)
        }

        let decoder = JSONDecoder()
        struct Feed: Decodable {
            let items: [Item]
            struct Item: Decodable {
                let id: String
                let title: String
                let status: String
            }
        }
        let feed = try decoder.decode(Feed.self, from: data)

        var output = ""
        for item in feed.items where item.status == "open" {
            output += "\(item.id)\t\(item.title)\t\(base)/p/\(item.id)\n"
        }
        FileHandle.standardOutput.write(output.data(using: .utf8)!)
    } catch {
        FileHandle.standardError.write("HTTP/JSON error: \(error.localizedDescription)\n".data(using: .utf8)!)
        exit(1)
    }
}

// Top-level await support (Swift 5.7+)
let sem = DispatchSemaphore(value: 0)
Task {
    main()
    sem.signal()
}
sem.wait()
