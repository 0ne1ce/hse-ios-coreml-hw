//
//  MortgageCalculator.swift
//  MortgageMLCalculator
//
//  Service for mortgage payment calculations
//

import Foundation

/// Протокол калькулятора ипотеки
protocol MortgageCalculatorProtocol {
    func calculateMonthlyPayment(
        loanAmount: Double,
        annualRate: Double,
        termYears: Double
    ) -> Double
    
    func calculateResult(
        price: Double,
        settings: MortgageSettings
    ) -> MortgageResult
}

/// Калькулятор ипотечных платежей
final class MortgageCalculator: MortgageCalculatorProtocol {
    
    // MARK: - Singleton
    
    static let shared = MortgageCalculator()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Расчёт аннуитетного ежемесячного платежа
    /// - Parameters:
    ///   - loanAmount: Сумма кредита
    ///   - annualRate: Годовая процентная ставка (%)
    ///   - termYears: Срок кредита в годах
    /// - Returns: Ежемесячный платёж
    ///
    /// Формула аннуитетного платежа:
    /// P = L × [r(1+r)^n] / [(1+r)^n - 1]
    /// где:
    /// - P — ежемесячный платёж
    /// - L — сумма кредита
    /// - r — месячная процентная ставка
    /// - n — количество месяцев
    func calculateMonthlyPayment(
        loanAmount: Double,
        annualRate: Double,
        termYears: Double
    ) -> Double {
        guard loanAmount > 0 else { return 0 }
        
        let monthlyRate = (annualRate / 100) / 12
        let numberOfPayments = termYears * 12
        
        // Если ставка 0% — просто делим на количество месяцев
        guard monthlyRate > 0 else {
            return loanAmount / numberOfPayments
        }
        
        // Аннуитетная формула
        let compoundFactor = pow(1 + monthlyRate, numberOfPayments)
        let numerator = monthlyRate * compoundFactor
        let denominator = compoundFactor - 1
        
        guard denominator > 0 else {
            return loanAmount / numberOfPayments
        }
        
        return loanAmount * (numerator / denominator)
    }
    
    /// Полный расчёт ипотеки
    /// - Parameters:
    ///   - price: Стоимость недвижимости
    ///   - settings: Параметры ипотеки
    /// - Returns: Результат расчёта
    func calculateResult(
        price: Double,
        settings: MortgageSettings
    ) -> MortgageResult {
        let downPaymentAmount = price * settings.downPaymentPercent / 100
        let loanAmount = price - downPaymentAmount
        
        let monthlyPayment = calculateMonthlyPayment(
            loanAmount: loanAmount,
            annualRate: settings.interestRate,
            termYears: settings.loanTermYears
        )
        
        return MortgageResult(
            price: price,
            settings: settings,
            monthlyPayment: monthlyPayment
        )
    }
}
