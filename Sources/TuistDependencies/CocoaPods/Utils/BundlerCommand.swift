enum BundlerCommand {
    static func exec(_ arguments: [String]) -> [String] {
        ["/usr/bin/env", "bundle", "exec"] + arguments
    }
}
