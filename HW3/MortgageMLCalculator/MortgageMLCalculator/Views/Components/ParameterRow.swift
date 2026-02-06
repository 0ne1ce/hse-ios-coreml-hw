//
//  ParameterRow.swift
//  MortgageMLCalculator
//
//  Reusable component for numeric parameter input
//

import SwiftUI

/// Переиспользуемый компонент для ввода числовых параметров
struct ParameterRow: View {
    
    // MARK: - Properties
    
    let title: String
    @Binding var value: String
    let unit: String
    var keyboardType: UIKeyboardType = .decimalPad
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            TextField("0", text: $value)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
            
            Text(unit)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        ParameterRow(
            title: "Площадь (м²)",
            value: .constant("75"),
            unit: "м²"
        )
        ParameterRow(
            title: "Комнаты",
            value: .constant("3"),
            unit: "шт."
        )
        ParameterRow(
            title: "Расстояние",
            value: .constant("2.5"),
            unit: "км"
        )
    }
}
