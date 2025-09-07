//
//  BCArticleDetails.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 27/08/2025.
//

import SwiftUI
import MarkdownUI

struct BCArticleDetails: View {
    var bcArticle: FeedContent
    
    var body: some View {
        ZStack{
            VStack{
                ImageLoaderView(urlString: bcArticle.contentTypeSpecificResponse.article.heroImageURL, resizingMode: .fit)
                    .ignoresSafeArea()
                    .padding(0)
                Spacer()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    //                Image(systemName:"house")
                    
                    // MARK: Hero
                    HeroHeader(
                        title: bcArticle.title,
                        imageURL: bcArticle.contentTypeSpecificResponse.article.heroImageURL,
                        tags: bcArticle.contentTypeSpecificResponse.article.tags
                    )
                    .padding(.top, 220)
                    
                    
                    //                .padding(.horizontal)
                    //                .padding(.top)
                    VStack{
                        // MARK: Author
                        AuthorRow(author: bcArticle.author)
                            .padding(.horizontal)
                        
                        // MARK: Meta
                        MetaRow(
                            date: bcArticle.createdAt.asDate,
                            readingMinutes: bcArticle.markdownDescription.estimatedReadingMinutes(),
                            likes: bcArticle.likesCount,
                            comments: bcArticle.commentsCount,
                            isLiked: bcArticle.isLiked
                        )
                        .padding(.horizontal)
                        
                        // MARK: Content
                        Markdown(bcArticle.markdownDescription)
                            .padding(.horizontal)
                        //                    .markdownTheme(.gitHub)
                        //                    .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(.systemGroupedBackground))
                    .padding(.horizontal)
                    .cornerRadius(24)
                        
                    //            .padding(.horizontal, 18)
                    .padding(.bottom, 32)
                }
            }
            .background(.clear)
//            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Subviews

private struct HeroHeader: View {
    let title: String
    let imageURL: String
    let tags: [String]
    
    var body: some View {
        VStack{
//            ImageLoaderView(urlString: imageURL, resizingMode: .fit)
//                .ignoresSafeArea()
//                .padding(0)
            
//            ImageLoaderView(urlString: imageURL, resizingMode: .fit)
//                .ignoresSafeArea()
//                .padding(0)
//                .scaleEffect(y: -1)                  // flip vertically
//                        .opacity(0.4)                        // make it dimmer than the original
//                        .mask(                               // fade out toward the bottom
//                            LinearGradient(
//                                colors: [.black, .clear, .clear],
//                                startPoint: .top,
//                                endPoint: .center
//                            )
//                        )
//                        .blur(radius: 1)                     // optional: soften the reflection
            ZStack{
//                Rectangle()
//                    .fill(
//                        LinearGradient(
//                            colors: [.black.opacity(0.95), .black.opacity(0.75)],
//                            startPoint: .top, endPoint: .bottom
//                        )
//                    )
                    
                Text(title)
                    .font(.title)
                    .bold()
//                    .foregroundColor(.white)
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 24.0))
//                    .glassEffect(.regular.tint(.black), in: .rect(cornerRadius: 24.0))
            }
            
//            .cornerRadius(24)
            .padding(.top, -20)
//            .padding(.horizontal)
            
            
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(tags.prefix(8)), id: \.self) { tag in
                            TagCapsule(tag: "#\(tag)", inverted: true)
                        }
                    }
                }
                .opacity(0.95)
                .padding(.horizontal)
            }
                
        }

        
        
        
