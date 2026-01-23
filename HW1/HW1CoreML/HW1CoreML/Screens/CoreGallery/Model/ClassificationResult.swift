//
//  ClassificationResult.swift
//  HW1CoreML
//
//  Created by Алексей on 23.01.2026.
//

import Foundation

struct ClassificationResult: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double
    
    var confidencePercent: String {
        String(format: "%.1f%%", confidence * 100)
    }
}
