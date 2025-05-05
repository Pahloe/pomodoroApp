//
//  ContentView.swift
//  pomodorov1
//
//  Created by Paolo Miguel Imperio on 4/5/25.
//

import SwiftUI

struct ContentView: View {
    enum TimerState {
        case work
        case breakTime
        case paused
    }
    
    let workDuration: TimeInterval = 25 * 60
    let breakDuration: TimeInterval = 5 * 60
    
    @State private var timeRemaining: TimeInterval
    @State private var timerState: TimerState = .paused
    @State private var timer: Timer? = nil
    @State private var lastFireDate: Date? = nil
    @State private var currentSessionType: TimerState = .work // Track current session type
    
    init() {
        _timeRemaining = State(initialValue: workDuration)
    }
    
    var body: some View {
        VStack {
            Text(timeString(timeRemaining))
                .font(.system(size: 64, weight: .bold))
                .padding()
            
            HStack(spacing: 20) {
                if timerState == .paused {
                    Button(action: startOrResumeTimer) {
                        Text(timeRemaining == workDuration ? "Start Work" : "Resume")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
                    // Always show Pause button when timer is running
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
            
            Text(stateDescription)
                .font(.title2)
                .padding(.top, 20)
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var stateDescription: String {
        if timerState == .paused {
            return timeRemaining == workDuration ? "Ready to Start" : "Paused"
        }
        return currentSessionType == .work ? "Work Time - Stay Focused!" : "Break Time - Relax!"
    }
    
    func startOrResumeTimer() {
        lastFireDate = Date()
        if timeRemaining == workDuration {
            // Starting fresh work session
            currentSessionType = .work
            timerState = .work
        } else {
            // Resuming - restore the previous session type
            timerState = currentSessionType
        }
        startTimer()
    }
    
    func startBreak() {
        currentSessionType = .breakTime
        timerState = .breakTime
        timeRemaining = breakDuration
        lastFireDate = Date()
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let lastFireDate = lastFireDate else { return }
            
            let elapsed = Date().timeIntervalSince(lastFireDate)
            self.lastFireDate = Date()
            
            self.timeRemaining = max(0, self.timeRemaining - elapsed)
            
            if self.timeRemaining <= 0 {
                self.timer?.invalidate()
                if self.currentSessionType == .work {
                    self.startBreak()
                } else {
                    self.timerState = .paused
                    self.currentSessionType = .work // Reset to work for next session
                }
            }
        }
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timerState = .paused
        lastFireDate = nil
    }
    
    func resetTimer() {
        timer?.invalidate()
        timerState = .paused
        currentSessionType = .work
        timeRemaining = workDuration
        lastFireDate = nil
    }
}
