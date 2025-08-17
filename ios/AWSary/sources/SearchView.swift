//
//  SearchView.swift
//  awsary
//
//  Created by Tiago Rodrigues on 04/07/2025.
//
import SwiftUI

struct SearchView: View {
    @State var searchString = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                List{
                    Text("Item1")
                    Text("Item2")
                    Text("Item3")
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchString)
        }
    }
}


#Preview {
    SearchView()
}
