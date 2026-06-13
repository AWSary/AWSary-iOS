//
//  Test.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 05/08/2025.
//
import SwiftUI

struct testvew: View {
    var body: some View {
        NavigationStack {
            VStack{
                VStack{
                    VStack {
                        Circle()
                            .fill(Color(.cyan).gradient)
                            .frame(width: 35, height: 35)
                            .overlay {
                                Text("MF")
                                    .font(.headline)
                            }
                    }
                    .navigationTitle("Home")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: -15, y: -40)
                }
                Text("Hello, World!")
                Spacer()
            }
        }
    }
}

#Preview {
    testvew()
}
