//
//  SealView.swift
//  Inkwell
//

import SwiftUI

struct SealView: View {
    var size: CGFloat = 34
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(InkTheme.accent)
            Text("書")
                .font(.system(size: size * 0.6, weight: .bold, design: .serif))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    SealView(size: 40)
        .padding()
        .background(InkTheme.paper)
}
