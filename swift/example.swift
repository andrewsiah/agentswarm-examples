import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}
var base = ProcessInfo.processInfo.environment["AGENTSWARM_BASE_URL"] ?? "https://agentswarm.space"
while base.hasSuffix("/") { base.removeLast() }
guard let url = URL(string: base + "/api/feed?type=task"),
      ["http", "https"].contains(url.scheme ?? "") else { fail("HTTP error: invalid base URL") }
var request = URLRequest(url: url)
request.timeoutInterval = 30
let complete = DispatchSemaphore(value: 0)
var result: Data?
var failure: String?
URLSession.shared.dataTask(with: request) { data, response, error in
    defer { complete.signal() }
    if let error = error { failure = "HTTP error: \(error.localizedDescription)"; return }
    guard let response = response as? HTTPURLResponse else { failure = "HTTP error: missing response"; return }
    guard (200..<300).contains(response.statusCode) else { failure = "HTTP error: status \(response.statusCode)"; return }
    result = data
}.resume()
complete.wait()
if let failure = failure { fail(failure) }
guard let data = result else { fail("HTTP error: empty response") }
do {
    guard let document = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let items = document["items"] as? [[String: Any]] else { fail("JSON error: expected an items array") }
    var lines: [String] = []
    for item in items where item["status"] as? String == "open" {
        guard let id = item["id"] as? String, let title = item["title"] as? String else {
            fail("JSON error: missing task id or title")
        }
        lines.append("\(id)\t\(title)\t\(base)/p/\(id)\n")
    }
    FileHandle.standardOutput.write(Data(lines.joined().utf8))
} catch { fail("JSON error: \(error.localizedDescription)") }
