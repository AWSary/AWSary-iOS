//
//  PaywallView.swift
//  Magic Weather SwiftUI
//
//  Created by Cody Kerns on 1/19/21.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    /// - This binding is passed from ContentView: `paywallPresented`
    @Binding var isPresented: Bool
    /// - This can change during the lifetime of the PaywallView (e.g. if poor network conditions mean that loading offerings is slow)
    /// So set this as an observed object to trigger view updates as necessary
    @ObservedObject var userViewModel = UserViewModel.shared
    /// - The current offering saved from PurchasesDelegateHandler
    ///  if this is nil, then you might want to show a loading indicator or similar
    private var offering: Offering? {
        userViewModel.offerings?.current
    }
    var body: some View {
        PaywallContent(offering: self.offering, isPresented: self.$isPresented)
    }
}

private struct PaywallContent: View {
    var offering: Offering?
    var isPresented: Binding<Bool>
    /// - State for displaying an overlay view
    @State private var isPurchasing: Bool = false
    @State private var error: NSError?
    @State private var displayError: Bool = false
   @ObservedObject var userModel = UserViewModel.shared

    var body: some View {
            ZStack {
                /// - The paywall view list displaying each package
                List {
                   Section(header: Text("\nAWSary Premium")){
                      if self.userModel.subscriptionActive{
                         Text("❤️ Thanks for supporting AWSary ❤️\n\nCurrently AWSary Premium don't unlock you anything.\n\nIf you like this Application and want to pay a coffee to keep this app beeing developed, consider subscribing.")
                      } else {
                         Text("Currently AWSary Premium don't unlock you anything.\n\nIf you like this Application and want to pay a coffee to keep this app beeing developed, consider subscribing.")
                      }
                   }
                    Section(header: Text("\nChose your Premium subscription"), footer: Text("Thanks for supporting AWSary ❤️")) {
                        ForEach(offering?.availablePackages ?? []) { package in
                            PackageCellView(package: package) { (package) in

                                /// - Set 'isPurchasing' state to `true`
                                isPurchasing = true

                                /// - Purchase a package
                                do {
                                    let result = try await Purchases.shared.purchase(package: package)

                                    /// - Set 'isPurchasing' state to `false`
                                    self.isPurchasing = false

                                    if !result.userCancelled {
                                        self.isPresented.wrappedValue = false
                                    }
                                } catch {
                                    self.isPurchasing = false
                                    self.error = error as NSError
                                    self.displayError = true
                                }
                            }
                        }
                    }
                   Text("- Payment will be charged to your Apple ID account at the confirmation of purchase.\n\n- Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.\n\n- Your account will be charged for renewal within 24 hours prior to the end of the current period.\n\n- You can manage and cancel your subscriptions by going to your account settings in the App Store after purchase.").font(Font.system(Font.TextStyle.footnote))
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarTitle("✨ AWSary Premium")
                .navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.bottom)
               
                /// - Display an overlay during a purchase
                Rectangle()
                    .foregroundColor(Color.black)
                    .opacity(isPurchasing ? 0.5: 0.0)
                    .edgesIgnoringSafeArea(.all)
               
        }
        .alert(
            isPresented: self.$displayError,
            error: self.error,
            actions: { _ in
                Button(role: .cancel,
                       action: { self.displayError = false },
                       label: { Text("OK") })
            },
            message: { Text($0.recoverySuggestion ?? "Please try again") }
        )
    }
}

/* The cell view for each package */
private struct PackageCellView: View {
    let package: Package
    let onSelection: (Package) async -> Void
    
    var body: some View {
        Button {
            Task {
                await self.onSelection(self.package)
            }
        } label: {
            self.buttonLabel
        }
        .buttonStyle(.plain)
    }

    private var buttonLabel: some View {
        HStack {
            VStack {
                HStack {
                    Text(package.storeProduct.localizedTitle)
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                }
                HStack {
                    Text(package.terms)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding([.top, .bottom], 8.0)
            Spacer()
            Text(package.localizedPriceString)
                .font(.title3)
                .bold()
        }
        .contentShape(Rectangle()) // Make the whole cell tappable
    }
}

extension NSError: LocalizedError {
    public var errorDescription: String? {
        return self.localizedDescription
    }

}

struct PaywallView_Previews: PreviewProvider {
    private static let product2 = TestStoreProduct(
        localizedTitle: "Anual Premium",
        price: 34.99,
        localizedPriceString: "€7,99",
        productIdentifier: "pt.tig.awsary",
        productType: .autoRenewableSubscription,
        localizedDescription: "Description",
        subscriptionGroupIdentifier: "group",
        subscriptionPeriod: .init(value: 1, unit: .year),
        introductoryDiscount: nil,
        discounts: []
    )
    private static let offering = Offering(
        identifier: Self.offeringIdentifier,
        serverDescription: "Main offering",
        metadata: [:],
        availablePackages: [
            .init(
                identifier: "annual",
                packageType: .annual,
                storeProduct: product2.toStoreProduct(),
                offeringIdentifier: Self.offeringIdentifier
            )
        ]
    )
    private static let offeringIdentifier = "premium"
    static var previews: some View {
        PaywallContent(offering: Self.offering, isPresented: .constant(true))
    }

}
