import SwiftUI
import EventKit
import StoreKit
import RevenueCat

struct AAIplannerContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedEventName = "Architecting on AWS"
    @State private var startDate = Date()
    @State private var selectedTimeZone = TimeZone.current.identifier
    @State private var accessGranted = false
   @ObservedObject var userModel = UserViewModel.shared
   @State private var showAlert = false
    
    let eventNames = AAIEventData.eventNames
    let eventSequences = AAIEventData.eventSequences
    let timeZones = AAIEventData.timeZones
    
    var body: some View {
        VStack {
           Spacer()
            Text("AAI Planner")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
                .padding(.bottom)
            
            Text("If you are an AWS Authorized Instructor (AAI), you can easily add to your calendar the plans for your training deliverability. Select the training, the start time, and the time zone, and press Add Events.\n\nRecommended Modules plans and breaks will be added to your calendar.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing, .bottom])

            
               Spacer()
                Text("You need to install the full app to use this feature.")
                    .onAppear {
                        viewModel.requestAccess { granted in
                            accessGranted = granted
                        }
                    }
               Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AAIplannerContentView()
    }
}

