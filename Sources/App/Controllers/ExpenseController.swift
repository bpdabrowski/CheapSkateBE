//
//  ExpenseController.swift
//  
//
//  Created by Brendyn Dabrowski on 12/31/22.
//

import Vapor
import Fluent

struct ExpenseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let expenseRoutes = routes.grouped("api", "expenses")
        expenseRoutes.get(":userID", use: getAllHandler)
        expenseRoutes.get(
          ":userID",
          "search",
          use: getExpensesHandler)
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = expenseRoutes.grouped(
          tokenAuthMiddleware,
          guardAuthMiddleware)
        tokenAuthGroup.post(use: createExpense)
        tokenAuthGroup.put(":acronymID", use: updateHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Expense]> {
        guard let userId = req.headers.first(name: "user-id") else {
            throw Abort(.networkAuthenticationRequired)
        }
        
        return User.find(UUID(uuidString: userId), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$expenses.get(on: req.db)
            }
    }
    
    func createExpense(_ req: Request) throws -> EventLoopFuture<Expense> {
        let data = try req.content.decode(CreateExpenseData.self)
        let user = try req.auth.require(User.self)
        let expense = try Expense(
            category: data.category,
            amount: data.amount,
            date: data.date,
            userID: user.requireID()
        )
        return expense.save(on: req.db).map { expense }
    }
    
    func getExpensesHandler(_ req: Request) throws -> EventLoopFuture<[Expense]> {
        guard let userId = req.headers.first(name: "user-id") else {
            throw Abort(.networkAuthenticationRequired)
        }
        
        guard let searchTerm = req.query[Int.self, at: "month"] else {
            throw Abort(.badRequest)
        }
        
        return User.find(UUID(uuidString: userId), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { user in
                user.$expenses.get(on: req.db)
            }
            .map { expenses in
                expenses.filter { expense in
                    let component = Calendar.current.component(.month, from: Date(timeIntervalSinceReferenceDate: expense.date))
                    return component == searchTerm
                }
            }
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
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Expense> {
        let updateData = try req.content.decode(CreateExpenseData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Expense
            .find(req.parameters.get("expenseID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { expense in
                expense.category = updateData.category
                expense.amount = updateData.amount
                expense.date = updateData.date
                expense.$user.id = userID
                return expense.save(on: req.db).map { expense }
        }
    }

}

struct CreateExpenseData: Content {
    let category: String
    let amount: Double
    let date: TimeInterval
}

