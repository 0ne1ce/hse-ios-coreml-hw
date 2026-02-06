//
//  PropertyInput.swift
//  MortgageMLCalculator
//
//  Model representing property characteristics for price prediction
//

import Foundation

/// Входные параметры недвижимости для ML-модели
struct PropertyInput {
    var area: Double          // Площадь в м²
    var totalRooms: Int       // Количество комнат
    var bathrooms: Int        // Количество санузлов
    var garageSpaces: Int     // Парковочные места
    var distanceToCenter: Double  // Расстояние до центра в км
    var floor: Int            // Этаж
    var buildYear: Int        // Год постройки
    
    // MARK: - Default Values
    
    static let `default` = PropertyInput(
        area: 75,
        totalRooms: 3,
        bathrooms: 2,
        garageSpaces: 1,
        distanceToCenter: 2.5,
        floor: 5,
        buildYear: 2010
    )
    
    // MARK: - Validation
    
    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?
    }
    
    func validate() -> ValidationResult {
        // Проверка площади
        guard area >= 10 && area <= 1000 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Площадь должна быть от 10 до 1000 м²"
            )
        }
        
        // Проверка комнат
        guard totalRooms >= 1 && totalRooms <= 20 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Количество комнат должно быть от 1 до 20"
            )
        }
        
        // Проверка санузлов
        guard bathrooms >= 1 && bathrooms <= 10 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Количество санузлов должно быть от 1 до 10"
            )
        }
        
        // Проверка парковки
        guard garageSpaces >= 0 && garageSpaces <= 10 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Парковочных мест должно быть от 0 до 10"
            )
        }
        
        // Проверка расстояния
        guard distanceToCenter >= 0 && distanceToCenter <= 100 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Расстояние до центра должно быть от 0 до 100 км"
            )
        }
        
        // Проверка этажа
        guard floor >= 1 && floor <= 100 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Этаж должен быть от 1 до 100"
            )
        }
        
        // Проверка года постройки
        let currentYear = Calendar.current.component(.year, from: Date())
        guard buildYear >= 1900 && buildYear <= currentYear + 5 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Год постройки должен быть от 1900 до \(currentYear + 5)"
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil)
    }
}
