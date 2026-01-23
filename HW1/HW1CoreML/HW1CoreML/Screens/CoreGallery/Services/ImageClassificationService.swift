//
//  ImageClassificationService.swift
//  HW1CoreML
//
//  Created by Алексей on 23.01.2026.
//

import CoreML
import UIKit
import Vision

protocol ImageClassificationService {
    func classify(image: UIImage) async throws -> [ClassificationResult]
}

final class ImageClassificationServiceImpl: ImageClassificationService {
    
    private let model: MachineLearningModel
    private var vnModel: VNCoreMLModel?
    
    init(model: MachineLearningModel) {
        self.model = model
        setupModel()
    }
    
    private func setupModel() {
        do {
            let coreMLModel = try createCoreMLModel()
            vnModel = try VNCoreMLModel(for: coreMLModel)
        } catch {
            print("Ошибка при загрузке модели \(model.displayName): \(error)")
        }
    }
    
    private func createCoreMLModel() throws -> MLModel {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        
        switch model {
        case .mobileNetV2:
            return try MobileNetV2(configuration: config).model
        case .fruitsClassifier:
            return try FruitsClassifier(configuration: config).model
        case .squeezeNet:
            return try SqueezeNet(configuration: config).model
        }
    }
    
    func classify(image: UIImage) async throws -> [ClassificationResult] {
        guard let vnModel = vnModel else {
            throw ClassificationError.modelNotLoaded
        }
        
        guard let ciImage = CIImage(image: image) else {
            throw ClassificationError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let results = self.processResults(request.results)
                continuation.resume(returning: results)
            }
            
            request.imageCropAndScaleOption = .centerCrop
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func processResults(_ results: [VNObservation]?) -> [ClassificationResult] {
        guard let classifications = results as? [VNClassificationObservation] else {
            return []
        }
        
        let limit = model.isCustom ? classifications.count : 5
        
        return classifications
            .prefix(limit)
            .map { ClassificationResult(label: $0.identifier, confidence: Double($0.confidence)) }
    }
}

enum ClassificationError: LocalizedError {
    case modelNotLoaded
    case invalidImage
    case modelNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Модель не загружена"
        case .invalidImage:
            return "Не удалось обработать изображение"
        case .modelNotAvailable:
            return "Модель ещё не добавлена в проект"
        }
    }
}
