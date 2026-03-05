import SwiftUI
import Combine

// MARK: - Brick Model
struct Brick: Identifiable {
    let id = UUID()
    var position: CGPoint
    let width: CGFloat
    let height: CGFloat
    var isDestroyed = false
    var color: Color

    var rect: CGRect {
        CGRect(x: position.x - width/2, y: position.y - height/2,
               width: width, height: height)
    }
}

// MARK: - Game Manager
class GameManager: ObservableObject {
    @Published var ballPosition = CGPoint(x: 200, y: 300)
    @Published var platformPosition = CGPoint(x: 200, y: 500)
    @Published var bricks: [Brick] = []
    @Published var score = 0
    @Published var remainingBricks = 0
    @Published var isRobotPlaying = false
    @Published var showModelPrediction = true

    // Статистика
    @Published var trainingProgress: Double = 0
    @Published var predictionError: Double = 1.0
    @Published var successfulExamples: Int = 0
    @Published var explorationRate: Double = 1.0

    // Статистика отбиваний
    @Published var playerSuccessfulHits: Int = 0
    @Published var robotSuccessfulHits: Int = 0
    @Published var playerMissedHits: Int = 0
    @Published var robotMissedHits: Int = 0
    @Published var lastReward: Double = 0.0
    @Published var totalReward: Double = 0.0

    // Предикшен модели
    @Published var predictedPlatformPosition: CGFloat = 200
    @Published var ballVelocity = CGPoint(x: 3, y: -3)

    // Настройки игры
    let platformWidth: CGFloat = 100
    let platformHeight: CGFloat = 20
    let ballSize: CGFloat = 20
    private var gameSize: CGSize = .zero
    private var timer: Timer?
    private let brickRows = 5
    private let brickCols = 8

    // Нейронная сеть с reinforcement learning
    private let neuralNetwork: ReinforcementNeuralNetwork

    // Обучение
    private var initialError: Double = 1.0
    private var hasCalculatedInitialError = false
    private var lastState: [Double] = []
    private var lastAction: Double = 0

    // Exploration/Exploitation
    private let minExplorationRate: Double = 0.1
    private let explorationDecay: Double = 0.995

    // Физика и границы
    private let gameAreaTopPadding: CGFloat = 60
    private let platformBottomPadding: CGFloat = 20

    // MARK: - Task A (Persistence)
    private var episodeCount: Int = 0
    private let saveInterval: Int = 20
    private var modelLoaded: Bool = false

    init() {
        neuralNetwork = ReinforcementNeuralNetwork(inputSize: 6)
        loadModel()
    }

    func setupGame(in size: CGSize) {
        gameSize = size
        platformPosition = CGPoint(x: size.width / 2, y: size.height - platformBottomPadding - platformHeight/2)
        ballPosition = CGPoint(x: size.width / 2, y: size.height - 200)
        ballVelocity = CGPoint(x: CGFloat.random(in: -3...3), y: -4)
        score = 0
        playerSuccessfulHits = 0
        robotSuccessfulHits = 0
        playerMissedHits = 0
        robotMissedHits = 0
        if !modelLoaded {
            totalReward = 0
        }

        createBricks(in: size)
        remainingBricks = bricks.filter { !$0.isDestroyed }.count

        startGame()
    }

    private func createBricks(in size: CGSize) {
        bricks.removeAll()
        let brickWidth = (size.width - 20) / CGFloat(brickCols)
        let brickHeight: CGFloat = 25

        for row in 0..<brickRows {
            for col in 0..<brickCols {
                let x = 10 + brickWidth * CGFloat(col) + brickWidth / 2
                let y = gameAreaTopPadding + brickHeight * CGFloat(row) + brickHeight / 2

                let hue = Double(row) / Double(brickRows)
                let color = Color(hue: hue, saturation: 0.8, brightness: 0.8)

                bricks.append(Brick(
                    position: CGPoint(x: x, y: y),
                    width: brickWidth - 2,
                    height: brickHeight - 2,
                    color: color
                ))
            }
        }
    }

