//
//  User.swift
//  
//
//  Created by Brendyn Dabrowski on 1/15/23.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID
    var id: UUID?
       
    @Field(key: "name")
    var name: String
       
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$user)
    var expenses: [Expense]
    
    @OptionalField(key: "siwaIdentifier")
    var siwaIdentifier: String?

        
    init() {}
        
    init(
        id: UUID? = nil,
        name: String,
        username: String,
        password: String,
        siwaIdentifier: String? = nil
    ) {
        self.name = name
        self.username = username
        self.password = password
        self.siwaIdentifier = siwaIdentifier
    }
    
    final class Public: Content {
      var id: UUID?
      var name: String
      var username: String

      init(id: UUID?, name: String, username: String) {
        self.id = id
        self.name = name
        self.username = username
      }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic() }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}
