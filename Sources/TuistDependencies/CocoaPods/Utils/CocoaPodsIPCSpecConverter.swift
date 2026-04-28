import Foundation
import TSCBasic
import TuistSupport

enum CocoaPodsIPCSpecConverterError: FatalError, Equatable {
    case unexpectedOutput(expected: Int, got: Int)

    var description: String {
        switch self {
        case let .unexpectedOutput(expected, got):
            return "CocoaPods returned \(got) podspec conversion results, but Tuist expected \(expected)."
        }
    }

    var type: ErrorType {
        .abort
    }
}

struct CocoaPodsIPCSpecConverter {
    private static let endOfOutputSignal = "\n\r\n"
    private static var defaultMaximumConcurrentREPLProcesses: Int {
        min(4, max(1, ProcessInfo.processInfo.activeProcessorCount))
    }

    private let maximumConcurrentREPLProcesses: Int

    init(maximumConcurrentREPLProcesses: Int = CocoaPodsIPCSpecConverter.defaultMaximumConcurrentREPLProcesses) {
        self.maximumConcurrentREPLProcesses = max(1, maximumConcurrentREPLProcesses)
    }

    func convert(
        _ podspecPaths: [AbsolutePath],
        workingDirectory: AbsolutePath
    ) throws -> [String] {
        guard !podspecPaths.isEmpty else { return [] }

        let (replPaths, directPaths) = podspecPaths.partitioned { !$0.basename.containsWhitespace }

        var resultsByPath: [AbsolutePath: String] = [:]
        for (path, result) in zip(replPaths, try convertWithRepl(replPaths, workingDirectory: workingDirectory)) {
            resultsByPath[path] = result
        }
        for path in directPaths {
            resultsByPath[path] = try convertDirectly(path)
        }

        return try podspecPaths.map { path in
            guard let result = resultsByPath[path] else {
                throw CocoaPodsIPCSpecConverterError.unexpectedOutput(expected: podspecPaths.count, got: resultsByPath.count)
            }
            return result
        }
    }

    private func convertWithRepl(
        _ podspecPaths: [AbsolutePath],
        workingDirectory: AbsolutePath
    ) throws -> [String] {
        guard !podspecPaths.isEmpty else { return [] }

        let batches = Self.batches(
            from: podspecPaths,
            maximumBatchCount: maximumConcurrentREPLProcesses
        )
        logger.debug("Converting \(podspecPaths.count) podspecs using \(batches.count) CocoaPods IPC REPL process(es).")

        if batches.count == 1 {
            return try convertBatchWithRepl(batches[0], workingDirectory: workingDirectory)
        }

        let queue = DispatchQueue(label: "io.tuist.cocoapods-ipc-spec-converter", attributes: .concurrent)
        let group = DispatchGroup()
        let lock = NSLock()
        var batchResults = [Result<[String], Error>?](repeating: nil, count: batches.count)

        for (index, batch) in batches.enumerated() {
            group.enter()
            queue.async {
                defer { group.leave() }
                let result: Result<[String], Error>
                do {
                    result = .success(try convertBatchWithRepl(batch, workingDirectory: workingDirectory))
                } catch {
                    result = .failure(error)
                }

                lock.lock()
                batchResults[index] = result
                lock.unlock()
            }
        }

        group.wait()

        return try batchResults.flatMap { result in
            try result!.get()
        }
    }

    private func convertBatchWithRepl(
        _ podspecPaths: [AbsolutePath],
        workingDirectory: AbsolutePath
    ) throws -> [String] {
        let output = try run(
            BundlerCommand.exec(["pod", "ipc", "repl"]),
            standardInput: podspecPaths
                .map { "spec \($0.basename)" }
                .joined(separator: "\n") + "\n",
            workingDirectory: workingDirectory
        )

        return try Self.parseReplOutput(output, expectedOutputCount: podspecPaths.count)
    }

    static func batches<Element>(from elements: [Element], maximumBatchCount: Int) -> [[Element]] {
        guard !elements.isEmpty else { return [] }

        let batchCount = min(max(1, maximumBatchCount), elements.count)
        let batchSize = Int(ceil(Double(elements.count) / Double(batchCount)))

        return stride(from: 0, to: elements.count, by: batchSize)
            .map { startIndex in
                let endIndex = min(startIndex + batchSize, elements.count)
                return Array(elements[startIndex ..< endIndex])
            }
    }

    static func parseReplOutput(_ output: String, expectedOutputCount: Int) throws -> [String] {
        var chunks = output
            .components(separatedBy: endOfOutputSignal)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if chunks.first?.hasPrefix("version:") == true {
            chunks.removeFirst()
        }

        guard chunks.count == expectedOutputCount else {
            throw CocoaPodsIPCSpecConverterError.unexpectedOutput(expected: expectedOutputCount, got: chunks.count)
        }

        return chunks
    }

    private func convertDirectly(_ podspecPath: AbsolutePath) throws -> String {
        try System.shared.capture(BundlerCommand.exec(["pod", "ipc", "spec", podspecPath.pathString]))
    }

    private func run(
        _ arguments: [String],
        standardInput: String,
        workingDirectory: AbsolutePath
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: arguments[0])
        process.arguments = Array(arguments.dropFirst())
        process.environment = System.shared.env
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory.pathString)

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        var outputData = Data()
        var errorData = Data()
        let outputGroup = DispatchGroup()

        outputGroup.enter()
        DispatchQueue.global().async {
            outputData = stdout.fileHandleForReading.readDataToEndOfFile()
            outputGroup.leave()
        }

        outputGroup.enter()
        DispatchQueue.global().async {
            errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            outputGroup.leave()
        }

        try process.run()

        stdin.fileHandleForWriting.write(Data(standardInput.utf8))
        stdin.fileHandleForWriting.closeFile()

        process.waitUntilExit()
        outputGroup.wait()

        guard process.terminationStatus == 0 else {
            throw SystemError.terminated(command: arguments[0], code: process.terminationStatus, standardError: errorData)
        }

        return String(decoding: outputData, as: UTF8.self)
    }
}

private extension Array {
    func partitioned(_ belongsInFirstPartition: (Element) -> Bool) -> (matching: [Element], notMatching: [Element]) {
        var matching: [Element] = []
        var notMatching: [Element] = []

        for element in self {
            if belongsInFirstPartition(element) {
                matching.append(element)
            } else {
                notMatching.append(element)
            }
        }

        return (matching, notMatching)
    }
}

private extension String {
    var containsWhitespace: Bool {
        rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }
}
