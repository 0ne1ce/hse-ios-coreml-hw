//
//  CoreGalleryViewModel.swift
//  HW1CoreML
//
//  Created by Алексей on 23.01.2026.
//

import Combine
import SwiftUI
import PhotosUI

@MainActor
final class ClassificationViewModel: ObservableObject {
    
    @Published var selectedImage: UIImage?
    @Published var results: [ClassificationResult] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var imageSelection: PhotosPickerItem? {
        didSet { loadImage() }
    }
    
    private let classifier: ImageClassificationService
    let model: MachineLearningModel
    
    init(model: MachineLearningModel) {
        self.model = model
        self.classifier = ImageClassificationServiceImpl(model: model)
    }
    
    private func loadImage() {
        guard let imageSelection else { return }
        
        Task {
            do {
                if let data = try await imageSelection.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    await classify()
                }
            } catch {
                errorMessage = "Ошибка загрузки картикнки"
            }
        }
    }
    
    func classify() async {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            results = try await classifier.classify(image: image)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        
        isProcessing = false
    }
}
