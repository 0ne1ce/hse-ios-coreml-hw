//
//  ContentView.swift
//  MortgageMLCalculator
//
//  Main view composing all sections
//

import SwiftUI

/// Главный экран приложения
struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = MortgageViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Секция 1: Параметры недвижимости
                PropertyInputSection(viewModel: viewModel)
                
                // Секция 2: Условия ипотеки
                MortgageSettingsSection(viewModel: viewModel)
                
                // Секция 3: Результаты
                ResultsSection(viewModel: viewModel)
            }
            .navigationTitle("Ипотечный калькулятор")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Кнопка скрытия клавиатуры
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Готово") {
                        hideKeyboard()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    // MARK: - Private Methods
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
