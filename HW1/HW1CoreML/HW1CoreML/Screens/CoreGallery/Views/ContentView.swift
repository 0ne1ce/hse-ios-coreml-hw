//
//  ContentView.swift
//  HW1CoreML
//
//  Created by Алексей on 22.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedModel: MachineLearningModel?
    
    private var availableModels: [MachineLearningModel] {
        MachineLearningModel.allCases.filter { $0.isAvailable }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ML Gallery")
                        .font(.largeTitle.bold())
                    Text("Выберите модель")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(availableModels) { model in
                            ModelCardView(model: model)
                                .onTapGesture {
                                    selectedModel = model
                                }
                        }
                    }
                    .padding(.horizontal)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                
                Spacer()
            }
            .sheet(item: $selectedModel) { model in
                ClassificationView(model: model)
            }
        }
    }
}
