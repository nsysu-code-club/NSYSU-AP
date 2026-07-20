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
            compactNext: "",
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
            compactNext: "",
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
        var compactNext = ""
        
        if let json = myUserDefaults?.string(forKey: "course_notify"),
           let courseData = try? JSONDecoder().decode(CourseData.self, from: Data(json.utf8)) {
            let today = Date()
            let dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: today)
            let courses = courseData.courses
            let weekday = dateComponents.weekday == 1 ? 7 : (dateComponents.weekday ?? 1) - 1
            
            struct TempCourseItem {
                let course: Course
                let startTime: String
                var endTime: String
                var endSectionIndex: Int
                let startDate: Date
                var endDate: Date
            }
            
            var todayCourses: [TempCourseItem] = []
            var todayCount = 0
            
            courses.forEach({ (course) in
                course.sectionTimes.forEach { (sectionTime) in
                    if weekday == sectionTime.weekday {
                        todayCount += 1
                        if sectionTime.index >= 0 && sectionTime.index < courseData.timeCodes.count {
                            let timeCode = courseData.timeCodes[sectionTime.index]
                            todayCourses.append(
                                TempCourseItem(
                                    course: course,
                                    startTime: timeCode.startTime,
                                    endTime: timeCode.endTime,
                                    endSectionIndex: sectionTime.index,
                                    startDate: time2Date(timeText: timeCode.startTime),
                                    endDate: time2Date(timeText: timeCode.endTime)
                                )
                            )
                        }
                    }
                }
            })
            
            let sortedCourses = todayCourses.sorted { $0.startDate < $1.startDate }
            var mergedCourses: [TempCourseItem] = []

            for item in sortedCourses {
                if let last = mergedCourses.last,
                   last.course === item.course,
                   item.endSectionIndex == last.endSectionIndex + 1 {
                    mergedCourses[mergedCourses.count - 1].endTime = item.endTime
                    mergedCourses[mergedCourses.count - 1].endSectionIndex = item.endSectionIndex
                    mergedCourses[mergedCourses.count - 1].endDate = item.endDate
                } else {
                    mergedCourses.append(item)
                }
            }

            let activeAndFutureCourses = mergedCourses.filter { $0.endDate > today }
            let topTwoCourses = Array(activeAndFutureCourses.prefix(2))
            
            if let first = topTwoCourses.first {
                classTime = "\(first.startTime) - \(first.endTime)"
                location = cleanLocation(
                    "\(first.course.location.building ?? "")\(first.course.location.room ?? "")"
                )
                title = first.course.title
                shortText = "\(first.course.title): \(location) \(first.startTime)"
                
                if topTwoCourses.count > 1 {
                    let second = topTwoCourses[1]
                    nextTime = "\(second.startTime) - \(second.endTime)"
                    nextLocation = cleanLocation(
                        "\(second.course.location.building ?? "")\(second.course.location.room ?? "")"
                    )
                    nextTitle = second.course.title
                    shortNext = "\(second.course.title) \(nextLocation) \(second.startTime) - \(second.endTime)"
                    compactNext = "\(second.course.title) · \(second.startTime)"
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
            compactNext: compactNext,
            configuration: configuration
        )
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func cleanLocation(_ location: String) -> String {
        guard let range = location.range(
            of: #"\([^()]*\)"#,
            options: .regularExpression
        ) else {
            return location
        }

        return String(location[range].dropFirst().dropLast())
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
    let compactNext: String

    let configuration: ConfigurationIntent
}

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
    
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    private static let fullWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    private static let dayOfMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    var weekdayText: String {
        Self.weekdayFormatter.string(from: entry.date).uppercased()
    }
    
    var fullWeekdayText: String {
        Self.fullWeekdayFormatter.string(from: entry.date).uppercased()
    }
    
    var dayOfMonthText: String {
        Self.dayOfMonthFormatter.string(from: entry.date)
    }
    
    var monthText: String {
        Self.monthFormatter.string(from: entry.date).uppercased()
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
                        Text(
                            family == .systemSmall
                                ? entry.compactNext
                                : entry.shortNext
                        )
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
        compactNext: "演算法 · 13:00",
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
        compactNext: "",
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
        compactNext: "",
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
        compactNext: "",
        configuration: ConfigurationIntent()
    )
}
