//
//  ArticleTempView.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 15/08/2025.
//
import SwiftUI

struct ArticleTempView: View {
    @Namespace var namespace
    @State var show = false
    let article:FeedContent
    
    var body: some View {
        ZStack{
            if show{
                VStack(alignment: .leading){
                    HStack{
                        if article.author.avatarURL != nil{
                            ImageLoaderView(urlString: article.author.avatarURL!)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .matchedGeometryEffect(id: "avatarUrl", in: namespace)
                        }
                        VStack(alignment: .leading){
                            Text(article.author.preferredName).font(.title)
                                .matchedGeometryEffect(id: "preferredName", in: namespace)
                            Text(timeAgo(from: article.createdAt)).font(.subheadline)
                                .matchedGeometryEffect(id: "createdAt", in: namespace)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    Text(article.title).font(.title2).fontWeight(.bold)
                        .matchedGeometryEffect(id: "title", in: namespace)

                    ArticleDescriptionSnippet(
                        text: article.contentTypeSpecificResponse.article.description)
                    .matchedGeometryEffect(id: "articleDescription", in: namespace)
                    ImageLoaderView(urlString: article.contentTypeSpecificResponse.article.heroImageURL, resizingMode: .fit)
                        .padding(.horizontal, -15)
                        .padding(.bottom, -15)
                        .matchedGeometryEffect(id: "heroImageUrl", in: namespace)
                }
                .padding(15)
                .background(Color.awsaryArticleCardBackground)
                .cornerRadius(20)
            } else {
                VStack(alignment: .leading){
                    ImageLoaderView(urlString: article.contentTypeSpecificResponse.article.heroImageURL, resizingMode: .fit)
                        .padding(.horizontal, -15)
                        .padding(.bottom, -15)
                        .matchedGeometryEffect(id: "heroImageUrl", in: namespace)
                    Text(article.title).font(.title).fontWeight(.bold)
                    HStack{
                        if article.author.avatarURL != nil{
                            ImageLoaderView(urlString: article.author.avatarURL!)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .matchedGeometryEffect(id: "avatarUrl", in: namespace)
                        }
                        VStack(alignment: .leading){
                            Text(article.author.preferredName).font(.title)
                                .matchedGeometryEffect(id: "preferredName", in: namespace)
                            Text(timeAgo(from: article.createdAt)).font(.subheadline)
                                .matchedGeometryEffect(id: "createdAt", in: namespace)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    Text(article.title).font(.title2).fontWeight(.bold)
                        .matchedGeometryEffect(id: "title", in: namespace)

                    ArticleDescriptionSnippet(
                        text: article.contentTypeSpecificResponse.article.description)
                    .matchedGeometryEffect(id: "articleDescription", in: namespace)
                    
                }
                .padding(15)
                .background(Color.awsaryArticleCardBackground)
                .cornerRadius(20)
            }
        }
        .onTapGesture{
            withAnimation{
                show.toggle()
            }
        }
    }
}

#Preview {
    ArticleTempView(article: FeedContent(
        author:
            Author(alias: "taylorjacobsen", avatarURL: "https://avatars.builderprofile.aws.dev/2ZaW6WI2TFvsadSAaamdEDFqGF1.webp",
                   creatorID: "", isAmazonEmployee: true, preferredName: "Taylor", bio: "", headline: ""),
        commentsCount: 31, contentID: "", contentType: ContentType(rawValue: "ARTICLE")!, contentTypeSpecificResponse: ContentTypeSpecificResponse(
            article: Article(
                description: "These six new AWS Heroes span diverse backgrounds and specialties, from Armenia's first AWS Community Day organizer to experts in security, serverless architecture, and machine learning. Each brings unique contributions to the AWS community through technical leadership, education, and community building initiatives across their respective regions.", heroImageURL: "https://prod-assets.cosmic.aws.dev/a/31EePiKCBwxMXt34WAvL7oZqnmB/aws-.webp", tags: ["aws-heroes"], versionID: "31EvSDX5lW5761vdqGmIQWa1NAC")), createdAt: 1753205654571, isLiked: false, lastModifiedAt: 1753205654571, lastPublishedAt: 1753205654571, likesCount: 13, locale: Locale(rawValue: "en")!, markdownDescription: "String", status:Status(rawValue: "live")!, title: "Meet our newest AWS Heroes August 2025"))
    .padding(20)
    .background(Color.red)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