    func startGame() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
    }

    func startTraining() {
        guard !modelLoaded else {
            print("startTraining skipped: model already loaded")
            return
        }
        trainingProgress = 0
        predictionError = 1.0
        initialError = 1.0
        explorationRate = 1.0
        hasCalculatedInitialError = false
    }

    func movePlatform(to x: CGFloat) {
        guard !isRobotPlaying else { return }

        platformPosition.x = min(max(x, platformWidth/2), gameSize.width - platformWidth/2)
    }

    func toggleGameMode() {
        isRobotPlaying.toggle()
    }

    private func getState() -> [Double] {
        let normalizedBallX = Double(ballPosition.x / gameSize.width)
        let normalizedBallY = Double((ballPosition.y - gameAreaTopPadding) / (gameSize.height - gameAreaTopPadding - platformBottomPadding - platformHeight))
        let normalizedVelocityX = Double(ballVelocity.x / 10.0)
        let normalizedVelocityY = Double(ballVelocity.y / 10.0)
        let normalizedPlatformX = Double(platformPosition.x / gameSize.width)
        let distanceToPlatform = Double(abs(ballPosition.x - platformPosition.x) / gameSize.width)

        return [
            normalizedBallX,
            normalizedBallY,
            normalizedVelocityX,
            normalizedVelocityY,
            normalizedPlatformX,
            distanceToPlatform
        ]
    }

    private func chooseAction(state: [Double]) -> Double {
        // Exploration/Exploitation trade-off
        if Double.random(in: 0...1) < explorationRate {
            // Random action (exploration)
            return Double.random(in: 0.1...0.9)
        } else {
            // Action from neural network (exploitation)
            return neuralNetwork.predict(inputs: state)
        }
    }

    private func calculateRewardForHit(success: Bool) -> Double {
        if success {
            return 1.0
        } else {
            return -1.0
        }
    }

    private func recordExperience(state: [Double], action: Double, reward: Double, nextState: [Double]) {
        neuralNetwork.addExperience(state: state, action: action, reward: reward, nextState: nextState)
        successfulExamples = neuralNetwork.getExperienceCount()

        // Обучение на опыте
        neuralNetwork.trainOnExperience()

        // Уменьшаем exploration rate
        if isRobotPlaying {
            explorationRate = max(minExplorationRate, explorationRate * explorationDecay)
        }

        // Обновляем статистику обучения
        updateTrainingProgress()
    }

    private func updateTrainingProgress() {
        let currentError = neuralNetwork.calculateError()
        predictionError = currentError

        // Вычисляем прогресс обучения
        if !hasCalculatedInitialError && successfulExamples >= 10 {
            initialError = max(currentError, 0.01)
            hasCalculatedInitialError = true
        }

        if hasCalculatedInitialError && initialError > 0 {
            let errorReduction = max(0, 1.0 - (currentError / initialError))
            trainingProgress = min(1.0, errorReduction)
        }

        // Обновляем exploration rate в UI
        explorationRate = max(minExplorationRate, explorationRate)
    }

    private func updateGame() {
        let oldBallPosition = ballPosition

        // Сохраняем текущее состояние для обучения (в любом режиме)
        if ballVelocity.y > 0 && ballPosition.y > gameSize.height * 0.6 {
            lastState = getState()

            if isRobotPlaying {
                lastAction = chooseAction(state: lastState)

                // Конвертируем предсказанное действие в позицию
                let targetX = CGFloat(lastAction) * gameSize.width
                predictedPlatformPosition = min(max(targetX, platformWidth/2), gameSize.width - platformWidth/2)
            } else {
                // В режиме человека действие - это текущая позиция платформы
                lastAction = Double(platformPosition.x / gameSize.width)
            }
        }

        // Обновляем позицию мяча
        ballPosition.x += ballVelocity.x
        ballPosition.y += ballVelocity.y

        // Проверяем столкновение со стенами
        checkWallCollisions()

        // Проверяем столкновение с платформой
        let hitPlatform = checkPlatformCollision(oldPosition: oldBallPosition)

        if hitPlatform {
            if isRobotPlaying {
                robotSuccessfulHits += 1
            } else {
                playerSuccessfulHits += 1
            }

            // Рассчитываем награду (в любом режиме)
            let reward = calculateRewardForHit(success: true)
            lastReward = reward
            totalReward += reward
            score += 1

            // Сохраняем опыт для обучения (в любом режиме)
            if !lastState.isEmpty {
                let nextState = getState()
                recordExperience(state: lastState, action: lastAction, reward: reward, nextState: nextState)
            }
        }

        // Проверяем столкновение с кирпичами
        checkBrickCollisions(oldPosition: oldBallPosition)

        // Проверяем, упал ли мяч ниже платформы
        let platformTopY = platformPosition.y - platformHeight/2
        if ballPosition.y > platformTopY && !hitPlatform {
            // Мяч пролетел мимо платформы - засчитываем промах
            if ballPosition.y > platformTopY + ballSize {
                if isRobotPlaying {
                    robotMissedHits += 1
                } else {
                    playerMissedHits += 1
                }

                // Рассчитываем награду (штраф) в любом режиме
                let reward = calculateRewardForHit(success: false)
                lastReward = reward
                totalReward += reward

                // Сохраняем опыт для обучения в любом режиме
                if !lastState.isEmpty {
                    let nextState = getState()
                    recordExperience(state: lastState, action: lastAction, reward: reward, nextState: nextState)
                }

                resetBall()
                score = max(0, score - 5)

                // Сбрасываем последнее состояние
                lastState = []
            }
        }

        // Если играет робот, используем предсказание модели
        if isRobotPlaying {
            useModelPrediction()
        }
    }

    private func checkWallCollisions() {
        let wallOffset: CGFloat = 5

        // Левая стенка
        if ballPosition.x <= ballSize/2 + wallOffset {
            ballPosition.x = ballSize/2 + wallOffset
            let currentSpeedX = abs(ballVelocity.x)
            ballVelocity.x = currentSpeedX
        }

        // Правая стенка
        if ballPosition.x >= gameSize.width - ballSize/2 - wallOffset {
            ballPosition.x = gameSize.width - ballSize/2 - wallOffset
            let currentSpeedX = abs(ballVelocity.x)
            ballVelocity.x = -currentSpeedX
        }

        // Верхняя стенка стакана
        if ballPosition.y <= gameAreaTopPadding + ballSize/2 {
            ballPosition.y = gameAreaTopPadding + ballSize/2
            ballVelocity.y = abs(ballVelocity.y)
        }
    }

    private func checkPlatformCollision(oldPosition: CGPoint) -> Bool {
        let platformRect = CGRect(
            x: platformPosition.x - platformWidth/2,
            y: platformPosition.y - platformHeight/2,
            width: platformWidth,
            height: platformHeight
        )

        let ballRect = CGRect(
            x: ballPosition.x - ballSize/2,
            y: ballPosition.y - ballSize/2,
            width: ballSize,
            height: ballSize
        )

        guard platformRect.intersects(ballRect) else { return false }

        let dx = ballPosition.x - platformPosition.x
        let dy = ballPosition.y - platformPosition.y
        let halfWidth = platformWidth/2
        let halfHeight = platformHeight/2

        let overlapX = halfWidth + ballSize/2 - abs(dx)
        let overlapY = halfHeight + ballSize/2 - abs(dy)

        if overlapX > overlapY {
            if dy > 0 {
                ballPosition.y = platformRect.maxY + ballSize/2 + 1
                ballVelocity.y = abs(ballVelocity.y)
            } else {
                ballPosition.y = platformRect.minY - ballSize/2 - 1

                let hitPoint = dx / (platformWidth/2)
                let maxBounceAngle: CGFloat = 75 * .pi / 180
                let bounceAngle = hitPoint * maxBounceAngle

                let speed = hypot(ballVelocity.x, ballVelocity.y) * 1.05
                ballVelocity.x = sin(bounceAngle) * speed
                ballVelocity.y = -cos(bounceAngle) * speed
            }
        } else {
            if dx > 0 {
                ballPosition.x = platformRect.maxX + ballSize/2 + 1
                let currentSpeedX = abs(ballVelocity.x)
                ballVelocity.x = currentSpeedX
            } else {
                ballPosition.x = platformRect.minX - ballSize/2 + 1
                let currentSpeedX = abs(ballVelocity.x)
                ballVelocity.x = -currentSpeedX
            }
        }

        let currentSpeed = sqrt(ballVelocity.x * ballVelocity.x + ballVelocity.y * ballVelocity.y)
        let minSpeed: CGFloat = 3.0
        if currentSpeed < minSpeed {
            let scale = minSpeed / currentSpeed
            ballVelocity.x *= scale
            ballVelocity.y *= scale
        }

        return true
    }

    private func checkBrickCollisions(oldPosition: CGPoint) {
        let ballRect = CGRect(
            x: ballPosition.x - ballSize/2,
            y: ballPosition.y - ballSize/2,
            width: ballSize,
            height: ballSize
        )

        for index in bricks.indices where !bricks[index].isDestroyed {
            if bricks[index].rect.intersects(ballRect) {
                bricks[index].isDestroyed = true

                let brickRect = bricks[index].rect

                let overlapLeft = ballRect.maxX - brickRect.minX
                let overlapRight = brickRect.maxX - ballRect.minX
                let overlapTop = ballRect.maxY - brickRect.minY
                let overlapBottom = brickRect.maxY - ballRect.minY

                let minOverlap = min(overlapLeft, overlapRight, overlapTop, overlapBottom)

                if minOverlap == overlapLeft {
                    ballPosition.x = brickRect.minX - ballSize/2
                    ballVelocity.x = -abs(ballVelocity.x)
                } else if minOverlap == overlapRight {
                    ballPosition.x = brickRect.maxX + ballSize/2
                    ballVelocity.x = abs(ballVelocity.x)
                } else if minOverlap == overlapTop {
                    ballPosition.y = brickRect.minY - ballSize/2
                    ballVelocity.y = -abs(ballVelocity.y)
                } else if minOverlap == overlapBottom {
                    ballPosition.y = brickRect.maxY + ballSize/2
                    ballVelocity.y = abs(ballVelocity.y)
                }

                score += 10
                remainingBricks = bricks.filter { !$0.isDestroyed }.count

                if remainingBricks == 0 {
                    createBricks(in: gameSize)
                    remainingBricks = bricks.count
                    ballVelocity.x *= 1.1
                    ballVelocity.y *= 1.1
                }

                break
            }
        }
    }

    private func useModelPrediction() {
        let smoothingFactor: CGFloat = 0.15

        if predictedPlatformPosition != 0 {
            let targetX = predictedPlatformPosition
            platformPosition.x = platformPosition.x * (1 - smoothingFactor) + targetX * smoothingFactor
        } else {
            if explorationRate > minExplorationRate {
                let randomMove = CGFloat.random(in: -2...2)
                platformPosition.x += randomMove
            }
        }

        platformPosition.x = min(max(platformPosition.x, platformWidth/2),
                               gameSize.width - platformWidth/2)

        if ballVelocity.y > 0 && ballPosition.y > gameSize.height * 0.6 {
            let state = getState()
            let action = chooseAction(state: state)
            let targetX = CGFloat(action) * gameSize.width
            predictedPlatformPosition = min(max(targetX, platformWidth/2), gameSize.width - platformWidth/2)
        }
    }

    private func resetBall() {
        ballPosition = CGPoint(x: platformPosition.x, y: platformPosition.y - platformHeight/2 - ballSize/2 - 1)

        let randomAngle = CGFloat.random(in: -45...45) * .pi / 180
        let speed: CGFloat = 5.0
        ballVelocity = CGPoint(
            x: sin(randomAngle) * speed,
            y: -cos(randomAngle) * speed
        )

        predictedPlatformPosition = platformPosition.x

        // Автосохранение каждые saveInterval эпизодов
        episodeCount += 1
        if episodeCount % saveInterval == 0 {
            saveModel()
        }
    }

    func resetGame() {
        setupGame(in: gameSize)
    }

    func resetTraining() {
        neuralNetwork.reset()
        successfulExamples = 0
        trainingProgress = 0
        predictionError = 1.0
        initialError = 1.0
        explorationRate = 1.0
        hasCalculatedInitialError = false
        isRobotPlaying = false
        totalReward = 0
        lastState = []
        episodeCount = 0
        NetworkPersistence.deleteModel()
    }

    // MARK: - Task A (Persistence)

    func saveModel() {
        let experiences = neuralNetwork.currentExperienceBuffer.map {
            Experience(state: $0.state, action: $0.action, reward: $0.reward, nextState: $0.nextState)
        }
        let state = NetworkState(
            weights: neuralNetwork.currentWeights,
            biases: neuralNetwork.currentBiases,
            experiences: experiences,
            explorationRate: explorationRate,
            totalReward: totalReward
        )
        NetworkPersistence.save(state: state)
        print("Model saving: \(experiences.count) experiences, exploration: \(explorationRate), reward: \(totalReward)")
    }

    private func loadModel() {
        guard let state = NetworkPersistence.load() else { return }
        neuralNetwork.loadWeights(state.weights, biases: state.biases)

        let buffer = state.experiences.map {
            (state: $0.state, action: $0.action, reward: $0.reward, nextState: $0.nextState)
        }
        neuralNetwork.loadExperienceBuffer(buffer)

        explorationRate = state.explorationRate
        totalReward = state.totalReward
        successfulExamples = neuralNetwork.getExperienceCount()
        modelLoaded = true

        print("Model loaded: \(state.experiences.count) experiences, exploration: \(state.explorationRate)")
    }

    // MARK: - TODO: Task B (Concurrency)
    // Перенесите trainOnExperience() в actor NeuralNetworkActor
}
