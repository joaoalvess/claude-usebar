import Foundation

/// Representa o campo .oauthAccount do arquivo de configuração do Claude Code
struct OAuthAccount: Codable, Equatable {
    let accountUuid: String
    let emailAddress: String
    let displayName: String
    let organizationUuid: String?
    let organizationName: String?
    let organizationRole: String?
    let hasExtraUsageEnabled: Bool?
    let workspaceRole: String?

    enum CodingKeys: String, CodingKey {
        case accountUuid
        case emailAddress
        case displayName
        case organizationUuid
        case organizationName
        case organizationRole
        case hasExtraUsageEnabled
        case workspaceRole
    }

    init(
        accountUuid: String,
        emailAddress: String,
        displayName: String,
        organizationUuid: String? = nil,
        organizationName: String? = nil,
        organizationRole: String? = nil,
        hasExtraUsageEnabled: Bool? = nil,
        workspaceRole: String? = nil
    ) {
        self.accountUuid = accountUuid
        self.emailAddress = emailAddress
        self.displayName = displayName
        self.organizationUuid = organizationUuid
        self.organizationName = organizationName
        self.organizationRole = organizationRole
        self.hasExtraUsageEnabled = hasExtraUsageEnabled
        self.workspaceRole = workspaceRole
    }
}