//        ZStack(alignment: .bottomLeading) {
//            // Image
//            ImageLoaderView(urlString: imageURL, resizingMode: .fit)
//                .ignoresSafeArea()
////                .padding(.bottom, 150)
//                
////            ImageLoaderView(urlString: imageURL, resizingMode: .fill)
////                .frame(height: 260)
////                .frame(maxWidth: .infinity)
////                .background(
////                    LinearGradient(
////                        colors: [.blue.opacity(0.35), .purple.opacity(0.35)],
////                        startPoint: .topLeading, endPoint: .bottomTrailing
////                    )
////                )
////                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
////                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 12)
//            
//            // Gradient overlay for legibility
//            
//            
//            // Title + Tags
//            ZStack{
//                VStack{
//                    Rectangle()
//                        .fill(
//                            LinearGradient(
//                                colors: [.clear, .black.opacity(0.65), .black.opacity(0.90), .black.opacity(0.85)],
//                                startPoint: .center, endPoint: .bottom
//                            )
//                        )
//                        .allowsHitTesting(false)
//                }
//                
//                VStack(alignment: .leading, spacing: 10) {
//                    Text(title)
//                        .font(.system(.title, design: .rounded, weight: .bold))
//                        .foregroundStyle(.white)
//                        .shadow(radius: 8)
//                        .lineLimit(3)
//                        .minimumScaleFactor(0.9)
//                    
//                    if !tags.isEmpty {
//                        ScrollView(.horizontal, showsIndicators: false) {
//                            HStack(spacing: 8) {
//                                ForEach(Array(tags.prefix(8)), id: \.self) { tag in
//                                    TagCapsule(tag: "#\(tag)", inverted: true)
//                                }
//                            }
//                        }
//                        .opacity(0.95)
//                    }
//                }
//                .padding(16)
//            }
//        }
////        .cornerRadius(24)
//        .accessibilityElement(children: .combine)
//        .accessibilityLabel(Text(title))
    }
}

