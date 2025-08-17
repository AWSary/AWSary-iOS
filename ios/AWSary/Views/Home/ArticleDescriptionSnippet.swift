//
//  ArticleDescriptionSnippet.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 13/08/2025.
//

import SwiftUI

import SwiftUI

struct ArticleDescriptionSnippet: View {
    let text: String
    @State private var expanded = false
    @State private var limitedHeight: CGFloat = .zero
    @State private var fullHeight: CGFloat = .zero

    private var isTruncated: Bool { fullHeight > limitedHeight + 0.5 }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Displayed text
            Text(text)
                .lineLimit(expanded ? nil : 2)
                .padding(.top, 6)
                // Put invisible measurers in BACKGROUND so they don't consume space
                .background(
                    Group {
                        Measurer(text: text, lineLimit: 2, height: $limitedHeight)
                        Measurer(text: text, lineLimit: nil, height: $fullHeight)
                    }
                )
            HStack{
                Spacer()
                if isTruncated && !expanded {
                    Button("...more") {
                        withAnimation(.easeInOut) { expanded = true } // one-way expand
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
        }
    }
}

// Zero-footprint text size measurer
private struct Measurer: View {
    let text: String
    let lineLimit: Int?
    @Binding var height: CGFloat

    var body: some View {
        Text(text)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { height = geo.size.height }
                        .onChange(of: geo.size.height) { height = $0 }
                }
            )
            .opacity(0)          // invisible
            .frame(height: 0)    // <- ensures it takes NO vertical space
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ArticleDescriptionSnippet(
            text: "This is a short description that won’t need to be truncated."
        )
        ArticleDescriptionSnippet(
            text: "CloudWhisper is a powerful AI-driven command-line tool designed to simplify AWS infrastructure management and cloud cost optimization using natural language. Whether you're a DevOps engineer, cloud architect, or a curious learner, CloudWhisper brings the power of Terraform generation, cost analysis, and resource optimization directly to your terminal all through intuitive prompts."
        )
    }
    .padding()
    .frame(width: 320) // constrain width to simulate a phone screen
}
