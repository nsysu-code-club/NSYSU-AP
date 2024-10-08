//
//  CourseAppWidget.swift
//  CourseAppWidget
//
//  Created by rainvisitor on 2020/10/1.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(text: "", shortText: "", configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(text: "下一堂課是 9:00\n在 EC5012 的 演算法",shortText: "9:00 在 EC5012 的演算法", configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        var myUserDefaults :UserDefaults!
        myUserDefaults = UserDefaults(suiteName: "group.com.nsysu.ap")
        var text = "尚無課程資料"
        var shortText = "尚無課程資料"
        if let json = myUserDefaults.string(forKey: "course_notify"){
            let courseData = try? JSONDecoder().decode(CourseData.self, from: Data(json.utf8))
            let today = Date()
            let dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: today)
            let courses = courseData?.courses
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            var minDiff = today.timeIntervalSince1970
            var todayCount = 0
            courses?.forEach({ (course) in
                course.sectionTimes.forEach { (sectionTime) in
                    let timeCode = courseData?.timeCodes[sectionTime.index]
                    let time = time2Date(timeText: timeCode?.startTime ?? "00:00")
                    let diff = time.timeIntervalSince1970 - today.timeIntervalSince1970
                    let weekday = dateComponents.weekday == 1 ? 7 :  (dateComponents.weekday ?? 1) - 1
                    if(weekday == sectionTime.weekday) {
                        todayCount = todayCount + 1
                    }
                    if( diff > 0.0  && diff < minDiff && weekday == sectionTime.weekday){
                        minDiff = diff
                        text = "下一節課是\(timeCode?.startTime ?? "")\n在 \(course.location.building ?? "" )\(course.location.room  ?? "") 的 \(course.title )"
                        shortText = "\(timeCode?.startTime ?? "")在 \(course.location.building ?? "" )\(course.location.room  ?? "") 的\(course.title )"
                    }
                }
            })
            if(todayCount == 0){
                text = "太好了今天沒有任何課"
                shortText = "今天沒有任何課"
            } else if (minDiff == today.timeIntervalSince1970){
                text = "太好了今天已經沒有任何課"
                shortText = "今天已經沒有任何課"
            }
        }
        
        let entry = SimpleEntry(text: text, shortText: shortText, configuration: configuration)
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    func time2Date(timeText:String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = (timeText.count == 4 ? "HHmm" : "HH:mm")
        let time = dateFormatter.date(from: timeText) ?? Date()
        var now = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        let courseTime = Calendar.current.dateComponents(in: TimeZone.current, from: time)
        now.hour = courseTime.hour
        now.minute = courseTime.minute
        let userCalendar = Calendar.current
        let someDateTime = userCalendar.date(from: now)
        return someDateTime ?? Date()
    }
}

struct SimpleEntry: TimelineEntry {
    var date = Date()
    let text: String
    let shortText: String
    let configuration: ConfigurationIntent
}

struct CourseAppWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    func getTitleBackgroudColor() -> Color {
        return Color.init(
            colorScheme == .dark ?
                UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.00):
                UIColor(red: 0.15, green: 0.45, blue: 1.00, alpha: 1.00)
        )
    }
    
    func getContentBackgroudColor() -> Color {
        return colorScheme == .dark ? Color.init(  UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.00)):Color.white
    }
    
    func getContentTextColor() -> Color {
        return colorScheme == .dark ? Color.white : Color.black
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack{
                HStack{
                    Text("上課提醒")
                        .foregroundColor(Color.white)
                        .frame(width: geometry.size.width, height: 36)
                }
                .background(getTitleBackgroudColor())
                Text("\(entry.text)")
                    .foregroundColor(getContentTextColor())
                    .frame(height: geometry.size.height - 36)
                    .padding([.trailing, .leading], 8)
                    .multilineTextAlignment(.center)
            }
            .widgetBackground(getContentBackgroudColor())
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct InlineWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        Text(entry.shortText)
    }
}

@available(iOSApplicationExtension 16.0, *)
struct CourseTextWidgetEntryView: View {
    var entry: Provider.Entry
    
    func getContentBackgroudColor() -> Color {
        return Color.init(  UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AccessoryWidgetBackground()
                    .cornerRadius(8)
                GeometryReader { geometry in
                        VStack{
                            Text("\(entry.text)")
                                .font(.system(.caption, weight: .bold))
                                .frame(height: geometry.size.height)
                                .padding([.trailing, .leading], 4)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                }
            }
            .widgetBackground(getContentBackgroudColor())
        }
    }
}

struct ViewSizeWidgetView: View {

    let entry: SimpleEntry

    // Obtain the widget family value
    @Environment(\.widgetFamily)
    var family

    var body: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch family {
            case .accessoryInline:
                InlineWidgetView(entry: entry)
            case .accessoryRectangular:
                CourseTextWidgetEntryView(entry: entry)
            default:
                // UI for Home Screen widget
                CourseAppWidgetEntryView(entry: entry)
            }
        } else {
            CourseAppWidgetEntryView(entry: entry)
        }
    }
}

@main
struct CourseAppWidget: Widget {
    let kind: String = "CourseAppWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ViewSizeWidgetView(entry: entry)
        }
        .configurationDisplayName("上課提醒")
        .description("提醒本日下一堂課")
        .supportedFamiliesIfNeeded()
        .disableContentMarginsIfNeeded()
    }
}

struct CourseAppWidget_Previews: PreviewProvider {
    static var previews: some View {
        ViewSizeWidgetView(entry: SimpleEntry(text: "下一堂課是 9:00\n在 EC5012 的 演算法", shortText: "9:00 在 EC5012 的演算法", configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
    
    func supportedFamiliesIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 16, *) {
            return self.supportedFamilies([
                .systemSmall,
                .systemMedium,
                .systemLarge,

                // Add Support to Lock Screen widgets
                .accessoryRectangular,
                .accessoryInline,
            ])
        } else {
            return self
        }
    }
}
