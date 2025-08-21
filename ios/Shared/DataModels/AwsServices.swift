//
//  AwsServices.swift
//  awsary
//
//  Created by Tiago Rodrigues on 02/01/2023.
//

import Foundation

class AwsServices: ObservableObject {
    static let shared = AwsServices()

    @Published var services: [awsService] = []

    private let fileManager = FileManager.default
    private let mainUrl = Bundle.main.url(forResource: "aws_services", withExtension: "json")
    private var subUrl: URL?
    private var lastRandom: awsService = awsService(
        id: 10,
        name: "DeepRacer",
        longName: "AWS DeepRacer",
        shortDesctiption: "DeepRacer",
        imageURL: "https://static.tig.pt/awsary/logos/Arch_AWS-DeepRacer_64.svg",
        youtube_id: ""
    )

    init() {
        refresh()
    }

    func getNameOfLastRandom() -> String {
        return lastRandom.longName
    }

    func getLastRandom() -> awsService {
        return lastRandom
    }

    func getRandomElement() -> awsService {
        if let random = services.randomElement() {
            lastRandom = random
            return random
        }
        return lastRandom
    }

    func refresh() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let documentDirectory: URL?
            do {
                documentDirectory = try self.fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
            } catch {
                documentDirectory = nil
            }

            self.subUrl = documentDirectory?.appendingPathComponent("aws_services.json")

            let decoded: [awsService] = self.loadServices()
            let sorted = decoded.sorted { $0.name < $1.name }

            DispatchQueue.main.async {
                self.services = sorted
            }
        }
    }

    private func loadServices() -> [awsService] {
        guard let mainUrl = mainUrl else { return [] }

        if let subUrl = subUrl, fileManager.fileExists(atPath: subUrl.path) {
            if let decoded = decodeData(pathName: subUrl), !decoded.isEmpty {
                return decoded
            }
        }

        return decodeData(pathName: mainUrl) ?? []
    }

    private func decodeData(pathName: URL) -> [awsService]? {
        do {
            let jsonData = try Data(contentsOf: pathName)
            let decoder = JSONDecoder()
            return try decoder.decode([awsService].self, from: jsonData)
        } catch {
            return nil
        }
    }
}
