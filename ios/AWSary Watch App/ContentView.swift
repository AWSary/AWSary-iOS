//
//  ContentView.swift
//  awsary.watchOS Watch App
//
//  Created by Tiago Rodrigues on 09/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var buildersContent:[FeedContent] = []
    
    var body: some View {
        NavigationStack{
            ScrollView {
                ScrollView {
                    LazyVStack(spacing: 24, pinnedViews: []) {
                        Text("Treding Articles")
                        ForEach(buildersContent.sorted() { $0.createdAt > $1.createdAt }, id:\.id) { article in
                            VStack{
                                AsyncImage(url: URL(string: article.contentTypeSpecificResponse.article.heroImageURL))
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(article.title)
                            }
                            
//     - move from webview to bcArticleDetails
//                            NavigationLink(destination: WebView(url: URL(string: "https://builder.aws.com\(article.contentID)")!)
//                                .navigationTitle(article.title)
//                                .navigationBarTitleDisplayMode(.inline)
//                            ){
//                                CardView(article: article)
//                            }
//                            .buttonStyle(PressableButtonStyle())
//                            .padding(.horizontal)
//     - move from webview to bcArticleDetails
                        }
                    }
                    .padding(.vertical)
                    .task {
                        await getData()
                    }
                }
            }
        }
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
    }
    
    private func getData() async{
        do {
            buildersContent = try await BuildersContentHelper().getBuildersContent()
        }catch{
        }
    }
}

#Preview {
    ContentView()
}
