import XCTest

@MainActor
final class TranscriptionAndAnalyticsTests: XCTestCase {
    func testLegacyAndTypedTranscriptionSessionsDecode() throws {
        let json = """
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "timestamp": "2026-04-22T12:00:00Z",
            "transcription": "legacy session",
            "duration": 2.0,
            "modelUsed": "base.en",
            "wordCount": 2,
            "characterCount": 14
          },
          {
            "id": "22222222-2222-2222-2222-222222222222",
            "timestamp": "2026-04-22T12:05:00Z",
            "transcription": "typed task",
            "duration": 1.0,
            "modelUsed": "base.en",
            "captureKind": "task",
            "linkedTaskID": "33333333-3333-3333-3333-333333333333",
            "wordCount": 2,
            "characterCount": 10
          }
        ]
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let sessions = try decoder.decode([TranscriptionSession].self, from: Data(json.utf8))

        XCTAssertEqual(sessions[0].captureKind, .dictation)
        XCTAssertNil(sessions[0].linkedTaskID)
        XCTAssertEqual(sessions[1].captureKind, .task)
        XCTAssertEqual(sessions[1].linkedTaskID, UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
    }

    func testAnalyticsIgnoreTaskSessions() throws {
        let analytics = AnalyticsManager(metricsFileURL: temporaryURL())

        analytics.recordSession(TranscriptionSession(
            transcription: "task capture",
            duration: 1.0,
            modelUsed: "base.en",
            captureKind: .task,
            linkedTaskID: UUID()
        ))

        XCTAssertEqual(analytics.metrics.totalSessions, 0)
        XCTAssertEqual(analytics.metrics.totalWords, 0)

        analytics.recordSession(TranscriptionSession(
            transcription: "dictation capture",
            duration: 1.0,
            modelUsed: "base.en",
            captureKind: .dictation
        ))

        XCTAssertEqual(analytics.metrics.totalSessions, 1)
        XCTAssertEqual(analytics.metrics.totalWords, 2)
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("usage_metrics.json")
    }
}
