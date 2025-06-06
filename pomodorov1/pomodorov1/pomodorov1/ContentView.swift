//
//  ContentView.swift
//  pomodorov1
//
//  Created by Paolo Miguel Imperio on 4/5/25.
//

import SwiftUI

/// A Pomodoro timer view with work sessions, short breaks, long breaks, and basic category tracking
struct ContentView: View {
    /// Represents the current state of the timer
    enum TimerState {
        case work       // Timer is running for work session
        case shortBreak // Timer is running for short break session
        case longBreak  // Timer is running for long break session
        case paused     // Timer is paused
        case completed
    }
    
    // MARK: - Timer Configuration
    /// Duration of work sessions in seconds (25 minutes)
    let workDuration: TimeInterval = 25 * 60
    /// Duration of short break sessions in seconds (5 minutes)
    let shortBreakDuration: TimeInterval = 5 * 60
    /// Duration of long break sessions in seconds (30 minutes)
    let longBreakDuration: TimeInterval = 30 * 60
    /// Number of work sessions before a long break
    let workSessionsBeforeLongBreak = 4
    
    // MARK: - State Properties
    /// Tracks remaining time for current session
    @State private var timeRemaining: TimeInterval
    /// Current operational state of the timer
    @State private var timerState: TimerState = .paused
    /// Reference to the timer object
    @State private var timer: Timer? = nil
    /// Last time the timer fired (for precise time tracking)
    @State private var lastFireDate: Date? = nil
    /// Tracks whether current session should be work or break
    @State private var currentSessionType: TimerState = .work
    /// Counts completed work sessions for long break scheduling
    @State private var completedWorkSessions = 0
    
    // MARK: - Category Tracking
    /// Dictionary tracking time spent per category
    @State private var categories: [String: TimeInterval] = ["General": 0]
    /// Currently selected category for work sessions
    @State private var selectedCategory = "General"
    /// Controls the display of the add category alert
    @State private var showingAddCategoryAlert = false
    /// New category name during creation
    @State private var newCategoryName = ""
    
    init() {
        // Initialize timeRemaining with work duration
        _timeRemaining = State(initialValue: workDuration)
    }
    
