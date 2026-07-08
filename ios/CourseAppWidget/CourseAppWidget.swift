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
        SimpleEntry(
            classTime: "",
            location: "",
            title: "",
            shortText: "",
            nextTime: "",
            nextLocation: "",
            nextTitle: "",
            shortNext: "",
            configuration: ConfigurationIntent()
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            classTime: "9:00 - 12:00",
            location: "EC5012",
            title: "演算法",
            shortText: "演算法: EC5012 9:00",
            nextTime: "",
            nextLocation: "",
            nextTitle: "",
            shortNext: "",
            configuration: configuration
        )
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        var myUserDefaults :UserDefaults!
        myUserDefaults = UserDefaults(suiteName: "group.com.nsysu.ap")
        var title = "尚無課程資料"
        var classTime = ""
        var location = ""
        var shortText = "尚無課程資料"
        
        var nextTitle = ""
        var nextTime = ""
        var nextLocation = ""
        var shortNext = ""
        
        if let json = myUserDefaults?.string(forKey: "course_notify") {
            let courseData = try? JSONDecoder().decode(CourseData.self, from: Data(json.utf8))
            let today = Date()
            let dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: today)
            let courses = courseData?.courses
            let weekday = dateComponents.weekday == 1 ? 7 : (dateComponents.weekday ?? 1) - 1
            
            struct TempCourseItem {
                let course: Course
                let timeCode: TimeCode
                let diff: TimeInterval
            }
            
            var futureCourses: [TempCourseItem] = []
            var todayCount = 0
            
            courses?.forEach({ (course) in
                course.sectionTimes.forEach { (sectionTime) in
                    if weekday == sectionTime.weekday {
                        todayCount += 1
                        if sectionTime.index < (courseData?.timeCodes.count ?? 0) {
                            let timeCode = courseData!.timeCodes[sectionTime.index]
                            let time = time2Date(timeText: timeCode.startTime)
                            let diff = time.timeIntervalSince1970 - today.timeIntervalSince1970
                            if diff > 0.0 {
                                futureCourses.append(
                                    TempCourseItem(course: course, timeCode: timeCode, diff: diff)
                                )
                            }
                        }
                    }
                }
            })
            futureCourses.sort { $0.diff < $1.diff }
            
            if !futureCourses.isEmpty {
                let first = futureCourses[0]
                classTime = "\(first.timeCode.startTime) - \(first.timeCode.endTime)"
                location = "\(first.course.location.building ?? "")\(first.course.location.room ?? "")"
                title = first.course.title
                shortText = "\(first.course.title): \(location) \(first.timeCode.startTime)"
                
                if futureCourses.count > 1 {
                    let second = futureCourses[1]
                    nextTime = "\(second.timeCode.startTime) - \(second.timeCode.endTime)"
                    nextLocation = "\(second.course.location.building ?? "")\(second.course.location.room ?? "")"
                    nextTitle = second.course.title
                    shortNext = "\(second.course.title): \(nextLocation) \(second.timeCode.startTime)"
                }
            } else {
                if todayCount == 0 {
                    title = "太好了今天沒有任何課"
                    shortText = "今天沒有任何課"
                } else {
                    title = "太好了今天沒有任何課"
                    shortText = "今天已經沒有任何課"
                }
            }
        }
        
        let entry = SimpleEntry(
            classTime: classTime,
            location: location,
            title: title,
            shortText: shortText,
            nextTime: nextTime,
            nextLocation: nextLocation,
            nextTitle: nextTitle,
            shortNext: shortNext,
            configuration: configuration
        )
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
    let classTime: String
    let location: String
    let title: String
    let shortText: String

    let nextTime: String
    let nextLocation: String
    let nextTitle: String
    let shortNext: String

    let configuration: ConfigurationIntent
}

