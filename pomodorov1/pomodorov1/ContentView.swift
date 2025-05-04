//
//  ContentView.swift
//  pomodorov1
//
//  Created by Paolo Miguel Imperio on 4/5/25.
//

import SwiftUI

struct ContentView: View {
    // Timer states
    enum TimerState {
        case work
        case breakTime
        case paused
    }
    
    // Timer configuration
    let workDuration: TimeInterval = 25 * 60 // 25 minutes
    let breakDuration: TimeInterval = 5 * 60  // 5 minutes
    
    @State private var timeRemaining: TimeInterval
    @State private var timerState: TimerState = .paused
    @State private var timer: Timer? = nil
    
    // Initialize timeRemaining with workDuration
    init() {
        _timeRemaining = State(initialValue: workDuration)
    }
    
    var body: some View {
        VStack {
            // Timer display
            Text(timeString(timeRemaining))
                .font(.system(size: 64, weight: .bold))
                .padding()
            
            // Timer controls
            HStack(spacing: 20) {
                if timerState == .paused {
                    Button(action: startWork) {
                        Text("Start Work")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
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
            
            // Current state indicator
            Text(stateDescription)
                .font(.title2)
                .padding(.top, 20)
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // Helper to format time as string
    func timeString(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // State description text
    var stateDescription: String {
        switch timerState {
        case .work: return "Work Time - Stay Focused!"
        case .breakTime: return "Break Time - Relax!"
        case .paused: return "Ready to Start"
        }
    }
    
    // Start work timer
    func startWork() {
        timerState = .work
        timeRemaining = workDuration
        startTimer()
    }
    
    // Start break timer
    func startBreak() {
        timerState = .breakTime
        timeRemaining = breakDuration
        startTimer()
    }
    
    // Start the timer
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                if timerState == .work {
                    startBreak()
                } else {
                    timerState = .paused
                }
            }
        }
    }
    
    // Pause the timer
    func pauseTimer() {
        timer?.invalidate()
        timerState = .paused
    }
    
    // Reset the timer
    func resetTimer() {
        timer?.invalidate()
        timerState = .paused
        timeRemaining = workDuration
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
