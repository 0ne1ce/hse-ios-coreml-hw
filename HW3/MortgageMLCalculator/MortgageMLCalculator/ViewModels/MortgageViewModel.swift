//
//  MortgageViewModel.swift
//  MortgageMLCalculator
//
//  ViewModel for mortgage calculator - handles business logic and state
//

import Foundation
import Combine

/// Состояния загрузки
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// ViewModel ипотечного калькулятора
@MainActor
final class MortgageViewModel: ObservableObject {
    
    // MARK: - Published Properties (State)
    
    // Входные данные недвижимости (строки для TextField)
    @Published var areaText: String = "75"
    @Published var roomsText: String = "3"
    @Published var bathroomsText: String = "2"
    @Published var garageText: String = "1"
    @Published var distanceText: String = "2.5"
    @Published var floorText: String = "5"
    @Published var buildYearText: String = "2010"
    
    // Настройки ипотеки
    @Published var mortgageSettings = MortgageSettings.default
    
    // Результаты
    @Published var result: MortgageResult?
    @Published var loadingState: LoadingState = .idle
    
    // MARK: - Private Properties
    
    private let predictionService: PricePredictionServiceProtocol
    private let mortgageCalculator: MortgageCalculatorProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var debounceTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    /// Текущие параметры недвижимости из текстовых полей
    var propertyInput: PropertyInput? {
        guard let area = Double(areaText),
              let rooms = Int(roomsText),
              let bathrooms = Int(bathroomsText),
              let garage = Int(garageText),
              let distance = Double(distanceText),
              let floor = Int(floorText),
              let buildYear = Int(buildYearText) else {
            return nil
        }
        
        return PropertyInput(
            area: area,
            totalRooms: rooms,
            bathrooms: bathrooms,
            garageSpaces: garage,
            distanceToCenter: distance,
            floor: floor,
            buildYear: buildYear
        )
    }
    
    /// Сообщение об ошибке (если есть)
    var errorMessage: String? {
        if case .error(let message) = loadingState {
            return message
        }
        return nil
    }
    
    /// Идёт ли расчёт
    var isCalculating: Bool {
        loadingState == .loading
    }
    
    // MARK: - Initialization
    
    init(
        predictionService: PricePredictionServiceProtocol = PricePredictionService.shared,
        mortgageCalculator: MortgageCalculatorProtocol = MortgageCalculator.shared
    ) {
        self.predictionService = predictionService
        self.mortgageCalculator = mortgageCalculator
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Объединяем все изменения параметров недвижимости
        Publishers.MergeMany(
            $areaText.map { _ in () },
            $roomsText.map { _ in () },
            $bathroomsText.map { _ in () },
            $garageText.map { _ in () },
            $distanceText.map { _ in () },
            $floorText.map { _ in () },
            $buildYearText.map { _ in () }
        )
        .dropFirst(7)  // Пропускаем начальные значения
        .sink { [weak self] _ in
            self?.debouncedCalculate()
        }
        .store(in: &cancellables)
        
        // Изменения настроек ипотеки — пересчёт только ипотеки (без ML)
        $mortgageSettings
            .dropFirst()
            .sink { [weak self] _ in
                self?.recalculateMortgageOnly()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Запуск расчёта при загрузке
    func onAppear() {
        calculateFull()
    }
    
    /// Полный пересчёт (ML + ипотека)
    func calculateFull() {
        debounceTask?.cancel()
        
        debounceTask = Task {
            await performFullCalculation()
        }
    }
    
    // MARK: - Private Methods
    
    /// Дебаунсированный расчёт (задержка 0.5 сек)
    private func debouncedCalculate() {
        debounceTask?.cancel()
        
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 секунды
            
            guard !Task.isCancelled else { return }
            
            await performFullCalculation()
        }
    }
    
    /// Выполнение полного расчёта
    private func performFullCalculation() async {
        // Проверяем валидность входных данных
        guard let property = propertyInput else {
            loadingState = .error("Введите корректные числовые значения")
            result = nil
            return
        }
        
        // Валидация
        let validation = property.validate()
        guard validation.isValid else {
            loadingState = .error(validation.errorMessage ?? "Ошибка валидации")
            result = nil
            return
        }
        
        loadingState = .loading
        
        do {
            // ML-предсказание цены
            let price = try await predictionService.predictPrice(for: property)
            
            // Расчёт ипотеки
            let mortgageResult = mortgageCalculator.calculateResult(
                price: price,
                settings: mortgageSettings
            )
            
            result = mortgageResult
            loadingState = .loaded
            
        } catch {
            loadingState = .error(error.localizedDescription)
            result = nil
        }
    }
    
    /// Пересчёт только ипотеки (без ML)
    private func recalculateMortgageOnly() {
        guard let currentResult = result else {
            // Если нет результата — запускаем полный расчёт
            debouncedCalculate()
            return
        }
        
        // Пересчитываем только ипотеку с текущей ценой
        result = mortgageCalculator.calculateResult(
            price: currentResult.predictedPrice,
            settings: mortgageSettings
        )
    }
}
