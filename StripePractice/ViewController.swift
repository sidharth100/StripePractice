//
//  ViewController.swift
//  StripePractice
//
//  Created by Sidharth Mehta on 2022-01-14.
//

import UIKit
import Stripe
import PassKit

class ViewController: UIViewController {

    var customerContext : STPCustomerContext?
    var paymentContext : STPPaymentContext?
    var isSetShipping = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MyAPIClient.createCustomer()
        let config = STPPaymentConfiguration.shared
        config.fpxEnabled = true
        config.applePayEnabled = true
        config.companyName = "Tesla"
        config.shippingType = .shipping
        config.requiredShippingAddressFields = Set<STPContactField>(arrayLiteral: STPContactField.name,STPContactField.emailAddress,STPContactField.phoneNumber,STPContactField.postalAddress)
        
        customerContext = STPCustomerContext(keyProvider: MyAPIClient())
        paymentContext = STPPaymentContext(customerContext: customerContext!, configuration: config, theme: .defaultTheme)
        self.paymentContext?.delegate = self
        self.paymentContext?.hostViewController = self
        self.paymentContext?.paymentAmount = 500 // cents
        
    }

    @IBAction func createCustTapped(_ sender: Any) {
        MyAPIClient.createCustomer()
    }
    @IBAction func payTapped(_ sender: Any) {
        self.paymentContext?.presentPaymentOptionsViewController()
    }
    
}

extension ViewController: STPPaymentContextDelegate{
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        if paymentContext.selectedPaymentOption != nil && isSetShipping {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                paymentContext.presentShippingViewController()
            }
        }
        
        if paymentContext.selectedPaymentOption != nil && !isSetShipping {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                self.paymentContext?.requestPayment()
                
            }
        }
    }
    
    
    
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
    
        isSetShipping = false
        
        
        let upsGround = PKShippingMethod()
           upsGround.amount = 0
           upsGround.label = "UPS Ground"
           upsGround.detail = "Arrives in 3-5 days"
           upsGround.identifier = "ups_ground"
        
           let fedEx = PKShippingMethod()
           fedEx.amount = 5.99
           fedEx.label = "FedEx"
           fedEx.detail = "Arrives tomorrow"
           fedEx.identifier = "fedex"

           if address.country == "US" {
               completion(.valid, nil, [upsGround, fedEx], upsGround)
           }
           else {
               completion(.invalid, nil, nil, nil)
           }
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        // Request a PaymentIntent from your backend
        MyAPIClient.createPaymentIntent(amount: (Double(paymentContext.paymentAmount) + Double(Int((paymentContext.selectedShippingMethod?.amount)!))), currency: "usd", customerId: "cus_Ky29CPjzOedw2L") { (result) in
            switch result {
            case .success(let clientSecret):
                // Assemble the PaymentIntent parameters
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentResult.paymentMethod?.stripeId

                // Confirm the PaymentIntent
                STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: paymentContext) { status, paymentIntent, error in
                    switch status {
                    case .succeeded:
                        // Your backend asynchronously fulfills the customer's order, for example, via webhook
                        completion(.success, nil)
                    case .failed:
                        completion(.error, error) // Report error
                    case .canceled:
                        completion(.userCancellation, nil) // Customer cancelled
                    @unknown default:
                        completion(.error, nil)
                    }
                }
            case .failure(let error):
                completion(.error, error) // Report error from your API
                break
            }
        }
        }
            
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        switch status {
           case .error:
            print(error.debugDescription)
           case .success:
            print(status.description)
           case .userCancellation:
               return // Do nothing
           }
    }
    
    
}

