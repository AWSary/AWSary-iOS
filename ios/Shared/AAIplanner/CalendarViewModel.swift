import SwiftUI
import EventKit

class CalendarViewModel: ObservableObject {
    private var eventStore = EKEventStore()
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestWriteOnlyAccessToEvents { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func addEvents(sequence: [(name: String, duration: Int)], startDate: Date, timeZone: TimeZone) {
        var currentStartDate = convert(date: startDate, to: timeZone)
        
        for event in sequence {
            let eventEndDate = Calendar.current.date(byAdding: .minute, value: event.duration, to: currentStartDate)!
            
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = event.name
            ekEvent.startDate = currentStartDate
            ekEvent.endDate = eventEndDate
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents
            ekEvent.timeZone = timeZone
            
           // If event is called skip, don't save it, used just to jump to the next day
           if event.name == "nextDay"{
              currentStartDate = convert(date: startDate.addingTimeInterval(TimeInterval(86400 * event.duration)), to: timeZone)
           }else{
              do {
                 try eventStore.save(ekEvent, span: .thisEvent)
              } catch {
                 print("Error saving event: \(error.localizedDescription)")
              }
              // Move to the next event start date
              currentStartDate = eventEndDate
           }
        }
    }
    
    private func convert(date: Date, to timeZone: TimeZone) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = components.day
        newComponents.hour = components.hour
        newComponents.minute = components.minute
        newComponents.second = components.second
        newComponents.timeZone = timeZone
        return calendar.date(from: newComponents) ?? date
    }
}
