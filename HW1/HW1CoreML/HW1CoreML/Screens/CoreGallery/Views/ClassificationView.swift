//
//  ClassificationView.swift
//  HW1CoreML
//
//  Created by Алексей on 23.01.2026.
//

import SwiftUI
import PhotosUI

struct ClassificationView: View {
    @StateObject private var viewModel: ClassificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(model: MachineLearningModel) {
        _viewModel = StateObject(wrappedValue: ClassificationViewModel(model: model))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    imageSection
                    
                    PhotosPicker(selection: $viewModel.imageSelection, matching: .images) {
                        Label("Выбрать фото", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    if !viewModel.results.isEmpty {
                        resultsSection
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(viewModel.model.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .overlay {
                if viewModel.isProcessing {
                    ProgressView("Классификация...")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private var imageSection: some View {
        Group {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                            Text("Выберите изображение")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Результаты")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(viewModel.results) { result in
                HStack {
                    Text(result.label.replacingOccurrences(of: "_", with: " ").capitalized)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(result.confidencePercent)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
            }
        }
    }
}
