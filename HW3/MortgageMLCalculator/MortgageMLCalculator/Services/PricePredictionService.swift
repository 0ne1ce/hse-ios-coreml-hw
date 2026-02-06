//
//  PricePredictionService.swift
//  MortgageMLCalculator
//
//  Service for property price prediction using CoreML
//

import Foundation
import CoreML

/// Протокол сервиса предсказания цен
protocol PricePredictionServiceProtocol {
    func predictPrice(for property: PropertyInput) async throws -> Double
}

/// Ошибки сервиса предсказания
enum PredictionError: LocalizedError {
    case modelLoadFailed
    case predictionFailed(String)
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed:
            return "Не удалось загрузить ML-модель"
        case .predictionFailed(let message):
            return "Ошибка предсказания: \(message)"
        case .invalidInput:
            return "Некорректные входные данные"
        }
    }
}

/// Сервис предсказания цен на недвижимость с использованием CoreML
final class PricePredictionService: PricePredictionServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = PricePredictionService()
    
    // MARK: - Private Properties
    
    private var model: HousePricePredictor?
    
    // MARK: - Initialization
    
    private init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all  // Использовать CPU + GPU + Neural Engine
            model = try HousePricePredictor(configuration: config)
        } catch {
            print("⚠️ Не удалось загрузить ML-модель: \(error)")
            model = nil
        }
    }
    
    // MARK: - Price Prediction
    
    /// Предсказание цены недвижимости
    /// - Parameter property: Параметры недвижимости
    /// - Returns: Предсказанная цена
    func predictPrice(for property: PropertyInput) async throws -> Double {
        // Выполняем предсказание в фоновом потоке
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PredictionError.modelLoadFailed)
                    return
                }
                
                do {
                    let price = try self.performPrediction(for: property)
                    continuation.resume(returning: price)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performPrediction(for property: PropertyInput) throws -> Double {
        // Если модель загружена — используем ML
        if let model = model {
            return try predictWithML(model: model, property: property)
        }
        
        // Иначе используем fallback-формулу
        return calculateFallbackPrice(for: property)
    }
    
    private func predictWithML(model: HousePricePredictor, property: PropertyInput) throws -> Double {
        let input = HousePricePredictorInput(
            area: Int64(property.area),
            total_rooms: Int64(property.totalRooms),
            bathrooms: Int64(property.bathrooms),
            garage_spaces: Int64(property.garageSpaces),
            distance_to_center: property.distanceToCenter,
            floor: Int64(property.floor),
            build_year: Int64(property.buildYear)
        )
        
        let prediction = try model.prediction(input: input)
        return prediction.price
    }
    
    /// Резервная формула расчёта цены (если ML недоступен)
    private func calculateFallbackPrice(for property: PropertyInput) -> Double {
        // Эвристическая формула на основе рыночных закономерностей
        let basePricePerSqm = 70_000.0
        let roomBonus = Double(property.totalRooms) * 250_000
        let bathroomBonus = Double(property.bathrooms) * 150_000
        let garageBonus = Double(property.garageSpaces) * 300_000
        let distanceDiscount = property.distanceToCenter * 120_000
        let yearBonus = Double(property.buildYear - 1970) * 15_000
        let floorAdjustment = property.floor <= 2 ? -100_000 : (property.floor > 10 ? 50_000 : 0)
        
        let total = (property.area * basePricePerSqm)
            + roomBonus
            + bathroomBonus
            + garageBonus
            - distanceDiscount
            + yearBonus
            + Double(floorAdjustment)
        
        return max(total, 1_500_000)  // Минимум 1.5 млн
    }
}
