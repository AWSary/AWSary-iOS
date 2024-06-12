import SwiftUI
import EventKit

struct AAIplannerContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedEventName = "Architecting on AWS"
    @State private var startDate = Date()
    @State private var selectedTimeZone = TimeZone.current.identifier
    @State private var accessGranted = false
    
    let eventNames = AAIEventData.eventNames
    let eventSequences = AAIEventData.eventSequences
    let timeZones = AAIEventData.timeZones
    
    var body: some View {
        VStack {
            Text("AAI Planner")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("If you are an AWS Authorized Instructor (AAI), you can easily add to your calendar the plans for your training deliverability. Select the training, the start time, and the time zone, and press Add Events.\n\nRecommended Modules plans and breaks will be added to your calendar.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing, .bottom])
            
            if accessGranted {
                Picker("Event Name", selection: $selectedEventName) {
                    ForEach(eventNames, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                
                DatePicker("Start Date and Time", selection: $startDate)
                    .padding()
                
                Picker("Time Zone", selection: $selectedTimeZone) {
                    ForEach(timeZones) { timeZone in
                        Text(timeZone.displayName).tag(timeZone.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            
                if selectedEventName == "Architecting on AWS" || selectedEventName == "Developing on AWS" {
                    Button("Add Events") {
                        if let sequence = eventSequences[selectedEventName] {
                            if let timeZone = TimeZone(identifier: selectedTimeZone) {
                                viewModel.addEvents(sequence: sequence, startDate: startDate, timeZone: timeZone)
                            }
                        }
                    }.padding()
                } else {
                    Button("Unlock Premium to Add Event") {
                        print("User pressed unlock premium button")
                    }.padding()
                }
            } else {
               Spacer()
                Text("Requesting Calendar Access...")
                    .onAppear {
                        viewModel.requestAccess { granted in
                            accessGranted = granted
                        }
                    }
               Spacer()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

