import Fluent
import PostgresNIO
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")

        api.post("register", use: { try await self.register(req: $0) })
    }

    func register(req: Request) async throws -> HTTPStatus {
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

        return HTTPStatus.created
    }
}
