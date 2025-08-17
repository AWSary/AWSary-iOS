//
//  ArticleCardView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 15/08/2025.
//
import SwiftUI

struct CardView: View {
    var article: FeedContent
    
    var body: some View {
        VStack(alignment: .leading){
            HStack{
                if article.author.avatarURL != nil{
                    ImageLoaderView(urlString: article.author.avatarURL!)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                VStack(alignment: .leading){
                    Text(article.author.preferredName).font(.title)
                    Text(timeAgo(from: article.createdAt)).font(.subheadline)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)

            Text(article.title).font(.title2).fontWeight(.bold)

            ArticleDescriptionSnippet(
                text: article.contentTypeSpecificResponse.article.description)
            ImageLoaderView(urlString: article.contentTypeSpecificResponse.article.heroImageURL, resizingMode: .fit)
                .padding(.horizontal, -15)
                .padding(.bottom, -15)
        }
        .padding(15)
        .background(Color.awsaryArticleCardBackground)
        .cornerRadius(20)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
