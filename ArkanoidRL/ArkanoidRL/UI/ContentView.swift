//
//  ContentView.swift
//  ArkanoidRL
//
//  Created by B.RF Group on 15.01.2026.
//

import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            // Основной интерфейс
            VStack(spacing: 0) {
                // Верхняя панель статистики
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Счет: \(gameManager.score)")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Блоков: \(gameManager.remainingBricks)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Статистика отбиваний
                    VStack(alignment: .center, spacing: 2) {
                        Text("У/Н")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        HStack(spacing: 15) {
                            VStack(spacing: 1) {
                                Text("👨")
                                    .font(.caption)
                                Text("\(gameManager.playerSuccessfulHits)/\(gameManager.playerMissedHits)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(gameManager.playerSuccessfulHits >= gameManager.playerMissedHits ? .green : .red)
                            }

                            VStack(spacing: 1) {
                                Text("🤖")
                                    .font(.caption)
                                Text("\(gameManager.robotSuccessfulHits)/\(gameManager.robotMissedHits)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(gameManager.robotSuccessfulHits >= gameManager.robotMissedHits ? .green : .red)
                            }
                        }
                    }

                    Spacer()

                    // Процент обучения и исследование
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Обучение: \(Int(gameManager.trainingProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(gameManager.trainingProgress > 0.7 ? .green : .orange)

                        Text("Исслед.: \(Int(gameManager.explorationRate * 100))%")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.9))
                .padding(.top, 50)

                // Статистика обучения
                VStack(spacing: 5) {
                    HStack {
                        Text("Примеры: \(gameManager.successfulExamples)")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Spacer()

                        Text("Ошибка:")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text(String(format: "%.3f", gameManager.predictionError))
                            .font(.caption)
                            .foregroundColor(gameManager.predictionError < 0.2 ? .green : .orange)

                        Spacer()

                        Text("Награда:")
                            .font(.caption2)
                            .foregroundColor(.gray)

                        Text(String(format: "%.1f", gameManager.totalReward))
                            .font(.caption)
                            .foregroundColor(gameManager.totalReward > 0 ? .green : .red)
                    }
                    .padding(.horizontal)

                    ProgressView(value: gameManager.trainingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: gameManager.trainingProgress > 0.7 ? .green : .orange))
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                }
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))

                // Игровое поле (стакан)
                GeometryReader { geometry in
                    ZStack {
                        // Фон стакана
                        Color.black

                        // Границы стакана
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .padding(1)

                        // Кирпичи
                        ForEach(gameManager.bricks) { brick in
                            if !brick.isDestroyed {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(brick.color)
                                    .frame(width: brick.width, height: brick.height)
                                    .position(x: brick.position.x, y: brick.position.y)
                            }
                        }

                        // Визуализация предсказания
                        if gameManager.showModelPrediction && gameManager.isRobotPlaying {
                            // Линия предсказания
                            Path { path in
                                let start = gameManager.ballPosition
                                let end = CGPoint(x: gameManager.predictedPlatformPosition,
                                                 y: gameManager.platformPosition.y)
                                path.move(to: start)
                                path.addLine(to: end)
                            }
                            .stroke(Color.yellow.opacity(0.3), style: StrokeStyle(
                                lineWidth: 1,
                                dash: [3, 3]
                            ))

                            // Точка предсказания
                            Circle()
                                .fill(Color.yellow.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .position(x: gameManager.predictedPlatformPosition,
                                         y: gameManager.platformPosition.y)
                        }

                        // Мяч
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.red, .orange]),
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 10
                                )
                            )
                            .frame(width: gameManager.ballSize, height: gameManager.ballSize)
                            .shadow(color: .red.opacity(0.5), radius: 3)
                            .position(gameManager.ballPosition)

                        // Платформа (прижата к низу)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .gray.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: gameManager.platformWidth, height: gameManager.platformHeight)
                            .overlay(
                                Capsule()
                                    .stroke(gameManager.isRobotPlaying ? Color.blue : Color.green, lineWidth: 2)
                            )
                            .shadow(color: gameManager.isRobotPlaying ? .blue.opacity(0.7) : .green.opacity(0.7), radius: 3)
                            .position(gameManager.platformPosition)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !gameManager.isRobotPlaying {
                                    let newX = min(max(value.location.x, gameManager.platformWidth/2),
                                                 geometry.size.width - gameManager.platformWidth/2)
                                    gameManager.movePlatform(to: newX)
                                }
                            }
                    )
                    .onAppear {
                        gameManager.setupGame(in: geometry.size)
                    }
                }

                // Нижняя панель управления
                HStack {
                    // Информация о режиме
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameManager.isRobotPlaying ? "🤖 Режим робота" : "👨 Режим человека")
                            .font(.caption)
                            .foregroundColor(gameManager.isRobotPlaying ? .blue : .green)
                    }

                    Spacer()

                    // Переключатель режима
                    Toggle("Робот", isOn: $gameManager.isRobotPlaying)
                        .font(.caption)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .frame(width: 60)

                    Spacer()

                    // Переключатель предсказаний
                    if gameManager.isRobotPlaying {
                        Toggle("Предсказания", isOn: $gameManager.showModelPrediction)
                            .font(.caption)
                            .toggleStyle(SwitchToggleStyle(tint: .yellow))
                            .frame(width: 110)
                        Spacer()
                    }

                    // Кнопки управления
                    HStack(spacing: 8) {
                        Button("Новая игра") {
                            gameManager.resetGame()
                        }
                        .font(.caption)
                        .foregroundColor(.red)

                        Button("Сброс обучения") {
                            gameManager.resetTraining()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.9))
                .padding(.bottom, 20)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            gameManager.startTraining()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                gameManager.saveModel()
            }
        }
    }
}
