//
//  MachineLearningModel.swift
//  HW1CoreML
//
//  Created by Алексей on 23.01.2026.
//

import SwiftUI

enum MachineLearningModel: String, CaseIterable, Identifiable {
    case mobileNetV2 = "MobileNetV2"
    case fruitsClassifier = "Fruits Classifier"
    case squeezeNet = "SqueezeNet"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .mobileNetV2:
            return "photo.artframe"
        case .fruitsClassifier:
            return "apple.logo"
        case .squeezeNet:
            return "cpu"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .mobileNetV2:
            return [.blue, .purple]
        case .fruitsClassifier:
            return [.green, .teal]
        case .squeezeNet:
            return [.orange, .red]
        }
    }
    
    var isCustom: Bool {
        switch self {
        case .fruitsClassifier:
            return true
        case .mobileNetV2, .squeezeNet:
            return false
        }
    }
    
    var sourceLabel: String? {
        switch self {
        case .squeezeNet:
            return "PyTorch"
        case .mobileNetV2, .fruitsClassifier:
            return nil
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .mobileNetV2:
            return true
        case .fruitsClassifier:
            return true
        case .squeezeNet:
            return true
        }
    }
}
