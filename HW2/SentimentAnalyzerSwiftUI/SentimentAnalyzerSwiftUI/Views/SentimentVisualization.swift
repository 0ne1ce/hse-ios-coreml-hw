//
//  SentimentVisualization.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Алексей on 23.01.2026.
//

import SwiftUI

// MARK: - Карточка результата тональности

struct SentimentCard: View {
    let result: TextAnalysisResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Результат анализа")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(result.sentiment.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(result.sentiment.color)
                        
                        Text(result.sentiment.emoji)
                            .font(.title2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Уверенность")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(result.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            Text("Язык: \(result.language)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(result.sentiment.color.opacity(0.1))
        )
    }
}

// MARK: - Индикатор уверенности

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Уверенность модели:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая линия
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Индикатор уверенности
                    Rectangle()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence),
                               height: 8)
                        .cornerRadius(4)
                    
                    // Текущая позиция
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * CGFloat(confidence) - 8)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("0%")
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .fontWeight(.semibold)
                Spacer()
                Text("100%")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .orange
        }
    }
}

// MARK: - Строка деталей анализа

struct AnalysisDetailRow: View {
    let detail: TextAnalysisResult.AnalysisDetail
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(detail.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(detail.value)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        switch detail.type {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .success: return "checkmark.circle"
        case .error: return "xmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch detail.type {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
}

// MARK: - Вью результатов анализа

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isAnalyzing {
                ProgressView("Анализ текста...")
                    .padding()
            } else if let result = viewModel.result {
                SentimentCard(result: result)
                
                ConfidenceIndicator(confidence: result.confidence)
                
                Text("Детали анализа:")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(result.details.prefix(3), id: \.title) { detail in
                    AnalysisDetailRow(detail: detail)
                }
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

// MARK: - Вью ошибки

struct ErrorView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Детальный просмотр

struct AnalysisDetailsView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @Binding var isExpanded: Bool
    
    var body: some View {
        if isExpanded, !viewModel.analysisDetails.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Полные детали анализа")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { isExpanded = false }) {
                        Image(systemName: "chevron.up")
                    }
                }
                
                ForEach(viewModel.analysisDetails, id: \.title) { detail in
                    AnalysisDetailRow(detail: detail)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
