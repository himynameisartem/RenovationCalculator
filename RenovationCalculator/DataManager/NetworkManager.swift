//
//  NetworkManager.swift
//  RenovationCalculator
//
//  Created by Artem Kudryavtsev on 07.05.2026.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    func sendToYandex(name: String, phone: String, email: String, comment: String, estimate: String?) {
        guard let url = URL(string: "https://functions.yandexcloud.net/d4etr5cmivffs85lr4d3") else { return }
        
        let fullEstimate = """
        Имя: \(name)
        Комментарий: \(comment)
        
        Смета:
        \(estimate ?? "Смета пуста")
        """
        
        let body: [String: Any] = [
            "phone": phone,
            "email": email,
            "estimate": fullEstimate
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Ошибка кодирования: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("Статус ответа: \(httpResponse.statusCode)")
            }
        }.resume()
    }
}
