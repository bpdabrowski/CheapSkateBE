//
//  File.swift
//  
//
//  Created by Brendyn Dabrowski on 12/30/22.
//

import Fluent

struct CreateExpense: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("expenses")
      .id()
      .field("category", .string, .required)
      .field("amount", .double, .required)
      .field("date", .double, .required)
      .field("userID", .uuid, .required, .references("users", "id"))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("expenses").delete()
  }
}

