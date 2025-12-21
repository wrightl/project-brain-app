//
//  ProjectBrainWidgetLiveActivity.swift
//  ProjectBrainWidget
//
//  Created by Lee Wright on 21/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ProjectBrainWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ProjectBrainWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ProjectBrainWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ProjectBrainWidgetAttributes {
    fileprivate static var preview: ProjectBrainWidgetAttributes {
        ProjectBrainWidgetAttributes(name: "World")
    }
}

extension ProjectBrainWidgetAttributes.ContentState {
    fileprivate static var smiley: ProjectBrainWidgetAttributes.ContentState {
        ProjectBrainWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ProjectBrainWidgetAttributes.ContentState {
         ProjectBrainWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ProjectBrainWidgetAttributes.preview) {
   ProjectBrainWidgetLiveActivity()
} contentStates: {
    ProjectBrainWidgetAttributes.ContentState.smiley
    ProjectBrainWidgetAttributes.ContentState.starEyes
}
