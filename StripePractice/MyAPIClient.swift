//
//  MyAPIClient.swift
//  StripePractice
//
//  Created by Sidharth Mehta on 2022-01-14.
//

import Foundation
import Alamofire
import Stripe

class MyAPIClient: NSObject, STPCustomerEphemeralKeyProvider {
    
    
    // To Genrate empheral key
    
    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let parameters = ["api_version":apiVersion]
        
        AF.request(URL(string: "http://192.168.2.180:8888/StripeBackend-master/empheralkey.php")!, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: [:]).responseJSON { apiResponse in
            
            let data = apiResponse.data
            guard let json = ((try? JSONSerialization.jsonObject(with: data!, options: []) as? [String:Any]) as [String:Any]??) else{
                completion(nil,apiResponse.error)
                return
            }
            completion(json, nil)
        
        }
    }
    
    
    static func createCustomer(){
        
       var customerDetailParams = [String:String]()
        customerDetailParams["email"] = "test@gmail.com"
        customerDetailParams["phone"] = "4169301994"
        customerDetailParams["name"] = "James"
        
        
        AF.request(URL(string: "http://192.168.2.180:8888/StripeBackend-master/createCustomer.php")!, method: .post, parameters: customerDetailParams, encoding: URLEncoding.default, headers: nil).responseJSON { (response) in

            if let error = response.error {
                print(error)
            }

            guard let data = response.data else {
                return
            }

            print(data)
        }
      
    }
    
    
   static func createPaymentIntent(amount:Double,currency:String,customerId:String,completion:@escaping(Result<String,Error>) -> Void )  {
        
        AF.request(URL(string: "http://192.168.2.180:8888/StripeBackend-master/createpaymentintent.php")!, method: .post, parameters: ["amount": amount, "customerId": customerId, "currency": currency], encoding: URLEncoding.default, headers: nil).responseJSON { response in
            
        
            
            if let data = response.data {
            
                guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:String]) as [String:String]??) else{
                completion(.failure(response.error!))
                return
            }
        completion(.success(json!["clientSecret"]!))
        }else{
            completion(.failure(response.error!))
        }
    }
    
    
    
}
}
