//
//  CreateAdminUser.swift
//  
//
//  Created by Brendyn Dabrowski on 2/9/23.
//

import Foundation
import Fluent
import Vapor

struct CreateAdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let passwordHash: String
        do {
            let password = UUID().uuidString
            passwordHash = try Bcrypt.hash(password)
            print("Admin Password: \(password)")
        } catch {
            return database.eventLoop.future(error: error)
        }
      
        let user = User(
            name: "Admin",
            username: "admin",
            password: passwordHash)
        return user.save(on: database)
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        User.query(on: database)
            .filter(\.$username == "admin")
            .delete()
    }
}
