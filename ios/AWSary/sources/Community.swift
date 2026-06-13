//
//  Community.swift
//  awsary (iOS)
//
//  Created by Tiago Rodrigues on 06/08/2025.
//

import SwiftUI

public struct Community: View {
    public var body: some View {
        NavigationStack{
            VStack{
                HStack{
                    ImageLoaderView(urlString: "https://builder.aws.com/assets/Connect-AWS-Heroes-DvZA3Ttr.jpg")
                        .cornerRadius(40)
                        .frame(maxHeight: 200)
                    
                    ImageLoaderView(urlString: "https://builder.aws.com/assets/Connect-AWS-Community-Builders-CSNXyeTr.jpg")
                        .cornerRadius(40)
                        .frame(maxHeight: 200)
                }
                HStack{
                    ImageLoaderView(urlString: "https://builder.aws.com/assets/Connect-AWS-User-Groups-CxAlUT0j.jpg")
                        .cornerRadius(40)
                        .frame(maxHeight: 200)
                    
                    ImageLoaderView(urlString: "https://builder.aws.com/assets/Connect-AWS-Cloud-Clubs-BLUhtt7F.jpg")
                        .cornerRadius(40)
                        .frame(maxHeight: 200)
                }
            }
            .navigationTitle("Community")
        }
        
    }
}

#Preview {
    Community()
}
