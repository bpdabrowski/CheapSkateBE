import Fluent
import Vapor

func routes(_ app: Application) throws {
    let expenseController = ExpenseController()
    try app.register(collection: expenseController)
}
