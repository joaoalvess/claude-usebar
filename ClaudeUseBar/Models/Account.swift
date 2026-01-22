import Foundation

/// Representa uma conta armazenada pelo app
struct Account: Codable, Identifiable, Equatable {
    let id: UUID
    let emailAddress: String
    let accountUuid: String
    let displayName: String
    let organizationName: String?
    let createdAt: Date
    var lastUsedAt: Date
    var order: Int

    init(
        id: UUID = UUID(),
        emailAddress: String,
        accountUuid: String,
        displayName: String,
        organizationName: String?,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date(),
        order: Int = 0
    ) {
        self.id = id
        self.emailAddress = emailAddress
        self.accountUuid = accountUuid
        self.displayName = displayName
        self.organizationName = organizationName
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.order = order
    }
}
