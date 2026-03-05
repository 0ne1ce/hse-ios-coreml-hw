//
//  Persistence.swift
//  ArkanoidRL
//
//  Created by B.RF Group on 27.02.2026.
//

import Foundation

// MARK: - Сохранение и загрузка весов нейросети
class NetworkPersistence {

    private static let fileName = "arkanoid_nn_state.json"

    // MARK: - Directory Setup

    private static func getModelDirectory() -> URL? {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let modelDir = appSupport.appendingPathComponent("ArkanoidRL", isDirectory: true)

        if !FileManager.default.fileExists(atPath: modelDir.path) {
            do {
                try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create model directory: \(error)")
                return nil
            }
        }
        return modelDir
    }

    private static func getModelURL() -> URL? {
        getModelDirectory()?.appendingPathComponent(fileName)
    }

    // MARK: - Save (на фоновом потоке, чтобы не блокировать UI)

    static func save(state: NetworkState) {
        DispatchQueue.global(qos: .utility).async {
            guard let url = getModelURL() else { return }
            do {
                let data = try JSONEncoder().encode(state)
                try data.write(to: url, options: .atomic)
                print("Model saved successfully (\(data.count) bytes)")
            } catch {
                print("Failed to save model: \(error)")
            }
        }
    }

    // MARK: - Load (синхронно при старте приложения)

    static func load() -> NetworkState? {
        guard let url = getModelURL(),
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(NetworkState.self, from: data)
        } catch {
            print("Failed to load model: \(error)")
            return nil
        }
    }

    // MARK: - Delete (при сбросе обучения)

    static func deleteModel() {
        guard let url = getModelURL() else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
