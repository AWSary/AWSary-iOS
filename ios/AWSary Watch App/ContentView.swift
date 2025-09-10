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
        // Loading articles
        if buildersContent.isEmpty{
            Text("Loading Articles...")
            ProgressView()
                .task {
                    await getData()
                }
        }else{
            // Articles are ready
            NavigationStack{
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(buildersContent.sorted() { $0.createdAt > $1.createdAt }, id:\.id) { article in
                            ZStack {
                                LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
//                                AsyncImage(url: URL(string: article.contentTypeSpecificResponse.article.heroImageURL))
                                VStack{
                                    Spacer()
                                    Text(article.title).fontWeight(.medium)
                                    Text("Read More").font(.footnote) // TODO make the text stand out less, dark grey
        
                                }.padding()
                            }
                            .id(article.id)
                            .containerRelativeFrame(.vertical)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .scrollTargetLayout()
                }
                .ignoresSafeArea()
                .scrollTargetBehavior(.paging)
            }
        }
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
