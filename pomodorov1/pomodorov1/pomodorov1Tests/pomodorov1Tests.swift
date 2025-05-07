//
//  pomodorov1Tests.swift
//  pomodorov1Tests
//
//  Created by Paolo Miguel Imperio on 4/5/25.
//

import Testing
@testable import pomodorov1

@MainActor
final class PomodoroTimerTests {
    // MARK: - Test Setup
    private var timer: ContentViewTestable!
    
    @MainActor
    func setUp() async {
        timer = ContentViewTestable()
        // Reset to known state before each test
        timer.resetTimer()
    }
    
    // MARK: - Timer Configuration Tests
    @Test func testInitialTimerConfiguration() async throws {
        await setUp()
        
        #expect(timer.workDuration == 25 * 60)
        #expect(timer.shortBreakDuration == 5 * 60)
        #expect(timer.longBreakDuration == 30 * 60)
        #expect(timer.workSessionsBeforeLongBreak == 4)
    }
    
    // MARK: - Initial State Tests
    @Test func testInitialState() async throws {
        await setUp()
        
        #expect(timer.timerState == .paused)
        #expect(timer.currentSessionType == .work)
        #expect(timer.timeRemaining == timer.workDuration)
        #expect(timer.completedWorkSessions == 0)
        #expect(timer.categories.count == 1)
        #expect(timer.categories["General"] == 0)
        #expect(timer.selectedCategory == "General")
    }
    
    // MARK: - Time Formatting Tests
    @Test func testTimeStringFormatting() async throws {
        await setUp()
        
        #expect(timer.timeString(150) == "02:30") // 2 minutes 30 seconds
        #expect(timer.timeString(3600) == "60:00") // 1 hour
        #expect(timer.timeString(0) == "00:00")
        #expect(timer.timeString(59) == "00:59")
    }
    
    // MARK: - State Description Tests
    @Test func testStateDescriptions() async throws {
        await setUp()
        
        // Initial paused state
        #expect(timer.stateDescription == "Ready to Start")
        
        // Work states
        timer.timerState = .work
        #expect(timer.stateDescription == "Work Time - Stay Focused!")
        
        // Paused after work
        timer.timerState = .paused
        timer.currentSessionType = .shortBreak
        #expect(timer.stateDescription == "Work Complete - Ready for Short Break")
        
        timer.currentSessionType = .longBreak
        #expect(timer.stateDescription == "Work Complete - Ready for Long Break")
        
        // Break states
        timer.timerState = .shortBreak
        #expect(timer.stateDescription == "Short Break - Relax!")
        
        timer.timerState = .longBreak
        #expect(timer.stateDescription == "Long Break - Recharge!")
    }
    
    // MARK: - Timer Operation Tests
    @Test func testWorkTimerOperation() async throws {
        await setUp()
        
        // Start work timer
        timer.startOrResumeTimer()
        #expect(timer.timerState == .work)
        #expect(timer.currentSessionType == .work)
        
        // Simulate 1 second passing
        timer.timeRemaining -= 1
        #expect(timer.timeRemaining == timer.workDuration - 1)
        
        // Pause timer
        timer.pauseTimer()
        #expect(timer.timerState == .paused)
        #expect(timer.currentSessionType == .work)
        
        // Resume timer
        timer.startOrResumeTimer()
        #expect(timer.timerState == .work)
    }
    
    @Test func testCompleteWorkSession() async throws {
        await setUp()
        
        // Complete a work session
        timer.startOrResumeTimer()
        timer.timeRemaining = 0 // Force completion
        timer.startTimer() // Manually call to trigger completion
        
        #expect(timer.timerState == .paused)
        #expect(timer.currentSessionType == .shortBreak)
        #expect(timer.completedWorkSessions == 1)
        #expect(timer.categories["General"] == timer.workDuration)
    }
    
    @Test func testShortBreakCycle() async throws {
        await setUp()
        
        // Complete work session
        timer.startOrResumeTimer()
        timer.timeRemaining = 0
        timer.startTimer()
        
        // Start short break
        timer.startBreak()
        #expect(timer.timerState == .shortBreak)
        #expect(timer.timeRemaining == timer.shortBreakDuration)
        
        // Complete break
        timer.timeRemaining = 0
        timer.startTimer()
        
        #expect(timer.timerState == .paused)
        #expect(timer.currentSessionType == .work)
        #expect(timer.timeRemaining == timer.workDuration)
    }
    
    @Test func testLongBreakCycle() async throws {
        await setUp()
        
        // Complete 4 work sessions
        for _ in 0..<4 {
            timer.startOrResumeTimer()
            timer.timeRemaining = 0
            timer.startTimer()
            timer.startBreak()
            timer.timeRemaining = 0
            timer.startTimer()
        }
        
        // Next break should be long
        timer.startOrResumeTimer()
        timer.timeRemaining = 0
        timer.startTimer()
        
        #expect(timer.currentSessionType == .longBreak)
        #expect(timer.timeRemaining == timer.longBreakDuration)
        
        // Complete long break
        timer.timeRemaining = 0
        timer.startTimer()
        
        #expect(timer.completedWorkSessions == 0) // Should reset counter
        #expect(timer.currentSessionType == .work)
    }
    
    // MARK: - Category Management Tests
    @Test func testCategoryManagement() async throws {
        await setUp()
        
        // Add new category
        timer.newCategoryName = "Programming"
        timer.categories["Programming"] = 0
        
        #expect(timer.categories.count == 2)
        #expect(timer.categories["Programming"] == 0)
        
        // Select new category
        timer.selectedCategory = "Programming"
        
        // Track time in category
        timer.startOrResumeTimer()
        timer.timeRemaining = 0
        timer.startTimer()
        
        #expect(timer.categories["Programming"] == timer.workDuration)
        #expect(timer.categories["General"] == 0) // Should remain unchanged
    }
    
    @Test func testResetTimer() async throws {
        await setUp()
        
        // Run partial session
        timer.startOrResumeTimer()
        timer.timeRemaining -= 100
        
        // Reset
        timer.resetTimer()
        
        #expect(timer.timerState == .paused)
        #expect(timer.currentSessionType == .work)
        #expect(timer.timeRemaining == timer.workDuration)
        #expect(timer.completedWorkSessions == 0)
    }
    
    // MARK: - Edge Case Tests
    @Test func testMultipleQuickPauses() async throws {
        await setUp()
        
        for _ in 0..<10 {
            timer.startOrResumeTimer()
            timer.pauseTimer()
        }
        
        #expect(timer.timerState == .paused)
        #expect(timer.timeRemaining == timer.workDuration)
    }
    
    @Test func testCategoryTimeAccumulation() async throws {
        await setUp()
        
        timer.newCategoryName = "Study"
        timer.categories["Study"] = 0
        timer.selectedCategory = "Study"
        
        // Complete two work sessions
        for _ in 0..<2 {
            timer.startOrResumeTimer()
            timer.timeRemaining = 0
            timer.startTimer()  
            timer.startBreak()
            timer.timeRemaining = 0
            timer.startTimer()
        }
        
        #expect(timer.categories["Study"] == timer.workDuration * 2)
    }
}
