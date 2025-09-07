import SwiftUI

struct HomeView: View {
    @Namespace var namespace
    @State var showArticle = false
    
    @State private var awsUserGroups:[AwsCloudClubElement] = []
    @State private var buildersContent:[FeedContent] = []
    @State private var backgroundIsAnimating = false
    // site fir color conversion
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
                LazyVStack(spacing: 24, pinnedViews: []) {
                    HStack{
                        Text("Trending Articles")
                            .font(.title).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)
                            .padding(.bottom, -15)
                            
                    }
                    ForEach(buildersContent.sorted() { $0.createdAt > $1.createdAt }, id:\.id) { article in
                        
// - move from webview to bcArticleDetails
                       NavigationLink(destination: BCArticleDetails(bcArticle: article), label: {
                           CardView(article: article)
                       })
                       .buttonStyle(PressableButtonStyle())
                       .padding(.horizontal)
                        
// - move from webview to bcArticleDetails
//                        NavigationLink(destination: WebView(url: URL(string: "https://builder.aws.com\(article.contentID)")!)
//                            .navigationTitle(article.title)
//                            .navigationBarTitleDisplayMode(.inline)
//                        ){
//                            CardView(article: article)
//                        }
//                        .buttonStyle(PressableButtonStyle())
//                        .padding(.horizontal)
// - move from webview to bcArticleDetails
                    }
                }
                .padding(.vertical)
                .task {
                    await getData()
                }
            }
            .background(){
                MeshGradient(width: 3, height: 3, points: [
                    .init(x:0,y:0), .init(x:0.5,y:0), .init(x:1,y:0),
                    .init(x:0,y:0.5), .init(x:0.5,y:0.5), .init(x:1,y:0.5),
                    .init(x:0,y:1),  .init(x:0.5,y:1),.init(x:1,y:1),
                ], colors: backgroundIsAnimating ? backgorundColor1 : backgorundColor2)
                .frame(height: .infinity)
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black, location: 0.4),
                            .init(color: .clear, location: 0.9),
                            .init(color: .clear, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ).ignoresSafeArea()
            }
            .navigationTitle("AWSary")
        }
// Disabled during dev to reduce cpu usage and pc heat
//        .onAppear(){
//            withAnimation(.easeInOut(duration: 5).repeatForever()) {
//                backgroundIsAnimating.toggle()
//            }
//        }
// End here the - Disabled during dev to reduce cpu usage and pc heat
    }
        
    private func getData() async{
        do {
            awsUserGroups = try await CommunityDatabaseHelper().getUserGroups()
            buildersContent = try await BuildersContentHelper().getBuildersContent()
        }catch{
        }
    }
}

#Preview {
    HomeView()
}