// TODO: make this look better
struct CourseAppWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetFamily) var family

    let titleBackgroundColor = Color.init(UIColor(red: 0.16, green: 0.59, blue: 0.98, alpha: 1.00))
    
    func getContentBackgroudColor() -> Color {
        return colorScheme == .dark ? Color.init(  UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.00)):Color.white
    }
    
    func getContentTextColor() -> Color {
        return colorScheme == .dark ? Color.white : Color.black
    }
    
    var weekdayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // "Mon", "Tue", "Wed", etc.
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: entry.date).uppercased()
    }
    
    var fullWeekdayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // "Monday", "Tuesday", etc.
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: entry.date).uppercased()
    }
    
    var dayOfMonthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // "13", "1"
        return formatter.string(from: entry.date)
    }
    
    var monthText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM" // "June", "January"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: entry.date).uppercased()
    }
    
    var body: some View {
        if family == .systemLarge {
            VStack(spacing: 0) {
                Spacer(minLength: 10)
                
                VStack(spacing: 4) {
                    Text(fullWeekdayText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(titleBackgroundColor)
                        .tracking(3)
                    
                    Text(dayOfMonthText)
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                        .foregroundColor(getContentTextColor())
                    
                    Text(monthText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .tracking(2)
                }
                .padding(.bottom, 16)
                .frame(maxHeight: .infinity)
                
                HStack(spacing: 12) {
                    if !entry.classTime.isEmpty {
                        Capsule()
                            .fill(titleBackgroundColor)
                            .frame(width: 4)
                            .frame(maxHeight: 64)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        if (!entry.classTime.isEmpty){
                            Text("\(entry.classTime)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }
                        Text("\(entry.title)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(getContentTextColor())
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        Text("\(entry.location)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(maxHeight: .infinity)
                if !entry.shortNext.isEmpty {
                    Divider().padding(.horizontal, 24)
                    HStack(spacing: 12) {
                        Capsule()
                            .fill(titleBackgroundColor)
                            .frame(width: 4)
                            .frame(maxHeight: 64)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.nextTime)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("\(entry.nextTitle)")
                                .font(.title3)
                                .bold()
                                .foregroundColor(getContentTextColor())
                                .lineLimit(2)
                                .minimumScaleFactor(0.6)
                            Text("\(entry.nextLocation)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity)
                }
                Spacer()
            }
            .widgetBackground(getContentBackgroudColor())
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(weekdayText)
                    .font(.callout)
                    .foregroundColor(.gray)
                    .tracking(1)
                HStack(spacing: 8) {
                    if !entry.classTime.isEmpty {
                        Capsule()
                            .fill(titleBackgroundColor)
                            .frame(width: 4)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        if (!entry.classTime.isEmpty){
                            Text("\(entry.classTime)")
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        Text("\(entry.title)")
                            .font(.title2)
                            .bold()
                            .foregroundColor(getContentTextColor())
                            .minimumScaleFactor(0.5)
                        Text("\(entry.location)")
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer().frame(height: 4)
                    }
                    Spacer()
                }
                if !entry.shortNext.isEmpty {
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(titleBackgroundColor)
                            .frame(width: 4, height: 16)
                        Text("\(entry.shortNext)")
                            .font(.caption)
                            .foregroundColor(getContentTextColor())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                    }
                }
                else{
                    Spacer()
                }
            }
            .padding(16)
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
// TODO: make this look better
struct CourseTextWidgetEntryView: View {
    var entry: Provider.Entry
    
    func getContentBackgroudColor() -> Color {
        return Color.init(  UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1))
    }
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 4){
                Text("\(entry.title)")
                    .bold()
                    .minimumScaleFactor(0.5)
                if (!entry.classTime.isEmpty){
                    HStack{
                        Text("\(entry.classTime)")
                            .font(.system(.caption, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Text("\(entry.location)")
                            .font(.system(.caption, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }.padding(4)
        }.widgetBackground(getContentBackgroudColor())
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

@available(iOSApplicationExtension 17.0, *)
#Preview(as: .accessoryRectangular) {
    CourseAppWidget()
} timeline: {
    SimpleEntry(
        classTime: "9:00 - 12:00",
        location: "EC9031",
        title: "積體電路電腦輔助設計概論",
        shortText: "積體電路電腦輔助設計概論: EC9031 9:00",

        nextTime: "13:00 - 16:00",
        nextLocation: "EC5012",
        nextTitle: "演算法",
        shortNext: "演算法 13:00 - 16:00",
        configuration: ConfigurationIntent()
    )
}
@available(iOSApplicationExtension 17.0, *)
#Preview(as: .accessoryRectangular) {
    CourseAppWidget()
} timeline: {
    SimpleEntry(
        classTime: "9:00 - 12:00",
        location: "EC9031",
        title: "積體電路電腦輔助設計概論",
        shortText: "積體電路電腦輔助設計概論: EC9031 9:00",

        nextTime: "",
        nextLocation: "",
        nextTitle: "",
        shortNext: "",
        configuration: ConfigurationIntent()
    )
}
@available(iOSApplicationExtension 17.0, *)
#Preview(as: .accessoryRectangular) {
    CourseAppWidget()
} timeline: {
    SimpleEntry(
        classTime: "",
        location: "",
        title: "太好了今天沒有任何課",
        shortText: "今天已經沒有任何課",
        
        nextTime: "",
        nextLocation: "",
        nextTitle: "",
        shortNext: "",
        configuration: ConfigurationIntent()
    )
}

@available(iOSApplicationExtension 17.0, *)
#Preview(as: .accessoryRectangular) {
    CourseAppWidget()
} timeline: {
    SimpleEntry(
        classTime: "9:00 - 12:00",
        location: "EC5012",
        title: "演算法",
        shortText: "9:00 EC5012 演算法",
        nextTime: "",
        nextLocation: "",
        nextTitle: "",
        shortNext: "",
        configuration: ConfigurationIntent()
    )
}
