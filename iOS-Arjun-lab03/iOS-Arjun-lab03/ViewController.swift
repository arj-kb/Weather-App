//
//  ViewController.swift
//  iOS-Arjun-lab03
//
//  Created by Arjun K B on 2024-03-17.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var toogleTemperature: UISwitch!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var feelsLike: UILabel!
    @IBOutlet weak var conditionData: UILabel!
    
    private var whichTemperature: Bool = true
    private let locationManager = CLLocationManager()
    private let locationManagerDelegate = MyLocationManagerDelegate()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weatherConditionImage()
        searchTextField.delegate = self
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = locationManagerDelegate
        locationManagerDelegate.viewController = self
    }
    
    
    @IBAction func onToggleSwitch(_ sender: UISwitch) {
        print("Toggle switch state changed: \(sender.isOn)")
        whichTemperature = sender.isOn
        updateTemp()
    }
    
    private func updateTemp(){
        print("Temp: \(whichTemperature)")
        if searchTextField.text == nil{
            print("hello")
            locationManager.requestLocation()

        }
        else{
            print("failed")
            loadWeather(search: searchTextField.text)
  
        }
    }
    
    @IBAction func onGetLocationTapped(_ sender: UIButton) {
        // get user location
        locationManager.requestLocation()
        searchTextField.text = ""
    }
    
    private func displayLocation(locationText:String){
        locationLabel.text = locationText
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: searchTextField.text) // Trigger the search action

        return true
    }

    private func weatherConditionImage(){
//        weatherImage.image = UIImage(systemName: "cloud" )
    }
    
    @IBAction func currentLocationTapped(_ sender: UIButton) {
        
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
        
    }
    
     func loadWeather(search: String?){
        guard let search = search else{
            return
        }
        
        // get url
        guard let url = getURL(query: search) else{
            print("Could not get URL")
            return
        }
        // create URLSession
        let session = URLSession.shared
        // create task for session
        let dataTask = session.dataTask(with: url) {data, response, error in
            // network call finished
            print("Network call complete")
            
            guard error == nil else{
                print("Received error")
                return
            }
            guard let data = data else{
                print("value data found ")
                return
            }
            
            if let weatherResponse = self.parseJson(data: data) {
                print(weatherResponse)
                print(weatherResponse.location.name)
                print(weatherResponse.current.temp_c)
                print(weatherResponse.current.condition)
                print(weatherResponse.current.is_day)
                print("Tempp: \(self.whichTemperature)")



   
                DispatchQueue.main.async {
                    self.locationLabel.text = "\(weatherResponse.location.name), \(weatherResponse.location.region), \(weatherResponse.location.country)"
                    self.searchTextField.text =  "\(weatherResponse.location.name), \(weatherResponse.location.region), \(weatherResponse.location.country)"
                    if self.whichTemperature {
                        self.temperatureLabel.text = "\(weatherResponse.current.temp_c) C"
                        self.feelsLike.text = "Feels like \(weatherResponse.current.feelslike_c) C"
                        self.conditionData.text = "\(weatherResponse.current.condition.text)"
                        
                        
                    } else {
                        self.temperatureLabel.text = "\(weatherResponse.current.temp_f) F"
                        self.feelsLike.text = "Feels like \(weatherResponse.current.feelslike_f) F"
                    }
                    let code = weatherResponse.current.condition.code
                    let isDay = weatherResponse.current.is_day
                    if isDay == 1 {
                        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "dayImage")!)
                        // Changing font color to make text visible
                        self.locationLabel.textColor = UIColor.black
                        self.temperatureLabel.textColor = UIColor.black
                        self.feelsLike.textColor = UIColor.black
                        self.conditionData.textColor = UIColor.black
                    } else {
                        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "nightImage")!)
                        // Changing font color to make text visible
                        self.locationLabel.textColor = UIColor.white
                        self.temperatureLabel.textColor = UIColor.white
                        self.feelsLike.textColor = UIColor.white
                        self.conditionData.textColor = UIColor.white
                    }
                    // Grouping codes to only important weather conditions
                    switch code {
                    case 1000:
                        self.weatherImage.image = UIImage(systemName: "sun.max")
                    case 1003:
                        self.weatherImage.image = UIImage(systemName: "cloud.sun")
                    case 1006, 1009:
                        self.weatherImage.image = UIImage(systemName: "cloud")
                    case 1030:
                        self.weatherImage.image = UIImage(systemName: "cloud.fog")
                    case 1063, 1180, 1183, 1186:
                        self.weatherImage.image = UIImage(systemName: "cloud.drizzle")
                    case 1066, 1114, 1117, 1201, 1207, 1210, 1213, 1216, 1219, 1222, 1225, 1237, 1240, 1243, 1246: // Snow
                        self.weatherImage.image = UIImage(systemName: "snow")
                    case 1069, 1072, 1204, 1249:
                        self.weatherImage.image = UIImage(systemName: "cloud.sleet")
                    case 1087, 1273, 1276: // Thunderstorm
                        self.weatherImage.image = UIImage(systemName: "cloud.bolt")
                    case 1150, 1153, 1168, 1171, 1189, 1192, 1195, 1198:
                        self.weatherImage.image = UIImage(systemName: "cloud.rain")
                    // Add more cases for other weather conditions as needed
                    default:
                        self.weatherImage.image = UIImage(systemName: "questionmark")
                    }

                }

            }
            
        }
        dataTask.resume()
    }
    
    private func getURL(query: String) -> URL? {
        
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "e86c57a349d64f27bb113334241803"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else{
            return nil
        }
        return URL(string: url)
    }
    
    private func parseJson(data:Data) -> WeatherResponse? {

        //decode data
        let decoder = JSONDecoder()
        var weather : WeatherResponse?
        do{
            weather = try decoder.decode(WeatherResponse.self, from:data)
        } catch {
            print("Error decoding")
        }
        return weather
    }
}

struct WeatherResponse:Decodable {
    let location: Location
    let current: Weather
}
struct Location:Decodable {
    let name: String
    let region: String
    let country: String
}
struct Weather:Decodable {
    let temp_c: Float
    let temp_f: Float
    let is_day:Int
    let condition: WeatherCondition
    let feelslike_c: Float
    let feelslike_f: Float
}
struct WeatherCondition:Decodable {
    let text: String
    let code: Int
}
class MyLocationManagerDelegate: NSObject, CLLocationManagerDelegate{
    weak var viewController: ViewController?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Got Location")
        
        if let location = locations.last{
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            viewController?.loadWeather(search: "\(latitude),\(longitude)")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)

    }
}
