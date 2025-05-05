//
//  pomodorov1App.swift
//  pomodorov1
//
//  Created by Paolo Miguel Imperio on 4/5/25.
//

import SwiftUI

/// A Pomodoro timer view with work sessions, short breaks, and long breaks
struct ContentView: View {
    /// Represents the current state of the timer
    enum TimerState {
        case work       // Timer is running for work session
        case shortBreak // Timer is running for short break session
        case longBreak  // Timer is running for long break session
        case paused     // Timer is paused
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
    
    // MARK: - Initialization
    init() {
        // Initialize timeRemaining with work duration
        _timeRemaining = State(initialValue: workDuration)
    }
    
    // MARK: - Main View
    var body: some View {
        VStack {
            // Session counter
            Text("Session \(completedWorkSessions)/\(workSessionsBeforeLongBreak)")
                .font(.headline)
                .padding(.top)
            
            // Timer display (minutes:seconds)
            Text(timeString(timeRemaining))
                .font(.system(size: 64, weight: .bold))
                .padding()
            
            // Control buttons
            HStack(spacing: 20) {
                if timerState == .paused {
                    // Show appropriate start button based on session type
                    if currentSessionType == .work {
                        Button(action: startOrResumeTimer) {
                            Text(timeRemaining == workDuration ? "Start Work" : "Resume")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        Button(action: startBreak) {
                            Text(currentSessionType == .longBreak ? "Start Long Break" : "Start Short Break")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Show reset button if timer isn't at initial state
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
                    // Show pause and reset buttons when timer is running
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
        if timerState == .paused {
            if currentSessionType == .shortBreak {
                return "Work Complete - Ready for Short Break"
            } else if currentSessionType == .longBreak {
                return "Work Complete - Ready for Long Break"
            }
            return timeRemaining == workDuration ? "Ready to Start" : "Paused"
        }
        
        switch currentSessionType {
        case .work: return "Work Time - Stay Focused!"
        case .shortBreak: return "Short Break - Relax!"
        case .longBreak: return "Long Break - Recharge!"
        case .paused: return "Paused"
        }
    }
    
    // MARK: - Timer Control Methods
    
    /// Starts or resumes the timer based on current state
    func startOrResumeTimer() {
        lastFireDate = Date()
        currentSessionType = .work
        timerState = .work
        startTimer()
    }
    
    /// Starts the appropriate break timer (short or long)
    func startBreak() {
        let isLongBreak = completedWorkSessions >= workSessionsBeforeLongBreak
        currentSessionType = isLongBreak ? .longBreak : .shortBreak
        timerState = isLongBreak ? .longBreak : .shortBreak
        timeRemaining = isLongBreak ? longBreakDuration : shortBreakDuration
        lastFireDate = Date()
        startTimer()
    }
    
    /// Begins the countdown timer with precise time tracking
    func startTimer() {
        // Invalidate any existing timer
        timer?.invalidate()
        
        // Start new timer with 0.1 second precision
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let lastFireDate = lastFireDate else { return }
            
            // Calculate exact time elapsed since last update
            let elapsed = Date().timeIntervalSince(lastFireDate)
            self.lastFireDate = Date()
            
            // Update remaining time
            self.timeRemaining = max(0, self.timeRemaining - elapsed)
            
            // Handle timer completion
            if self.timeRemaining <= 0 {
                self.timer?.invalidate()
                
                switch self.currentSessionType {
                case .work:
                    // Work session completed
                    self.completedWorkSessions += 1
                    self.timerState = .paused
                    // Determine next break type
                    self.currentSessionType = self.completedWorkSessions >= self.workSessionsBeforeLongBreak ?
                        .longBreak : .shortBreak
                    
                case .shortBreak, .longBreak:
                    // Break completed - reset for next work session
                    if self.currentSessionType == .longBreak {
                        self.completedWorkSessions = 0
                    }
                    self.timerState = .paused
                    self.currentSessionType = .work
                    self.timeRemaining = self.workDuration
                    
                case .paused:
                    break
                }
            }
        }
    }
    
    /// Pauses the running timer
    func pauseTimer() {
        timer?.invalidate()
        timerState = .paused
        lastFireDate = nil
    }
    
    /// Resets the timer to initial work state
    func resetTimer() {
        timer?.invalidate()
        timerState = .paused
        currentSessionType = .work
        timeRemaining = workDuration
        lastFireDate = nil
        completedWorkSessions = 0
    }
}
