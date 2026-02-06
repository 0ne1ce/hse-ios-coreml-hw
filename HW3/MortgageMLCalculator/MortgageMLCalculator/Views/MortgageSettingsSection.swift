//
//  MortgageSettingsSection.swift
//  MortgageMLCalculator
//
//  View section for mortgage settings (sliders)
//

import SwiftUI

/// Секция настроек ипотеки
struct MortgageSettingsSection: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: MortgageViewModel
    
    // MARK: - Body
    
    var body: some View {
        Section {
            // Первоначальный взнос
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Первоначальный взнос")
                    Spacer()
                    Text("\(Int(viewModel.mortgageSettings.downPaymentPercent))%")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: $viewModel.mortgageSettings.downPaymentPercent,
                    in: 10...50,
                    step: 5
                )
                .tint(.blue)
            }
            .padding(.vertical, 4)
            
            // Срок кредита
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Срок кредита")
                    Spacer()
                    Text("\(Int(viewModel.mortgageSettings.loanTermYears)) лет")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: $viewModel.mortgageSettings.loanTermYears,
                    in: 5...30,
                    step: 1
                )
                .tint(.blue)
            }
            .padding(.vertical, 4)
            
            // Процентная ставка
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Процентная ставка")
                    Spacer()
                    Text(String(format: "%.1f%%", viewModel.mortgageSettings.interestRate))
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Slider(
                    value: $viewModel.mortgageSettings.interestRate,
                    in: 3...20,
                    step: 0.1
                )
                .tint(.blue)
            }
            .padding(.vertical, 4)
            
        } header: {
            Text("Условия ипотеки")
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        MortgageSettingsSection(viewModel: MortgageViewModel())
    }
}
