import Foundation

/// Detecta processos do Claude Code em execução
struct ProcessDetector {
    /// Busca processos do Claude Code
    /// - Returns: Array de PIDs encontrados
    func findClaudeProcesses() -> [Int32] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "claude"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        var pids: [Int32] = []

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()

            if let output = String(data: data, encoding: .utf8) {
                pids = output
                    .split(separator: "\n")
                    .compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
            }
        } catch {
            // Erro ao executar pgrep
            print("Erro ao buscar processos: \(error)")
        }

        return pids
    }

    /// Verifica se há algum processo do Claude Code em execução
    var isClaudeRunning: Bool {
        !findClaudeProcesses().isEmpty
    }

    /// Conta quantos processos do Claude Code estão rodando
    var claudeProcessCount: Int {
        findClaudeProcesses().count
    }
}
