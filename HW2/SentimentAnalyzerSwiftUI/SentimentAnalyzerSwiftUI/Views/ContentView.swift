//
//  ContentView.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Алексей on 23.01.2026.
//

// ContentView.swift
import SwiftUI
import NaturalLanguage

struct ContentView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    @State private var inputText = "Я очень доволен этим продуктом! Работает отлично."
    @State private var showingDetails = false
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Поле ввода текста
                    TextEditorView(text: $inputText)
                    
                    // Анализ в реальном времени
                    RealTimeAnalysisView(text: $inputText, viewModel: viewModel)
                    
                    // Кнопка анализа
                    AnalysisButton(viewModel: viewModel, text: inputText)
                    
                    // Результаты анализа
                    if viewModel.result != nil || viewModel.isAnalyzing || viewModel.errorMessage != nil {
                        AnalysisResultsView(viewModel: viewModel)
                    }
                    
                    // Тестовые примеры
                    TestCasesView(viewModel: viewModel, inputText: $inputText)
                    
                    // Детали анализа
                    AnalysisDetailsView(viewModel: viewModel, isExpanded: $showingDetails)
                    
                    // Кнопка автотестов
                    Button("Запустить автотесты") {
                        runTests()
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    // Кнопка импорта из фото
                    Button(action: {
                        showingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Импорт текста из фото")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle("Анализатор тональности")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetails.toggle() }) {
                        Image(systemName: showingDetails ? "info.circle.fill" : "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                PhotoImportView(importedText: $inputText)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func runTests() {
        let testTexts = [
            "Это отличный день! Я счастлив.",
            "Все ужасно, ничего не работает.",
            "Сегодня обычный день, ничего особенного.",
            "Ты дурак, иди отсюда!"
        ]
        
        for (index, text) in testTexts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 2) {
                inputText = text
                viewModel.analyzeText(text)
            }
        }
    }
}

// MARK: - Компонент поля ввода

struct TextEditorView: View {
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Введите текст для анализа:")
                .font(.headline)
            
            TextEditor(text: $text)
                .frame(height: 150)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                Text("Символов: \(text.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Очистить") {
                    text = ""
                }
                .font(.caption)
                .disabled(text.isEmpty)
            }
        }
    }
}

// MARK: - Кнопка анализа

struct AnalysisButton: View {
    @ObservedObject var viewModel: AnalysisViewModel
    let text: String
    
    var body: some View {
        Button(action: {
            viewModel.analyzeText(text)
        }) {
            HStack {
                Image(systemName: "text.magnifyingglass")
                Text("Анализировать тональность")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(text.isEmpty)
        .opacity(text.isEmpty ? 0.6 : 1)
    }
}

// MARK: - Тестовые примеры

struct TestCasesView: View {
    @ObservedObject var viewModel: AnalysisViewModel
    @Binding var inputText: String
    
    let testCases = [
        ("😊 Позитивный", "Я очень доволен покупкой! Отличный сервис и быстрая доставка. Рекомендую всем!"),
        ("😠 Негативный", "Ужасный продукт, сломался через день. Деньги на ветер, больше никогда не куплю."),
        ("😐 Нейтральный", "Приобрел товар для тестирования. Качество стандартное, доставка заняла 3 дня."),
        ("⚠️ Токсичный", "Ты полный идиот, если думаешь, что это работает!")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Тестовые примеры:")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(testCases, id: \.0) { title, text in
                        Button(action: {
                            inputText = text
                            viewModel.analyzeText(text)
                        }) {
                            VStack(spacing: 4) {
                                Text(title.components(separatedBy: " ").first ?? "")
                                    .font(.title2)
                                
                                Text(title.components(separatedBy: " ").last ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Анализ в реальном времени

struct RealTimeAnalysisView: View {
    @Binding var text: String
    @ObservedObject var viewModel: AnalysisViewModel
    @State private var realTimeResult: Sentiment? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Анализ в реальном времени:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let sentiment = realTimeResult, text.count > 10 {
                HStack {
                    Text(sentiment.emoji)
                    Text(sentiment.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(sentiment.color)
                }
                .transition(.opacity)
            }
        }
        .onChange(of: text) { newValue in
            // Запускаем анализ с задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                performQuickAnalysis(newValue)
            }
        }
    }
    
    private func performQuickAnalysis(_ text: String) {
        guard text.count > 10 else {
            realTimeResult = nil
            return
        }
        
        let positiveWords = ["хорошо", "отлично", "супер", "нравится", "доволен"]
        let negativeWords = ["плохо", "ужасно", "кошмар", "ненавижу", "сломался"]
        
        var score = 0
        let words = text.lowercased().split(separator: " ")
        
        for word in words {
            if positiveWords.contains(String(word)) { score += 1 }
            if negativeWords.contains(String(word)) { score -= 1 }
        }
        
        if score > 0 {
            realTimeResult = .positive
        } else if score < 0 {
            realTimeResult = .negative
        } else {
            realTimeResult = .neutral
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
