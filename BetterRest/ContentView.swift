//
//  ContentView.swift
//  BetterRest
//
//  Created by Kevin Darmawan on 23/12/24.
//
import CoreML
import SwiftUI

struct ContentView: View {
    @State private var sleepAmount = 8.0
    @State private var wakeUp = defaultWakeTime
    @State private var coffeeAmount = 1
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    var body: some View {
        NavigationStack {
            Spacer()
            Spacer()
            Form {
                Section {
                    Text("Desired amount of sleep")
                        .font(.headline)
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.5)
                }
                Section {
                    Text("What time you want to wake up")
                        .font(.headline)
                    DatePicker("Please enter a date", selection: $wakeUp, in: dateRange(), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                Section {
                    Text("Daily coffee intake")
                        .font(.headline)
                    Picker("The number of cups you drink", selection: $coffeeAmount) {
                        ForEach(0..<4, id: \.self) {
                            Text("^[\($0) cup](inflect:true)")
                        }
                    }
                }
                Button(action: calculateBedtime) {
                    Label("Calculate", systemImage: "arrow.right.circle.fill")
                }
                .alert(alertTitle, isPresented: $showingAlert) {
                    Button("Understood") { }
                }  message: {
                    Text(alertMessage)
                }
            }
            .navigationTitle("BetterRest")
        }
    }
    
    func dateRange() -> ClosedRange<Date> {
        let tomorrow = Date.now.addingTimeInterval(86400)
        let oneMonthAgo = wakeUp.addingTimeInterval(-886400)
        return oneMonthAgo...tomorrow
    }
    
    func calculateBedtime() {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            let recommendedSleepTime = wakeUp - prediction.actualSleep
            showingAlert = true
            alertTitle = "Your ideal bedtime is..."
            alertMessage = recommendedSleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
            showingAlert = true
        }
    }
}

#Preview {
    ContentView()
}
