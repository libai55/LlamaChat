//
//  ChatSources.swift
//  Camel
//
//  Created by Alex Rozanski on 30/03/2023.
//

import Foundation

fileprivate struct Payload: Codable {
  let sources: [ChatSource]
}

class ChatSource: Codable, Equatable, ObservableObject {
  let id: String
  @Published var name: String {
    didSet {
      chatSources?.didUpdate(self)
    }
  }
  let type: ChatSourceType
  let modelURL: URL

  fileprivate weak var chatSources: ChatSources?

  enum CodingKeys: CodingKey {
    case id
    case name
    case type
    case modelURL
  }

  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    id = try values.decode(String.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    type = try values.decode(ChatSourceType.self, forKey: .type)
    modelURL = try values.decode(URL.self, forKey: .modelURL)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(type, forKey: .type)
    try container.encode(modelURL, forKey: .modelURL)
  }

  init(name: String, type: ChatSourceType, modelURL: URL) {
    self.id = UUID().uuidString
    self.name = name
    self.type = type
    self.modelURL = modelURL
  }

  static func == (lhs: ChatSource, rhs: ChatSource) -> Bool {
    return lhs.id == rhs.id &&
    lhs.name == rhs.name &&
    lhs.type == rhs.type &&
    lhs.modelURL == rhs.modelURL
  }
}

class ChatSources: ObservableObject {
  @Published private(set) var sources: [ChatSource] = [] {
    didSet {
      persistSources()
    }
  }

  private lazy var persistedURL: URL? = {
    return applicationSupportDirectoryURL()?.appending(path: "sources.json")
  }()

  init() {
    loadSources()
  }

  func add(source: ChatSource) {
    sources.append(source)
  }

  func remove(source: ChatSource) {
    _ = sources.firstIndex(of: source).map { sources.remove(at: $0) }
  }

  fileprivate func didUpdate(_ source: ChatSource) {
    persistSources()
    objectWillChange.send()
  }

  private func loadSources() {
    guard
      let persistedURL,
      let jsonData = try? Data(contentsOf: persistedURL),
      let payload = try? JSONDecoder().decode(Payload.self, from: jsonData)
    else { return }

    payload.sources.forEach { source in
      source.chatSources = self
    }
    sources = payload.sources
  }

  private func persistSources() {
    guard let persistedURL else { return }

    let jsonEncoder = JSONEncoder()
    let json = try? jsonEncoder.encode(Payload(sources: sources))
    try? json?.write(to: persistedURL)
  }
}