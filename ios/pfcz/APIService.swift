import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://caropii.onrender.com"
    
    private init() {}
    
    // 食事データをRailsに送信
    func sendFoodEntry(food: Food, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/food_entries") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let foodEntry = [
            "food_entry": [
                "food_name": food.name,
                "protein": food.protein,
                "fat": food.fat,
                "carbs": food.carbs,
                "calories": food.calories,
                "consumed_at": ISO8601DateFormatter().string(from: Date())
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: foodEntry)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    completion(.success(()))
                } else {
                    completion(.failure(APIError.serverError))
                }
            }
        }.resume()
    }
    
    // AI分析結果を取得
    func getAIAnalysis(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/food_entries/analyze_nutrition") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let analysis = json["analysis"] as? String {
                        completion(.success(analysis))
                    } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let error = json["error"] as? String {
                        completion(.failure(APIError.customError(error)))
                    } else {
                        completion(.failure(APIError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case serverError
    case invalidResponse
    case customError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが受信できませんでした"
        case .serverError:
            return "サーバーエラーが発生しました"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .customError(let message):
            return message
        }
    }
}