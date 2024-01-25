import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct ComplicationEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Image("GearIcon")
            .resizable()
            .scaledToFit()
           // Render as a template image
    }
}

@main
struct MyComplication: Widget {
    let kind: String = "MyComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Spot Multitool")
        .description("Launches My App")
        .supportedFamilies([.accessoryCircular]) // Specify circular complication
    }
}
