import SwiftUI

let required = ["ideviceinstaller", "idevicepair", "ideviceinfo", "idevice_id"]  // idevice* tools come from the libimobiledevice + ideviceinstaller brews

func findTool(_ name: String) -> String? {
    ["/opt/homebrew/bin/", "/usr/local/bin/"].map { $0 + name }.first { FileManager.default.isExecutableFile(atPath: $0) }
}

func missingTools() -> [String] { required.filter { findTool($0) == nil } }

// Opens Terminal (brew may ask for the password) and installs Homebrew if needed, then the packages.
func installDependencies() {
    let script = #"""
    #!/bin/zsh
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    if ! command -v brew >/dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1
      [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
      [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    fi
    brew install libimobiledevice ideviceinstaller
    echo; echo "Done. You can close this window and press Check again in the app."
    """#
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("install-idevice-deps.command")
    try? script.write(to: url, atomically: true, encoding: .utf8)
    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    NSWorkspace.shared.open(url)
}

struct AppItem: Identifiable { let id: String; let name: String; let version: String; let size: Int }

enum DeviceState { case none, unpaired, paired }

struct Disk { var capacity: Double = 0, available: Double = 0 }

func fmt(_ b: Double) -> String { ByteCountFormatter.string(fromByteCount: Int64(b), countStyle: .file) }

let cacheDir: URL = {
    let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("AppSweeper")
    try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
    return d
}()

// ponytail: icons come from the iTunes Search API (sends bundle IDs to Apple); sideloaded apps get no icon. Icons are cached on disk.
func fetchIcon(_ id: String) async -> NSImage? {
    let file = cacheDir.appendingPathComponent(id + ".png")
    if let img = NSImage(contentsOf: file) { return img }
    guard let q = URL(string: "https://itunes.apple.com/lookup?bundleId=\(id)"),
          let (d, _) = try? await URLSession.shared.data(from: q),
          let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
          let url = ((j["results"] as? [[String: Any]])?.first?["artworkUrl100"] as? String).flatMap(URL.init),
          let (img, _) = try? await URLSession.shared.data(from: url) else { return nil }
    try? img.write(to: file)
    return NSImage(data: img)
}

func run(_ tool: String, _ args: [String]) async -> (ok: Bool, out: String) {
    await Task.detached {
        let p = Process(), pipe = Pipe()
        guard let path = findTool(tool) else { return (false, "\(tool) not found") }
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardOutput = pipe; p.standardError = pipe
        do { try p.run() } catch { return (false, "\(error)") }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus == 0, String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
    }.value
}

@MainActor final class Model: ObservableObject {
    @Published var apps: [AppItem] = []
    @Published var checked = Set<String>()
    @Published var scope = "user"
    @Published var busy = false
    @Published var message: String?
    @Published var disk = Disk()
    @Published var icons: [String: NSImage] = [:]

    var freed: Double { Double(apps.filter { checked.contains($0.id) }.reduce(0) { $0 + $1.size }) }

    func loadDisk() async {
        let r = await run("ideviceinfo", ["-q", "com.apple.disk_usage"])
        var kv: [String: Double] = [:]
        for l in r.out.split(separator: "\n") {
            let p = l.components(separatedBy: ": ")
            if p.count == 2, let v = Double(p[1]) { kv[p[0]] = v }
        }
        disk = Disk(capacity: kv["TotalDataCapacity"] ?? 0, available: kv["TotalDataAvailable"] ?? 0)
    }

    func loadIcons() async {
        await withTaskGroup(of: (String, NSImage?).self) { g in
            for a in apps where icons[a.id] == nil { g.addTask { (a.id, await fetchIcon(a.id)) } }
            for await (id, img) in g { if let img { icons[id] = img } }
        }
    }

    @Published var state = DeviceState.none

    func refreshState() async {
        guard !(await run("idevice_id", ["-l"])).out.isEmpty else { state = .none; return }
        state = (await run("idevicepair", ["validate"])).ok ? .paired : .unpaired
    }

    func pair() async {
        busy = true
        message = (await run("idevicepair", ["pair"])).out
        busy = false
        await refreshState()
    }

    func list() async {
        busy = true; defer { busy = false }
        let r = await run("ideviceinstaller", ["list", "--\(scope)", "--xml", "-a", "CFBundleIdentifier",
                          "-a", "CFBundleDisplayName", "-a", "CFBundleShortVersionString",
                          "-a", "StaticDiskUsage", "-a", "DynamicDiskUsage"])
        guard r.ok, let arr = try? PropertyListSerialization.propertyList(from: Data(r.out.utf8), format: nil) as? [[String: Any]] else {
            message = r.out + "\n\n" + String(localized: "Is the iPhone connected, unlocked and paired?"); return
        }
        checked = []
        apps = arr.map { d in
            AppItem(id: d["CFBundleIdentifier"] as? String ?? "?", name: d["CFBundleDisplayName"] as? String ?? "?",
                    version: d["CFBundleShortVersionString"] as? String ?? "",
                    size: (d["StaticDiskUsage"] as? Int ?? 0) + (d["DynamicDiskUsage"] as? Int ?? 0))
        }.sorted { $0.size > $1.size }
        await loadDisk()
        await loadIcons()
    }

    func uninstall() async {
        busy = true
        var res: [String] = []
        for id in checked.sorted() {
            let r = await run("ideviceinstaller", ["uninstall", id])
            res.append("\(r.ok ? "✓" : "✗") \(id)" + (r.ok ? "" : ": \(r.out.split(separator: "\n").last ?? "")"))
        }
        busy = false
        message = res.joined(separator: "\n")
        await list()
    }
}

struct ContentView: View {
    @StateObject var m = Model()
    @State var confirm = false
    @State var missing = missingTools()
    @State var order = [KeyPathComparator(\AppItem.size, order: .reverse)]

    var body: some View {
        if missing.isEmpty { main } else { setup }
    }

    var setup: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
            Text("Required tools not found").font(.title2)
            Text("This app needs Homebrew and the packages libimobiledevice and ideviceinstaller.")
            Text("Missing: \(missing.joined(separator: ", "))").foregroundStyle(.secondary)
            HStack {
                Button("Install with Homebrew") { installDependencies() }.buttonStyle(.borderedProminent)
                Button("Check again") { missing = missingTools() }
            }
            Text("Opens Terminal; it installs Homebrew first if it is missing and may ask for your password.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(30)
        .frame(minWidth: 700, minHeight: 450)
    }

    var main: some View {
        VStack(spacing: 8) {
            HStack {
                Button { Task { await m.pair() } } label: {
                    switch m.state {
                    case .paired: Label("Paired", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .unpaired: Label("Pair", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    case .none: Label("No device", systemImage: "iphone.slash").foregroundStyle(.secondary)
                    }
                }
                .disabled(m.state == .none || m.busy)
                .help(m.state == .paired ? "Device is paired with this Mac" : "Pair this Mac with the connected device")
                Button("List") { Task { await m.list() } }
                Picker("", selection: $m.scope) {
                    Text("User").tag("user"); Text("System").tag("system"); Text("All").tag("all")
                }.frame(width: 110).labelsHidden()
                Spacer()
                if m.busy { ProgressView().controlSize(.small) }
                Button("Uninstall (\(m.checked.count))") { confirm = true }
                    .disabled(m.checked.isEmpty || m.busy)
            }
            Table(m.apps, sortOrder: $order) {
                TableColumn("") { a in
                    Toggle("", isOn: Binding(
                        get: { m.checked.contains(a.id) },
                        set: { if $0 { m.checked.insert(a.id) } else { m.checked.remove(a.id) } }
                    )).labelsHidden()
                }.width(24)
                TableColumn("Name", value: \.name) { a in
                    HStack {
                        Group {
                            if let img = m.icons[a.id] { Image(nsImage: img).resizable() }
                            else { RoundedRectangle(cornerRadius: 6).fill(.quaternary) }
                        }.frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(a.name)
                    }
                }
                TableColumn("Bundle ID", value: \.id)
                TableColumn("Version", value: \.version).width(70)
                TableColumn("Size", value: \.size) { a in Text(fmt(Double(a.size))) }.width(80)
            }
            .onChange(of: order) { _, o in m.apps.sort(using: o) }
            DiskBar(disk: m.disk, freed: m.freed)
        }
        .padding()
        .frame(minWidth: 700, minHeight: 450)
        .task {
            while !Task.isCancelled {
                await m.refreshState()
                try? await Task.sleep(for: .seconds(3))
            }
        }
        .alert("Result", isPresented: Binding(get: { m.message != nil }, set: { _ in m.message = nil })) {
            Button("OK") {}
        } message: { Text(m.message ?? "") }
        .confirmationDialog("Uninstall \(m.checked.count) app(s)?", isPresented: $confirm) {
            Button("Uninstall", role: .destructive) { Task { await m.uninstall() } }
        } message: { Text(m.checked.sorted().joined(separator: "\n")) }
    }
}

struct DiskBar: View {
    let disk: Disk, freed: Double
    var body: some View {
        let cap = max(disk.capacity, 1), used = max(cap - disk.available, 0), keep = max(used - freed, 0)
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { g in
                HStack(spacing: 0) {
                    Rectangle().fill(.blue).frame(width: g.size.width * keep / cap)
                    Rectangle().fill(.red).frame(width: g.size.width * min(freed, used) / cap)
                    Rectangle().fill(.gray.opacity(0.25))
                }.clipShape(RoundedRectangle(cornerRadius: 5))
            }.frame(height: 16)
            HStack(spacing: 14) {
                Label("Used \(fmt(keep))", systemImage: "circle.fill").foregroundStyle(.blue)
                if freed > 0 { Label("Would free \(fmt(freed))", systemImage: "circle.fill").foregroundStyle(.red) }
                Label("Free \(fmt(disk.available + freed))", systemImage: "circle.fill").foregroundStyle(.gray)
                Spacer()
                Text("Capacity \(fmt(cap))")
            }.font(.caption).labelStyle(.titleAndIcon)
        }
    }
}

final class Delegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }
}

@main struct AppSweeperApp: App {
    @NSApplicationDelegateAdaptor(Delegate.self) var delegate
    var body: some Scene { WindowGroup("AppSweeper") { ContentView() } }
}
