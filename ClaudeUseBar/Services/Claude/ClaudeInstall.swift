import Foundation

/// Resolve paths de instalação do Claude Code
enum ClaudeInstall {
    enum ConfigLocation: String {
        case dotClaudeDir = "~/.claude/.claude.json"
        case homeDir = "~/.claude.json"
    }

    enum InstallError: LocalizedError {
        case configNotFound
        case invalidPath(String)

        var errorDescription: String? {
            switch self {
            case .configNotFound:
                return "Arquivo de configuração do Claude Code não encontrado. Verifique se o Claude Code está instalado."
            case .invalidPath(let path):
                return "Caminho inválido: \(path)"
            }
        }
    }

    /// Resolve o caminho do arquivo de configuração do Claude Code
    /// - Returns: Tupla com URL do arquivo e sua localização
    /// - Throws: InstallError se o arquivo não for encontrado
    static func resolveConfigPath() throws -> (URL, ConfigLocation) {
        let fileManager = FileManager.default

        // Tenta primeiro ~/.claude/.claude.json
        if let dotClaudeDirPath = expandTilde("~/.claude/.claude.json") {
            let dotClaudeDirURL = URL(fileURLWithPath: dotClaudeDirPath)
            if fileManager.fileExists(atPath: dotClaudeDirURL.path) {
                return (dotClaudeDirURL, .dotClaudeDir)
            }
        }

        // Fallback para ~/.claude.json
        if let homeDirPath = expandTilde("~/.claude.json") {
            let homeDirURL = URL(fileURLWithPath: homeDirPath)
            if fileManager.fileExists(atPath: homeDirURL.path) {
                return (homeDirURL, .homeDir)
            }
        }

        throw InstallError.configNotFound
    }

    /// Expande o til (~) para o diretório home do usuário
    /// - Parameter path: Caminho com til
    /// - Returns: Caminho expandido ou nil se inválido
    static func expandTilde(_ path: String) -> String? {
        if path.hasPrefix("~") {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            return path.replacingOccurrences(of: "~", with: homeDir)
        }
        return path
    }

    /// Retorna o diretório home do usuário
    static var homeDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    /// Retorna o nome de usuário do sistema
    static var username: String {
        NSUserName()
    }
}
