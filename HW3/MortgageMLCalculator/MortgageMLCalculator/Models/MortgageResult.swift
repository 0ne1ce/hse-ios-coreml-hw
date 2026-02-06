//
//  MortgageResult.swift
//  MortgageMLCalculator
//
//  Model representing mortgage calculation results
//

import Foundation

/// Параметры ипотечного кредита
struct MortgageSettings {
    var downPaymentPercent: Double  // Первоначальный взнос (%)
    var loanTermYears: Double       // Срок кредита (лет)
    var interestRate: Double        // Процентная ставка (%)
    
    static let `default` = MortgageSettings(
        downPaymentPercent: 20,
        loanTermYears: 20,
        interestRate: 7.5
    )
    
    // MARK: - Computed Properties
    
    var monthlyInterestRate: Double {
        (interestRate / 100) / 12
    }
    
    var totalMonths: Double {
        loanTermYears * 12
    }
}

/// Результат расчёта ипотеки
struct MortgageResult {
    let predictedPrice: Double      // Прогнозируемая стоимость
    let downPaymentAmount: Double   // Сумма первоначального взноса
    let loanAmount: Double          // Сумма кредита
    let monthlyPayment: Double      // Ежемесячный платёж
    let totalPayment: Double        // Общая сумма выплат
    let overpayment: Double         // Переплата
    let overpaymentPercent: Double  // Переплата в процентах
    let settings: MortgageSettings  // Настройки ипотеки
    
    // MARK: - Initialization
    
    init(price: Double, settings: MortgageSettings, monthlyPayment: Double) {
        self.predictedPrice = price
        self.settings = settings
        
        self.downPaymentAmount = price * settings.downPaymentPercent / 100
        self.loanAmount = price - downPaymentAmount
        self.monthlyPayment = monthlyPayment
        self.totalPayment = monthlyPayment * settings.totalMonths
        self.overpayment = totalPayment - loanAmount
        self.overpaymentPercent = loanAmount > 0 ? (overpayment / loanAmount) * 100 : 0
    }
}

// MARK: - Currency Formatting Extension

extension Double {
    /// Форматирование числа как валюты (рубли)
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self)) ₽"
    }
    
    /// Форматирование как процент
    var asPercent: String {
        String(format: "%.1f%%", self)
    }
}
