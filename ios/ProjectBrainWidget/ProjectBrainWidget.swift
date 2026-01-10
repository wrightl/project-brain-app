//
//  ProjectBrainWidget.swift
//  ProjectBrainWidget
//
//  Created by Lee Wright on 21/12/2025.
//

import WidgetKit
import SwiftUI

struct EggGoal {
    let message: String
    let completed: Bool
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let eggs = [
            EggGoal(message: "Complete morning meditation", completed: false),
            EggGoal(message: "Review project tasks", completed: true),
            EggGoal(message: "Call family", completed: false)
        ]
        return SimpleEntry(date: Date(), eggs: eggs)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let eggs = [
            EggGoal(message: "Complete morning meditation", completed: false),
            EggGoal(message: "Review project tasks", completed: true),
            EggGoal(message: "Call family", completed: false)
        ]
        return SimpleEntry(date: Date(), eggs: eggs)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var eggs: [EggGoal] = []
        
        // Fetch up to 3 egg goals
        for index in 0 ..< 3 {
            let message = StorageHelper.getString(key: "egg_\(index)") ?? "No Egg Goal Set"
            let completed = StorageHelper.getBool(key: "egg_\(index)_completed") ?? false
            eggs.append(EggGoal(message: message, completed: completed))
        }
        
        let entry = SimpleEntry(date: Date(), eggs: eggs)
        // Refresh every 15 minutes, but also responds to manual reloads
        let nextUpdate = Date().addingTimeInterval(15 * 60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let eggs: [EggGoal]
}

struct EggShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        
        // Create an egg shape using Bezier curves
        path.move(to: CGPoint(x: centerX, y: height))
        path.addCurve(
            to: CGPoint(x: width, y: height - (centerY * 0.7)),
            control1: CGPoint(x: width * 0.7, y: height),
            control2: CGPoint(x: width, y: height - (centerY * 0.3))
        )
        path.addCurve(
            to: CGPoint(x: centerX, y: 0),
            control1: CGPoint(x: width, y: height - (centerY * 1.1)),
            control2: CGPoint(x: width * 0.7, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: height - (centerY * 0.7)),
            control1: CGPoint(x: width * 0.3, y: 0),
            control2: CGPoint(x: 0, y: height - (centerY * 1.1))
        )
        path.addCurve(
            to: CGPoint(x: centerX, y: height),
            control1: CGPoint(x: 0, y: height - (centerY * 0.3)),
            control2: CGPoint(x: width * 0.3, y: height)
        )
        path.closeSubpath()
        
        return path
    }
}

struct EggCircleView: View {
    let egg: EggGoal
    let size: CGFloat
    
    var ringColor: Color {
        egg.completed ? .green : .orange
    }
    
    var body: some View {
        ZStack {
            // Ring
            Circle()
                .stroke(ringColor, lineWidth: size * 0.08)
                .frame(width: size, height: size)
            
            // Egg shape in center
            EggShape()
                .fill(ringColor.opacity(0.3))
                .frame(width: size * 0.6, height: size * 0.7)
        }
    }
}

struct ProjectBrainWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        GeometryReader { geometry in
            let eggSize = calculateEggSize(for: family, width: geometry.size.width, height: geometry.size.height)
            let spacing = eggSize * 0.15
            
            if family == .systemSmall {
                // Small: horizontal row of circles only
                HStack(spacing: spacing) {
                    ForEach(Array(entry.eggs.prefix(3).enumerated()), id: \.offset) { index, egg in
                        EggCircleView(egg: egg, size: eggSize)
                            .frame(width: eggSize, height: eggSize)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .padding()
            } else {
                // Medium and Large: vertical list with circle on left, message on right
                VStack(spacing: spacing * 1.5) {
                    ForEach(Array(entry.eggs.prefix(3).enumerated()), id: \.offset) { index, egg in
                        HStack(spacing: spacing) {
                            EggCircleView(egg: egg, size: eggSize)
                                .frame(width: eggSize, height: eggSize)
                            
                            Text(egg.message)
                                .font(.system(size: calculateFontSize(for: family)))
                                .foregroundColor(.primary)
                                .lineLimit(family == .systemMedium ? 1 : nil)
                                .multilineTextAlignment(.leading)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
//                .padding()
            }
        }
    }
    
    private func calculateEggSize(for family: WidgetFamily, width: CGFloat, height: CGFloat) -> CGFloat {
        switch family {
        case .systemSmall:
            // Small: fit 3 eggs horizontally with minimal padding
            let widgetSize = min(width, height)
            return (widgetSize * 0.9) / 3.5
        case .systemMedium:
            // Medium: vertical list - calculate based on available vertical space for 3 items
            // Account for padding (top + bottom) and spacing between 3 items
            let availableHeight = height * 1.0  // 10% for padding
            let spacingNeeded = 2 * (availableHeight * 0.05) // spacing between 3 items
            let heightPerItem = (availableHeight - spacingNeeded) / 3
            return min(heightPerItem * 1.0, width * 0.2) // Use 80% of item height or 20% of width, whichever is smaller
        case .systemLarge:
            // Large: vertical list - more space available
            let availableHeight = height * 1
//            let spacingNeeded = 2 * (availableHeight * 0.15)
            let heightPerItem = (availableHeight) / 3
            return min(heightPerItem * 1.0, width * 0.25)
        default:
            return min(width, height) / 4
        }
    }
    
    private func calculateFontSize(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemMedium:
            return 16
        case .systemLarge:
            return 22
        default:
            return 10
        }
    }
}

struct ProjectBrainWidget: Widget {
    let kind: String = "ProjectBrainWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            ProjectBrainWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    ProjectBrainWidget()
} timeline: {
    let eggs = [
        EggGoal(message: "Complete morning meditation", completed: false),
        EggGoal(message: "Review project tasks", completed: true),
        EggGoal(message: "Call family", completed: false)
    ]
    SimpleEntry(date: .now, eggs: eggs)
}

#Preview(as: .systemMedium) {
    ProjectBrainWidget()
} timeline: {
    let eggs = [
        EggGoal(message: "Complete morning meditation", completed: false),
        EggGoal(message: "Review project tasks", completed: true),
        EggGoal(message: "Call family", completed: false)
    ]
    SimpleEntry(date: .now, eggs: eggs)
}

#Preview(as: .systemLarge) {
    ProjectBrainWidget()
} timeline: {
    let eggs = [
        EggGoal(message: "Complete morning meditation", completed: false),
        EggGoal(message: "Review project tasks", completed: true),
        EggGoal(message: "Call family", completed: false)
    ]
    SimpleEntry(date: .now, eggs: eggs)
}
