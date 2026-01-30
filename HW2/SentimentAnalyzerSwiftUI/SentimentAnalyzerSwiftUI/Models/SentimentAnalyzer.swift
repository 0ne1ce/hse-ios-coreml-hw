//
//  SentimentAnalyzer.swift
//  SentimentAnalyzerSwiftUI
//
//  Created by Алексей on 23.01.2026.
//

import NaturalLanguage
import CoreML

class SentimentAnalyzer {
    
    // MARK: - Базовый анализ NLP
    
    func analyze(_ text: String) async throws -> TextAnalysisResult {
        var details: [TextAnalysisResult.AnalysisDetail] = []
        
        // 1. Определение языка
        let language = try await detectLanguage(text)
        details.append(.init(title: "Язык", value: language, type: .info))
        
        // 2. Токенизация и статистика
        let (wordCount, sentences) = try await tokenize(text)
        details.append(.init(title: "Статистика",
                            value: "\(wordCount) слов, \(sentences) предложений",
                            type: .info))
        
        // 3. Анализ тональности
        let (sentiment, confidence) = try await analyzeSentiment(text)
        
        // 4. Определение частей речи
        let posDetails = try await analyzePartsOfSpeech(text)
        details.append(contentsOf: posDetails)
        
        // 5. Поиск именованных сущностей
        let entities = try await findNamedEntities(text)
        if !entities.isEmpty {
            details.append(.init(title: "Именованные сущности",
                                value: entities.joined(separator: ", "),
                                type: .info))
        }
        
        // 6. Проверка на токсичность
        let isToxic = try await checkToxicity(text)
        if isToxic {
            details.append(.init(title: "⚠️ Предупреждение",
                                value: "Обнаружен потенциально токсичный контент",
                                type: .warning))
        }
        
        return TextAnalysisResult(
            text: text,
            sentiment: sentiment,
            confidence: confidence,
            language: language,
            wordCount: wordCount,
            entities: entities,
            details: details,
            timestamp: Date()
        )
    }
    
    // MARK: - Детектирование языка
    
    private func detectLanguage(_ text: String) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else {
            return "Не определен"
        }
        
        return language.rawValue
    }
    
    // MARK: - Токенизация
    
    private func tokenize(_ text: String) async throws -> (wordCount: Int, sentenceCount: Int) {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        
        var wordCount = 0
        var sentenceCount = 0
        
        // Подсчет слов
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .tokenType,
                            options: [.omitPunctuation, .omitWhitespace]) { _, _ in
            wordCount += 1
            return true
        }
        
        // Подсчет предложений
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .sentence,
                            scheme: .tokenType) { _, _ in
            sentenceCount += 1
            return true
        }
        
        return (wordCount, sentenceCount)
    }
    
    // MARK: - Анализ тональности
    
    private func analyzeSentiment(_ text: String) async throws -> (Sentiment, Double) {
        // Сначала пробуем встроенный анализатор
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        if let sentimentTag = tagger.tag(at: text.startIndex,
                                         unit: .paragraph,
                                         scheme: .sentimentScore).0,
           let score = Double(sentimentTag.rawValue) {
            
            let sentiment: Sentiment
            switch score {
            case 0.3...:
                sentiment = .positive
            case -0.3..<0.3:
                sentiment = .neutral
            default:
                sentiment = .negative
            }
            
            return (sentiment, abs(score))
        }
        
        // Если встроенный не сработал, используем простой анализ по словам
        return analyzeWithKeywords(text)
    }
    
    // MARK: - Анализ по ключевым словам (fallback)
    
    private func analyzeWithKeywords(_ text: String) -> (Sentiment, Double) {
        let positiveWords = ["хорошо", "отлично", "супер", "нравится", "доволен", "счастлив", "прекрасно", "замечательно", "рекомендую", "быстрая"]
        let negativeWords = ["плохо", "ужасно", "кошмар", "ненавижу", "сломался", "разочарован", "отвратительно", "никогда"]
        
        var score = 0
        let words = text.lowercased().split(separator: " ")
        
        for word in words {
            if positiveWords.contains(where: { String(word).contains($0) }) { score += 1 }
            if negativeWords.contains(where: { String(word).contains($0) }) { score -= 1 }
        }
        
        let confidence = min(Double(abs(score)) / 5.0, 1.0)
        
        if score > 0 {
            return (.positive, confidence)
        } else if score < 0 {
            return (.negative, confidence)
        } else {
            return (.neutral, 0.5)
        }
    }
    
    // MARK: - Дополнительные функции NLP
    
    private func analyzePartsOfSpeech(_ text: String) async throws -> [TextAnalysisResult.AnalysisDetail] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var posCount: [String: Int] = [:]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: [.omitPunctuation, .omitWhitespace]) { tag, _ in
            if let tag = tag {
                posCount[tag.rawValue, default: 0] += 1
            }
            return true
        }
        
        return posCount.map { TextAnalysisResult.AnalysisDetail(
            title: "Часть речи: \($0.key)",
            value: "\($0.value)",
            type: .info
        )}
    }
    
    private func findNamedEntities(_ text: String) async throws -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var entities: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType,
                            options: [.joinNames]) { tag, range in
            if let tag = tag, tag != .otherWord {
                let entity = String(text[range])
                entities.append("\(entity) (\(tag.rawValue))")
            }
            return true
        }
        
        return entities
    }
    
    private func checkToxicity(_ text: String) async throws -> Bool {
        // Простая проверка по ключевым словам
        // В реальном приложении следует использовать ML модель
        let toxicPatterns = [
            "идиот", "дурак", "тупой", "ненавижу", "убей", "сдохни"
        ]
        
        let lowercasedText = text.lowercased()
        return toxicPatterns.contains { lowercasedText.contains($0) }
    }
    
    // MARK: - Ошибки
    
    enum AnalysisError: Error {
        case modelNotFound
        case invalidText
        case analysisFailed
    }
}
