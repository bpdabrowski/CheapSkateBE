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
        expenseRoutes.get("search", use: searchHandler)
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Expense]> {
        Expense.query(on: req.db).all()
    }
    
    func createExpense(_ req: Request) throws -> EventLoopFuture<Expense> {
        let expense = try req.content.decode(Expense.self)
        return expense.save(on: req.db).map { expense }
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Expense]> {
        guard let searchTerm = req.query[Int.self, at: "month"] else {
            throw Abort(.badRequest)
        }
    
        return Expense.query(on: req.db)
            .all()
            .map { expenses in
                expenses.filter { expense in
                    let component = Calendar.current.component(.month, from: Date(timeIntervalSinceReferenceDate: expense.date))
                    return component == searchTerm
                }
            }
    }
}
