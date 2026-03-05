import Foundation

// MARK: - Структура для сохранения опыта обучения
struct Experience: Codable {
    let state: [Double]
    let action: Double
    let reward: Double
    let nextState: [Double]
}

// MARK: - Полный снимок состояния нейросети для персистенции
struct NetworkState: Codable {
    let weights: [[Double]]
    let biases: [Double]
    let experiences: [Experience]
    let explorationRate: Double
    let totalReward: Double
}
