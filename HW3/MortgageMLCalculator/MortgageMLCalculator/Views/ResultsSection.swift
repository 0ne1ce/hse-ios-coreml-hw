//
//  ResultsSection.swift
//  MortgageMLCalculator
//
//  View section for displaying calculation results
//

import SwiftUI

/// Секция отображения результатов расчёта
struct ResultsSection: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: MortgageViewModel
    
    // MARK: - Body
    
    var body: some View {
        Section {
            Group {
                if viewModel.isCalculating {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if let result = viewModel.result {
                    resultView(result: result)
                } else {
                    placeholderView
                }
            }
        } header: {
            Text("Результаты расчёта")
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Рассчитываем...")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func errorView(message: String) -> some View {
        Label {
            Text(message)
                .foregroundColor(.orange)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderView: some View {
        Text("Введите параметры для расчёта")
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
    }
    
    private func resultView(result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Прогнозируемая стоимость
            priceView(result: result)
            
            Divider()
            
            // Детали ипотеки
            mortgageDetailsView(result: result)
        }
        .padding(.vertical, 8)
    }
    
    private func priceView(result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Прогнозируемая стоимость")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(result.predictedPrice.asCurrency)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
    }
    
    private func mortgageDetailsView(result: MortgageResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ипотечный расчёт")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Первоначальный взнос
            DetailRow(
                title: "Первоначальный взнос:",
                value: "\(Int(result.settings.downPaymentPercent))%",
                valueColor: .primary
            )
            
            // Сумма кредита
            DetailRow(
                title: "Сумма кредита:",
                value: result.loanAmount.asCurrency,
                valueColor: .primary
            )
            
            // Ежемесячный платёж (выделен)
            DetailRow(
                title: "Ежемесячный платёж:",
                value: result.monthlyPayment.asCurrency,
                valueColor: .green,
                isHighlighted: true
            )
            
            // Переплата
            DetailRow(
                title: "Переплата за \(Int(result.settings.loanTermYears)) лет:",
                value: result.overpayment.asCurrency,
                valueColor: .red
            )
            
            // Процент переплаты
            DetailRow(
                title: "Переплата:",
                value: result.overpaymentPercent.asPercent,
                valueColor: .orange,
                font: .caption
            )
        }
    }
}

// MARK: - Detail Row Component

private struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    var isHighlighted: Bool = false
    var font: Font = .body
    
    var body: some View {
        HStack {
            Text(title)
                .font(font)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .headline : font)
                .fontWeight(isHighlighted ? .bold : .medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        ResultsSection(viewModel: {
            let vm = MortgageViewModel()
            vm.result = MortgageResult(
                price: 7_500_000,
                settings: .default,
                monthlyPayment: 52_340
            )
            return vm
        }())
    }
}
