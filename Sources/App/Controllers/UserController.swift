//
//  UsersController.swift
//  
//
//  Created by Brendyn Dabrowski on 1/15/23.
//

import Vapor
import JWT
import Fluent

struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.post(use: createHandler)
        usersRoute.get(use: getAllHandler)
        usersRoute.get(":userID", use: getHandler)
        usersRoute.get(
          ":userID",
          "acronyms",
          use: getExpensesHandler)
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        usersRoute.post("siwa", use: signInWithApple)
    }

    func createHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        return user.save(on: req.db).map { user.convertToPublic() }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().convertToPublic()
    }

    func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .convertToPublic()
    }
    
    func getExpensesHandler(_ req: Request) -> EventLoopFuture<[Expense]> {
        User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$expenses.get(on: req.db)
            }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map { token }
    }
    
    func signInWithApple(_ req: Request) throws -> EventLoopFuture<Token> {
        let data = try req.content.decode(SignInWithAppleToken.self)
        guard let appIdentifier = Environment.get("IOS_APPLICATION_IDENTIFIER") else {
            throw Abort(.internalServerError)
        }
        return req.jwt
            .apple
            .verify(data.token, applicationIdentifier: appIdentifier)
            .flatMap { siwaToken -> EventLoopFuture<Token> in
                User.query(on: req.db)
                    .filter(\.$siwaIdentifier == siwaToken.subject.value)
                    .first()
                    .flatMap { user in
                        let userFuture: EventLoopFuture<User>
                        if let user = user {
                            userFuture = req.eventLoop.future(user)
                        } else {
                            guard let email = siwaToken.email,
                                  let name = data.name else {
                                return req.eventLoop.future(error: Abort(.badRequest))
                            }
                            let user = User(
                                name: name,
                                username: email,
                                password: UUID().uuidString,
                                siwaIdentifier: siwaToken.subject.value
                            )
                            userFuture = user.save(on: req.db).map { user }
                        }
                        return userFuture.flatMap { user in
                            let token: Token
                            do {
                                token = try Token.generate(for: user)
                            } catch {
                                return req.eventLoop.future(error: error)
                            }
                            return token.save(on: req.db).map { token }
                        }
                    }
            }
    }
}

struct SignInWithAppleToken: Content {
  let token: String
  let name: String?
}
