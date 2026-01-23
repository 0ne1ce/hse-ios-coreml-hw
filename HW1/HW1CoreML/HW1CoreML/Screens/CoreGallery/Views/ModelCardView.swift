//
//  ModelCardView.swift
//  HW1CoreML
//
//  Created by Алексей on 23.01.2026.
//

import SwiftUI

struct ModelCardView: View {
    let model: MachineLearningModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: model.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if let source = model.sourceLabel {
                    BadgeView(text: source)
                }
                if model.isCustom {
                    BadgeView(text: "Custom")
                }
            }
            
            Spacer()
            
            Text(model.displayName)
                .font(.title.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: 320, height: 180)
        .background(
            LinearGradient(
                colors: model.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct BadgeView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.25))
            .clipShape(Capsule())
            .foregroundStyle(.white)
    }
}
