import Fluent
import Vapor
import PostgresNIO

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.post("register", use: { try await self.register(req: $0) })
    }

    func register(req: Request) async throws -> RegisterResponseDTO {
        do {
            try User.validate(content: req)

            let user = try req.content.decode(UserDTO.self).toModel()

            // Validate if the user exists
            if let _ = try await User.query(on: req.db)
                .filter(\.$username == user.username)
                .first()
            {
                throw Abort(.conflict, reason: "Username is already taken.")
            }

            // Hide the password
            user.password = try await req.password.async.hash(user.password)

            try await user.save(on: req.db)
        } catch {
            if let sqlError = error as? PSQLError {
                print(sqlError.code)
                print(sqlError.debugDescription)
                print(sqlError.query)
            }
        }
        return RegisterResponseDTO(error: false)
    }
}
