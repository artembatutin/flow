//
//  TaskModels.swift
//  Flow
//
//  Created by Codex on 2026-04-22.
//

import Foundation
import SwiftUI

enum TaskStatus: String, CaseIterable, Codable, Identifiable {
    case todo
    case inProgress = "in-progress"
    case done

    var id: String { rawValue }

    init?(persistedRawValue rawValue: String) {
        switch rawValue {
        case "todo", "inbox", "next":
            self = .todo
        case "in-progress", "inProgress":
            self = .inProgress
        case "done":
            self = .done
        default:
            return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        guard let status = TaskStatus(persistedRawValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown task status: \(rawValue)"
            )
        }
        self = status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var displayName: String {
        switch self {
        case .todo:
            return "Todo"
        case .inProgress:
            return "In Progress"
        case .done:
            return "Done"
        }
    }

    var shortName: String {
        switch self {
        case .todo:
            return "Todo"
        case .inProgress:
            return "Doing"
        case .done:
            return "Done"
        }
    }

    var tintColor: Color {
        switch self {
        case .todo:
            return .blue
        case .inProgress:
            return .orange
        case .done:
            return .green
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low
    case medium
    case high
    case urgent

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var sortRank: Int {
        switch self {
        case .urgent:
            return 3
        case .high:
            return 2
        case .medium:
            return 1
        case .low:
            return 0
        }
    }

    var tintColor: Color {
        switch self {
        case .low:
            return .secondary
        case .medium:
            return .blue
        case .high:
            return .orange
        case .urgent:
            return .red
        }
    }
}

enum TaskSource: String, CaseIterable, Codable {
    case manual
    case voiceTask
}

enum TaxonomyColorToken: String, CaseIterable, Codable, Identifiable {
    case slate
    case blue
    case green
    case amber
    case coral
    case rose
    case grape

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .slate:
            return Color(nsColor: .secondaryLabelColor)
        case .blue:
            return .blue
        case .green:
            return .green
        case .amber:
            return .orange
        case .coral:
            return .red
        case .rose:
            return .pink
        case .grape:
            return .purple
        }
    }
}

struct TaskProject: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isArchived: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct TaskLabel: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var colorToken: TaxonomyColorToken
    var isArchived: Bool
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorToken: TaxonomyColorToken = .blue,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorToken = colorToken
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct TaskItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var notes: String?
    var status: TaskStatus
    var priority: TaskPriority
    var projectID: UUID?
    var labelIDs: [UUID]
    var source: TaskSource
    let createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var originalTranscript: String?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        status: TaskStatus = .todo,
        priority: TaskPriority = .medium,
        projectID: UUID? = nil,
        labelIDs: [UUID] = [],
        source: TaskSource = .manual,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        originalTranscript: String? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = status
        self.priority = priority
        self.projectID = projectID
        self.labelIDs = labelIDs
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.originalTranscript = originalTranscript
    }
}

struct TaskWorkspaceStore: Codable, Equatable {
    var schemaVersion: Int = 1
    var tasks: [TaskItem] = []
    var projects: [TaskProject] = []
    var labels: [TaskLabel] = []
}

struct TaskFilterState: Equatable {
    var selectedProjectID: UUID?
    var selectedLabelID: UUID?
    var selectedStatus: TaskStatus?
    var selectedPriority: TaskPriority?
    var searchText: String = ""

    static let `default` = TaskFilterState()
}

struct TaskCaptureResult: Equatable {
    let title: String
    let status: TaskStatus
    let priority: TaskPriority
    let projectID: UUID?
    let labelIDs: [UUID]
    let originalTranscript: String
}
