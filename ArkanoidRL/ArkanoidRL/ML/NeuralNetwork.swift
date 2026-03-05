import Foundation

class ReinforcementNeuralNetwork {
    private var weights: [[Double]]
    private var biases: [Double]
    private let learningRate: Double = 0.05
    private let discountFactor: Double = 0.95

    private var experienceBuffer: [(state: [Double], action: Double, reward: Double, nextState: [Double])] = []
    private let maxBufferSize = 500
    private var recentErrors: [Double] = []

    init(inputSize: Int, hiddenSize: Int = 8) {
        weights = Array(repeating: Array(repeating: 0.0, count: hiddenSize), count: inputSize)
        biases = Array(repeating: 0.0, count: hiddenSize)

        let scale = sqrt(2.0 / Double(inputSize + hiddenSize))
        for i in 0..<inputSize {
            for j in 0..<hiddenSize {
                weights[i][j] = Double.random(in: -scale...scale)
            }
        }

        for j in 0..<hiddenSize {
            biases[j] = Double.random(in: -0.1...0.1)
        }
    }

    func predict(inputs: [Double]) -> Double {
        var hiddenOutputs = [Double](repeating: 0, count: biases.count)

        // Прямой проход
        for j in 0..<biases.count {
            var sum = biases[j]
            for i in 0..<inputs.count {
                sum += inputs[i] * weights[i][j]
            }
            // ReLU активация
            hiddenOutputs[j] = max(0, sum)
        }

        // Вычисляем выход
        var output: Double = 0
        for j in 0..<hiddenOutputs.count {
            output += hiddenOutputs[j] * 0.1
        }

        // Сигмоида для ограничения выхода в [0, 1]
        return 1.0 / (1.0 + exp(-output))
    }

    func trainOnExperience() {
        guard !experienceBuffer.isEmpty else { return }

        // Берем случайные примеры из буфера
        let batchSize = min(32, experienceBuffer.count)
        var batchIndices = Set<Int>()
        while batchIndices.count < batchSize {
            batchIndices.insert(Int.random(in: 0..<experienceBuffer.count))
        }

        for index in batchIndices {
            let experience = experienceBuffer[index]

            // Q-learning update
            let currentQ = predict(inputs: experience.state)
            let nextQ = predict(inputs: experience.nextState)
            let targetQ = experience.reward + discountFactor * nextQ

            let error = targetQ - currentQ

            // Обратное распространение ошибки
            let gradient = error * currentQ * (1 - currentQ)

            // Обновляем веса
            for i in 0..<weights.count {
                for j in 0..<weights[i].count {
                    weights[i][j] += learningRate * gradient * experience.state[i]
                }
            }

            // Обновляем смещения
            for j in 0..<biases.count {
                biases[j] += learningRate * gradient * 0.1
            }

            // Сохраняем ошибку
            recentErrors.append(abs(error))
            if recentErrors.count > 100 {
                recentErrors.removeFirst()
            }
        }

        normalizeWeights()
    }

    private func normalizeWeights() {
        let maxWeight = 3.0
        for i in 0..<weights.count {
            for j in 0..<weights[i].count {
                if weights[i][j] > maxWeight {
                    weights[i][j] = maxWeight
                } else if weights[i][j] < -maxWeight {
                    weights[i][j] = -maxWeight
                }
            }
        }
    }

    func addExperience(state: [Double], action: Double, reward: Double, nextState: [Double]) {
        experienceBuffer.append((state: state, action: action, reward: reward, nextState: nextState))

        if experienceBuffer.count > maxBufferSize {
            experienceBuffer.removeFirst(100)
        }
    }

    func calculateError() -> Double {
        guard !recentErrors.isEmpty else { return 1.0 }
        return recentErrors.reduce(0, +) / Double(recentErrors.count)
    }

    func reset() {
        experienceBuffer.removeAll()
        recentErrors.removeAll()
    }

    func getExperienceCount() -> Int {
        return experienceBuffer.count
    }

    // MARK: - Persistence Support

    var currentWeights: [[Double]] { weights }
    var currentBiases: [Double] { biases }

    func loadWeights(_ newWeights: [[Double]], biases newBiases: [Double]) {
        guard newWeights.count == weights.count,
              newBiases.count == biases.count else {
            print("Warning: Saved model dimensions don't match. Ignoring saved weights.")
            return
        }
        for i in 0..<newWeights.count {
            guard newWeights[i].count == weights[i].count else {
                print("Warning: Saved weight row \(i) dimension mismatch. Ignoring saved weights.")
                return
            }
        }
        weights = newWeights
        biases = newBiases
    }

    var currentExperienceBuffer: [(state: [Double], action: Double, reward: Double, nextState: [Double])] {
        experienceBuffer
    }

    func loadExperienceBuffer(_ buffer: [(state: [Double], action: Double, reward: Double, nextState: [Double])]) {
        experienceBuffer = buffer
    }
}
