//
//  GuideGridShape.swift
//  Inkwell
//

import SwiftUI

enum GuideGridStyle: String, CaseIterable, Identifiable {
    case rice = "rice"
    case field = "field"
    case blank = "blank"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .rice: return "Rice (米)"
        case .field: return "Field (田)"
        case .blank: return "Blank"
        }
    }
}

struct GuideGridShape: Shape {
    let style: GuideGridStyle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard style != .blank else { return path }
        
        let midX = rect.midX
        let midY = rect.midY
        
        // Field lines (center cross)
        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        
        // Rice lines (diagonals)
        if style == .rice {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        
        return path
    }
}

struct GuideGridView: View {
    var style: GuideGridStyle = .rice
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(InkTheme.line, lineWidth: 2)
            
            GuideGridShape(style: style)
                .stroke(
                    InkTheme.guide,
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
                )
        }
    }
}

#Preview {
    GuideGridView(style: .rice)
        .frame(width: 300, height: 300)
        .padding()
        .background(InkTheme.paper)
}
