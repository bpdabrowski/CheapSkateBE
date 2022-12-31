//
//  File.swift
//  
//
//  Created by Brendyn Dabrowski on 12/30/22.
//

import Vapor
import Fluent

final class Expense: Model {
  static let schema = "expenses"
  
  @ID
  var id: UUID?
  
  @Field(key: "category")
  var category: String
  
  @Field(key: "amount")
  var amount: Double
  
  init() {}
  
  init(id: UUID? = nil, category: String, amount: Double) {
    self.id = id
    self.category = category
    self.amount = amount
  }
}

extension Expense: Content {}