private struct AuthorRow: View {
    let author: Author
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle().fill(Color.secondary.opacity(0.08))
                if let url = author.avatarURL, !url.isEmpty {
                    ImageLoaderView(urlString: url, resizingMode: .fill)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
            .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // Names
            VStack(alignment: .leading, spacing: 2) {
                Text(author.preferredName.isEmpty ? author.alias : author.preferredName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("@\(author.alias)").foregroundStyle(.secondary)
                    
                    if author.isAmazonEmployee {
                        Label("Amazon", systemImage: "checkmark.seal.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
                .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

private struct MetaRow: View {
    let date: Date
    let readingMinutes: Int
    let likes: Int
    let comments: Int
    let isLiked: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            Label("\(readingMinutes) min read", systemImage: "clock")
            Spacer(minLength: 8)
            Label("\(likes)", systemImage: isLiked ? "heart.fill" : "heart")
                .symbolRenderingMode(isLiked ? .monochrome : .hierarchical)
            Label("\(comments)", systemImage: "text.bubble")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

private struct TagCapsule: View {
    let tag: String
    var inverted: Bool = false
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                inverted
                ? Color.white.opacity(0.18)
                : Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(
                    inverted ? Color.black.opacity(0.35) : Color.secondary.opacity(0.2),
                    lineWidth: 0.5
                )
            )
            .foregroundStyle(inverted ? .black : .primary)
            .lineLimit(1)
    }
}

// MARK: - Utilities

private extension Int {
    /// Accepts Unix timestamp in seconds or milliseconds.
    var asDate: Date {
        self > 1_000_000_000_000
        ? Date(timeIntervalSince1970: TimeInterval(self) / 1000.0)
        : Date(timeIntervalSince1970: TimeInterval(self))
    }
}

private extension String {
    /// Rough reading time estimate at ~220 wpm.
    func estimatedReadingMinutes(wordsPerMinute: Double = 220) -> Int {
        let words = self.split { !$0.isLetter && !$0.isNumber }.count
        return max(1, Int(ceil(Double(words) / wordsPerMinute)))
    }
}

// MARK: - Preview

#Preview {
    // Article (from contentTypeSpecificResponse.article)
    let article = Article(
        description: "Built a comprehensive portfolio website featuring AWS learning resources, DevSecOps guides, Docker & Kubernetes tutorials, AI learning content, and a serverless contact form. Deployed globally with CloudFront CDN and automated deployment pipeline. Perfect for beginners wanting to learn AWS hands-on!",
        heroImageURL: "https://prod-assets.cosmic.aws.dev/a/31juGbE9hhDnjwgoTQ6x9sVI4qs/SERV.webp",
        tags: ["cloud-launch-challenge-1", "aws-skill-builder", "aws-community-builders", "q-developer-challenge-2", "tutorials"],
        versionID: "31pqU7x2vtQG0kBLTnbbSGqcNKF"
    )

    // Author
    let author = Author(
        alias: "se7enaj",
        avatarURL: "https://avatars.builderprofile.aws.dev/30DznECgSvIJBLZbHM04z7gjmHn.webp",
        creatorID: "f1da81ac-4214-4b77-8256-3a20e76d91d9",
        isAmazonEmployee: false,
        preferredName: "Ajay kumar yegireddi",
        bio: nil,
        headline: "Senior SRE"
    )

    // Markdown body (trim or keep as-is)
    let md = #"""
## From Zero to Cloud Hero: My 7-Day Journey Building a Serverless Portfolio with AWS

A week ago, I was just another developer with local projects and basic web hosting knowledge. Today, I have a fully functional, globally distributed portfolio website with a serverless contact form that automatically notifies me via email. This is the power of AWS and the incredible learning journey I experienced during the AWS Builder Challenge #2.

##

<Youtube id="D45WvdLdmAg" />

##

## WHY MY WEBSITE DIFFERENT AND HELP OTHERS

* It contains my portfolio
* AWS Learning Hub: Cloud Practitioner study guides, practice exams, and certification resources
* DevSecOps Roadmap: Security-first development practices and tools
* Container Technologies: Docker tutorials and Kubernetes orchestration insights
* AI & Machine Learning: Webinar resources and learning materials
* Professional Portfolio: Showcase of projects and technical skills

### **🌐 My Live Website**

**Visit my portfolio:** [ONE FOR ALL ](https://main.d2maobwlukik2v.amplifyapp.com/)

**💻 What I Learned** 
* [Day 1 Building a Secure Foundation](https://builder.aws.com/content/31RlV3hm4onN9If2JBS63buQsqf/day-1-building-a-secure-foundationyour-aws-account-onboarding-guide)
* [Day 2 Simple Storage Service (Amazon S3)](https://builder.aws.com/content/31SMK3Qzb8bTLImcRZK2tenF2zm/day-2-unlocking-the-power-of-amazon-s3-for-secure-scalable-cloud-storage)
* [Day 3 deploy personal website to cloud with S3](https://builder.aws.com/content/31V8LEzMoxreYoeihHcqfYCaJ6s/day-3-build-customize-and-deploy-personal-website-to-cloud-with-s3)
* [Day 4 AWS CloudFront Global Distribution: Solving the latency](https://builder.aws.com/content/31WuJyrRhw8cPno1V2q0KxDJUUT/day-4-aws-cloudfront-global-distribution-solving-the-latency)
* [Day 5 Automating deployment with Amplify](https://builder.aws.com/content/31aQH8ShUXDaaiMPJkBWFcnWPO3/automating-website-deployment-with-amplify)
* [Day 6 Building a Professional Contact Form with AWS Services](https://builder.aws.com/content/31d7fX74tRB8So8QtMvAYzIaHmI/day-6-building-a-professional-contact-form-with-aws-services)

DAY 7 -- IS my success story of deploying it.

## 💻 What I Built

I created a comprehensive portfolio website that showcases my AWS DevOps expertise, complete with:

### Core Website Features:

* Responsive Design: Modern, mobile-first interface using HTML5 and CSS3 with CSS Grid and Flexbox
* Interactive Contact Form: Serverless form powered by AWS Lambda and SNS with real-time validation
* Global CDN: Lightning-fast loading worldwide via CloudFront with edge locations in 225+ cities
* Secure Storage: Private S3 bucket with public content delivery and proper IAM policies
* Automated Deployment: CI/CD pipeline with GitHub and AWS Amplify for seamless updates

### **DAY - 1** 
**Key Learning:** Security first, always! AWS security is comprehensive but requires proper configuration.
...
"""#

    // FeedContent
    let feed = FeedContent(
        author: author,
        commentsCount: 24,
        contentID: "/content/31fubMC8b1gkqDgPGLxuZN59dDR",
        contentType: .article,
        contentTypeSpecificResponse: ContentTypeSpecificResponse(article: article),
        createdAt: 1756231374,      // ms -> s
        isLiked: false,
        lastModifiedAt: 1756231415, // ms -> s
        lastPublishedAt: 1755932814,// ms -> s
        likesCount: 158,
        locale: .en,
        markdownDescription: md,
        status: .live,
        title: "How I Built a Serverless Portfolio That Scales to Millions ☁️ λ  | Day 7"
    )

    NavigationView {
        BCArticleDetails(bcArticle: feed)
    }
}
