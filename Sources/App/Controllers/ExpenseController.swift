//
//  File.swift
//  
//
//  Created by Brendyn Dabrowski on 12/31/22.
//

import Vapor
import Fluent

struct ExpenseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let expenseRoutes = routes.grouped("api", "expenses")
        expenseRoutes.get(use: getAllHandler)
        expenseRoutes.post(use: createExpense)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Expense]> {
        Expense.query(on: req.db).all()
    }
    
    func createExpense(_ req: Request) throws -> EventLoopFuture<Expense> {
        let expense = try req.content.decode(Expense.self)
        return expense.save(on: req.db).map { expense }
    }
}
