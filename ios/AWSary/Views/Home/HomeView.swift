import SwiftUI

struct HomeView: View {
    @Namespace var namespace
    @State var showArticle = false
    
    @State private var buildersContent:[FeedContent] = []
    @State private var loadState: TrendingArticlesLoadState = .idle
    @State private var backgroundIsAnimating = false
    // site for color conversion
    // https://iosref.com/uihex
    let backgorundColor1 = (0..<9).map { _ in
        [Color.awsaryPink, Color.awsaryPurple, Color.awsaryBlue]
        .randomElement()! }
    let backgorundColor2 = (0..<9).map { _ in
        [Color.awsaryPink, Color.awsaryPurple, Color.awsaryBlue]
        .randomElement()! }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Good morning, 👋")
                    Text("Ready to build something amazing?")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                
                LazyVStack(spacing: 24, pinnedViews: []) {
                    HStack{
                        Text("Trending Articles")
                            .font(.title).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)
                            .padding(.bottom, -15)
                            
                    }
                    if buildersContent.isEmpty {
                        TrendingArticlesStatusView(state: loadState) {
                            Task { await getData() }
                        }
                        .padding(.horizontal)
                    }
                    ForEach(buildersContent.sorted() { $0.createdAt > $1.createdAt }, id:\.id) { article in
                        
                        if let articleURL = URL(string: "https://builder.aws.com\(article.contentID)") {
                            NavigationLink(destination: WebView(url: articleURL)
                                .navigationTitle(article.title)
                                .navigationBarTitleDisplayMode(.inline)
                            ) {
                                CardView(article: article)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .padding(.horizontal)
                        }

//                        Native article details are retained for future use.
//                        NavigationLink(destination: BCArticleDetails(bcArticle: article)) {
//                            CardView(article: article)
//                        }
//                        .buttonStyle(PressableButtonStyle())
//                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .task {
                    guard loadState == .idle else { return }
                    await getData()
                }
            }
            .refreshable {
                await getData()
            }
            .background(){
                MeshGradient(width: 3, height: 3, points: [
                    .init(x:0,y:0), .init(x:0.5,y:0), .init(x:1,y:0),
                    .init(x:0,y:0.5), .init(x:0.5,y:0.5), .init(x:1,y:0.5),
                    .init(x:0,y:1),  .init(x:0.5,y:1),.init(x:1,y:1),
                ], colors: backgroundIsAnimating ? backgorundColor1 : backgorundColor2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.7), location: 0.0),
                            .init(color: .clear, location: 0.9),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ).ignoresSafeArea()
            }
            .awsarySettingsToolbar()
        }
// Disabled during dev to reduce cpu usage and pc heat
        .onAppear(){
            withAnimation(.easeInOut(duration: 15).repeatForever()) {
                backgroundIsAnimating.toggle()
            }
        }
// End here the - Disabled during dev to reduce cpu usage and pc heat
    }
        
    @MainActor
    private func getData() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let articles = try await BuildersContentHelper().getBuildersContent()
            try Task.checkCancellation()
            buildersContent = articles
            loadState = .loaded
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                loadState = .idle
            } else if let error = error as? URLError,
                      error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                loadState = .offline
            } else {
                loadState = .failed
            }
        }
    }
}

private enum TrendingArticlesLoadState {
    case idle, loading, loaded, offline, failed
}

private struct TrendingArticlesStatusView: View {
    let state: TrendingArticlesLoadState
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView("Loading articles…")
                .tint(Color(red: 0.357, green: 0.361, blue: 1.0))
                .frame(maxWidth: .infinity)
                .padding(24)
        case .offline, .failed:
            ContentUnavailableView {
                Label(state == .offline ? "You're offline" : "Couldn't load articles",
                      systemImage: state == .offline ? "wifi.slash" : "exclamationmark.triangle")
            } description: {
                Text(state == .offline
                     ? "Connect to the internet and try again."
                     : "Trending articles are unavailable right now. Please try again.")
            } actions: {
                Button("Retry", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.357, green: 0.361, blue: 1.0))
            }
            .background(Color.awsaryArticleCardBackground, in: RoundedRectangle(cornerRadius: 20))
        case .loaded:
            ContentUnavailableView {
                Label("No trending articles yet", systemImage: "newspaper")
            } description: {
                Text("Check back later for new articles.")
            } actions: {
                Button("Refresh", action: retry)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.357, green: 0.361, blue: 1.0))
            }
            .background(Color.awsaryArticleCardBackground, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

#Preview {
    HomeView()
}

#Preview("Trending — Offline") {
    TrendingArticlesStatusView(state: .offline, retry: {})
        .padding()
}

#Preview("Trending — Loading") {
    TrendingArticlesStatusView(state: .loading, retry: {})
}