    var body: some View {
        VStack {
            // Category selection
            HStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(Array(categories.keys.sorted()), id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { showingAddCategoryAlert = true }) {
                    Image(systemName: "plus")
                }
                .alert("New Category", isPresented: $showingAddCategoryAlert) {
                    TextField("Category name", text: $newCategoryName)
                    Button("Add") {
                        if !newCategoryName.isEmpty {
                            categories[newCategoryName] = 0
                            newCategoryName = ""
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding(.horizontal)
            

            // Session counter
            Text("Session \(completedWorkSessions)/\(workSessionsBeforeLongBreak)")
                .font(.headline)
                .padding(.top)
            
            // Timer display (minutes:seconds)
            Text(timeString(timeRemaining))
                .font(.system(size: 64, weight: .bold))
                .padding()
            
            // MARK: - Control Buttons
            HStack(spacing: 20) {
                if timerState == .paused || timerState == .completed {
                    if currentSessionType == .work {
                        Button(action: initiateWorkSession) {
                            Text(timeRemaining == workDuration ? "Start Work" : "Resume")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: initiateBreakSession) {
                            Text(currentSessionType == .longBreak ? "Start Long Break" : "Start Short Break")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    if timeRemaining != workDuration {
                        Button(action: resetTimer) {
                            Text("Reset")
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    Button(action: pauseTimer) {
                        Text("Pause")
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: resetTimer) {
                        Text("Reset")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            
            // Status message
            Text(stateDescription)
                .font(.title2)
                .padding(.top, 20)
            
            // Category time display
            Text("\(selectedCategory): \(timeString(categories[selectedCategory] ?? 0))")
                .font(.subheadline)
                .padding(.top, 10)
        }
    }

    // MARK: - Helper Methods
    
    /// Converts time interval to formatted string (MM:SS)
    /// - Parameter time: Time interval in seconds
    /// - Returns: Formatted string (e.g. "25:00")
    func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Provides descriptive text for current timer state
        var stateDescription: String {
            switch (timerState, currentSessionType) {
            case (.paused, .work):
                return timeRemaining == workDuration ? "Ready to Start" : "Paused"
            case (.completed, .work):
                return "Break Complete - Ready for Work"
            case (.completed, .shortBreak):
                return "Work Complete - Ready for Short Break"
            case (.completed, .longBreak):
                return "Work Complete - Ready for Long Break"
            case (.work, _):
                return "Work Time - Stay Focused!"
            case (.shortBreak, _):
                return "Short Break - Relax!"
            case (.longBreak, _):
                return "Long Break - Recharge!"
            default:
                return ""
            }
        }
    // MARK: - Timer Control Methods
    
    func initiateWorkSession() {
            timerState = .work
            configureTimerState(for: .work)
            startTimer()
        }
        
        /// Initiates the appropriate break session
        func initiateBreakSession() {
            let breakType = determineNextBreakType()
            timerState = breakType
            configureTimerState(for: breakType)
            updateTimeRemaining(for: breakType)
            startTimer()
        }
        
        // MARK: - Timer Configuration
        
         func configureTimerState(for state: TimerState) {
            timerState = state
            lastFireDate = Date()
        }
        
         func updateTimeRemaining(for state: TimerState) {
            switch state {
            case .work:
                timeRemaining = workDuration
            case .shortBreak:
                timeRemaining = shortBreakDuration
            case .longBreak:
                timeRemaining = longBreakDuration
            case .paused:
                break
            case .completed:
                break
            }
        }
        
        // MARK: - Break Session Logic
        
         func determineNextBreakType() -> TimerState {
            return completedWorkSessions >= workSessionsBeforeLongBreak ? .longBreak : .shortBreak
        }
        
        // MARK: - Timer Operation
        
        /// Manages precise timer countdown and session transitions
         func startTimer() {
            invalidateExistingTimer()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updateTimerCountdown()
            }
        }
        
         func invalidateExistingTimer() {
            timer?.invalidate()
            timer = nil
        }
        
         func updateTimerCountdown() {
            guard let lastFireDate = lastFireDate else { return }
            
            // Calculate precise elapsed time
            let elapsedTime = Date().timeIntervalSince(lastFireDate)
            self.lastFireDate = Date()
            
            // Update remaining time
            timeRemaining = max(0, timeRemaining - elapsedTime)
            
            handleTimerCompletionIfNeeded()
        }
        
        // MARK: - Session Completion
        
    func handleTimerCompletionIfNeeded() {
        guard timeRemaining <= 0 else { return }
        
        invalidateExistingTimer()
        timerState = .completed
        
        switch currentSessionType {
        case .work:
            logWorkTimeToCategory()
            advanceSessionCount()
            transitionToBreak()
            
        case .shortBreak, .longBreak:
            if currentSessionType == .longBreak {
                resetSessionCount()
            }
            prepareForNewWorkSession()
            
        case .paused, .completed:
            break
        }
    }

        
         func logWorkTimeToCategory() {
            let timeSpent = workDuration - timeRemaining
            categories[selectedCategory] = (categories[selectedCategory] ?? 0) + timeSpent
        }
        
         func advanceSessionCount() {
            completedWorkSessions += 1
        }
        
         func transitionToBreak() {
            timerState = .completed
            currentSessionType = determineNextBreakType()
            updateTimeRemaining(for: currentSessionType)
        }
        
         /*func resetAfterBreak() {
            if currentSessionType == .longBreak {
                resetSessionCount()
            }
            prepareForNewWorkSession()
        }*/
        
         func resetSessionCount() {
            completedWorkSessions = 0
        }
        
         func prepareForNewWorkSession() {
            timerState = .completed
            currentSessionType = .work
            timeRemaining = workDuration
        }
        
        // MARK: - Control Actions
        
        /// Pauses the currently running timer
        func pauseTimer() {
            invalidateExistingTimer()
            timerState = .paused
            lastFireDate = nil
        }
        
        /// Resets all timer state to initial conditions
        func resetTimer() {
            invalidateExistingTimer()
            timerState = .paused
            currentSessionType = .work
            timeRemaining = workDuration
            lastFireDate = nil
            completedWorkSessions = 0
        }
    }
