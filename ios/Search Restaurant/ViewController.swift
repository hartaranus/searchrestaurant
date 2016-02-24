//
//  ViewController.swift
//  Search Restaurant
//
//  Created by NexStreamingCorp on 1/4/16.
//  Copyright © 2016 NexStreamingCorp. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
	
	
	let GOOGLE_API_KEY = "AIzaSyDfSn5O7yYTPHtBg4PC41ydWPw364h5riE"
	let FOURSQUARE_CLIENT_ID = "URC5H2RL1RHRTXAW3N30JBRBQGOUZQ2MMSSPSEPQVVXXDDQE"
	let FOURSQUARE_CLIENT_SECRET = "25SAH5QCTNA2J2O24CJ2I1DHUXMUPOVG2P2DZAKEP3GKI2ER"
	let GOOGLE_BASE_URL_HOST = "maps.googleapis.com"
	let FOURSQUARE_BASE_URL_HOST = "api.foursquare.com"
	
	@IBOutlet weak var restaurantImageView: UIImageView!
	@IBOutlet weak var restaurantName: UILabel!
	
	@IBOutlet weak var locationTextField: UITextField!
	@IBOutlet weak var restaurantTextField: UITextField!
	
	@IBOutlet weak var restaurantAddress: UILabel!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
	@IBOutlet weak var restaurantCheckins: UILabel!
    @IBOutlet weak var showRestaurantsList: UIBarButtonItem!
	
	var tapRecognizer: UITapGestureRecognizer? = nil
	var placesClient: GMSPlacesClient?
	var locationManager: CLLocationManager!
	var latlngFromCurrLoc : String?
	var currentPlaceName : String?
    var placePicker : GMSPlacePicker?
	var restaurants = [Restaurant] ()
    var count: Int = 1
    
    let radiusDefault = "800"
    
    
	
	@IBAction func searchRestaurant(sender: UIButton) {
		
		print("search restaurant")
        testAPI()
		self.dismissAnyVisibleKeyboards()
		if !self.locationTextField.text!.isEmpty && !self.restaurantTextField.text!.isEmpty {
            self.showRestaurantsList.enabled = false
			self.restaurantName.text = "Searching .... "
			self.restaurantCheckins.text = ""
			self.restaurantAddress.text = ""
			self.spinner.startAnimating()
			if let currentPlaceName = currentPlaceName  {
				if currentPlaceName != self.locationTextField.text  {
					self.latlngFromCurrLoc = nil
					print("get place by searching")
				}
			}
			if let latlng = self.latlngFromCurrLoc {
				self.getRandomRestaurant(nil, lng: nil)
                self.getRestaurants(nil, lng: nil)
				print(latlng)
			} else {
				let gURL = self.getURLForQuery()
				print(gURL)
				self.getLocationCordinates(gURL)
			}
		} else {
		
			self.restaurantName.text = "Enter both location and restaurant type!"
			self.restaurantCheckins.text = ""
			self.restaurantAddress.text = ""
		}
	
	
	}
	
	
	@IBAction func getCurrentLocation(sender: UIButton) {
		/* Use GoogleMaps API */
		print("getCurrentLocation ")
		if(!CLLocationManager.locationServicesEnabled()) {
			locationManager.requestWhenInUseAuthorization()
			return
		}
		placesClient?.currentPlaceWithCallback({
			(placeLikelihoodList: GMSPlaceLikelihoodList? , error: NSError?) -> Void in
			
			if let error = error  {
				print("Pick place error : \(error.localizedDescription)")
				return
			}
			
			self.locationTextField.text = "No Current Place"
			
			if let placeLikelihoodList = placeLikelihoodList {
				print("\(placeLikelihoodList)")
				let place = placeLikelihoodList.likelihoods.first?.place
				if let place = place {
					
					self.currentPlaceName = place.name
					self.locationTextField.text = place.name
					print("place : \(place.name)")
					var latlng: CLLocationCoordinate2D!
					latlng = place.coordinate
					print(latlng)
					self.latlngFromCurrLoc = "\(latlng.latitude),\(latlng.longitude)"
				
				}
			}
		})
		
	}
	
    @IBAction func pickPlace(sender: UIButton) {
        let center = CLLocationCoordinate2DMake(37.5667, 126.9667)
        let northEast = CLLocationCoordinate2DMake(center.latitude + 0.001, center.longitude + 0.001)
        let southWest = CLLocationCoordinate2DMake(center.latitude - 0.001, center.longitude - 0.001)
        let viewport = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let config = GMSPlacePickerConfig(viewport: viewport)
        placePicker = GMSPlacePicker(config: config)
        
        placePicker?.pickPlaceWithCallback({ (place: GMSPlace?, error: NSError?) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let place = place {
                print("Place name \(place.name)")
                print("Place address \(place.formattedAddress)")
                print("Place attributions \(place.attributions)")
                self.currentPlaceName = place.name
                self.locationTextField.text = place.name
                print("place : \(place.name)")
                var latlng: CLLocationCoordinate2D!
                latlng = place.coordinate
                print(latlng)
                self.latlngFromCurrLoc = "\(latlng.latitude),\(latlng.longitude)"

            } else {
                print("No place selected")
            }
        })
        
    }
	override func viewDidLoad() {
		super.viewDidLoad()
	
		tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
		tapRecognizer?.numberOfTapsRequired = 1
		self.restaurantCheckins.text = ""
		self.restaurantAddress.text = ""
		self.spinner.stopAnimating()
		placesClient = GMSPlacesClient()
		locationManager = CLLocationManager()
        setupTextFields()
        
        if let savedRestaurants = loadRestaurants() {
            restaurants = savedRestaurants
            print("restaurants found with size :", restaurants.count)
            let randomRestaurantIndex = Int(arc4random_uniform(UInt32(restaurants.count)))
            let randomRestaurant = restaurants[randomRestaurantIndex]
            dispatch_async(dispatch_get_main_queue(), {
                self.restaurantName.font = UIFont.systemFontOfSize(20.0)
                self.restaurantName.text = randomRestaurant.name
                self.restaurantAddress.text = randomRestaurant.address
                self.restaurantImageView.image = randomRestaurant.photo
                self.showRestaurantsList.enabled = true
                self.restaurantImageView.alpha = 0.5
                
            })
            
        } else {
            print("no restaurants found")
        }
		
		
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		self.addKeyboardDismissRecognizer()
		self.subscribeKeyboardNotifications()
	}
	
	override func viewWillDisappear(animated: Bool) {
		
		self.removeKeyboardDismissRecognizer()
		self.unsubscribeKeyboardNotifications()
	}
	
	
	func getURLForQuery() -> NSURL {
		
		let googleComponents = NSURLComponents()
		googleComponents.scheme = "https"
		googleComponents.host = GOOGLE_BASE_URL_HOST
		googleComponents.path = "/maps/api/geocode/json"
		let queryString = self.locationTextField.text!.stringByReplacingOccurrencesOfString(" ", withString: "+")
		let addressItem = NSURLQueryItem(name: "address", value: queryString)
		let keyItem = NSURLQueryItem (name: "key", value: GOOGLE_API_KEY)
		
		googleComponents.queryItems = [addressItem,keyItem]
		let url = googleComponents.URL! as NSURL
		
		return url
	
	}
	
	func getLocationCordinates(url : NSURL) {
		
		let session = NSURLSession.sharedSession()
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
		
			guard (error == nil ) else {
				print("There is error in Google Geo-coding api request")
				return
			}
			
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				
				if let response = response as? NSHTTPURLResponse {
					print ("Your Google geocoding request returned an Invalid response! Status code : \(response.statusCode)")
				} else if let response = response {
					print ("Your Google geocoding request returned an Invalid response! Response : \(response)")
				} else {
					print ("Your Google geocoding request returned an Invalid response!")
				}
				
				return
			}
			
			guard let data = data else {
			
				print("No data was returned by the request")
				return
			}
			
			
			let parsedResult : AnyObject!
			
			do {
				parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			}catch {
				
				parsedResult = nil
				print("Could not parse the data as JSON : \(data)")
				return
			}
			
			
			guard let stat = parsedResult["status"] as? String where stat == "OK" else {
				print ("Google geocoding API returned an error = See error code in \(parsedResult)")
                self.stopSpinner(parsedResult["status"] as! String)
				return
			}
			
			guard let results = parsedResult["results"] as? NSArray, first = results[0] as? NSDictionary,
			 geometry = first["geometry"] as? NSDictionary,
			 location = geometry["location"] as! NSDictionary?
				else {
				print ("cannot find key location in \(parsedResult)")
				return
			}
			
			print(location)
			if let latitude = location["lat"], longitude = location["lng"] {
			
				self.getRandomRestaurant("\(latitude)", lng:  "\(longitude)")
				self.getRestaurants("\(latitude)", lng:  "\(longitude)")
			} else {
				print("latitude or longitude are nil")
				return
			}
			
		
		}
		
		task.resume()
		
		
	
	}
	
	func getRandomRestaurant(lat:String! , lng: String!)  {
		
		let foursquareComponents = NSURLComponents()
		foursquareComponents.scheme = "https"
		foursquareComponents.host = FOURSQUARE_BASE_URL_HOST
		foursquareComponents.path = "/v2/venues/search"
		
		let clientid = NSURLQueryItem(name: "client_id", value: FOURSQUARE_CLIENT_ID)
		let clientsecret = NSURLQueryItem(name: "client_secret", value: FOURSQUARE_CLIENT_SECRET)
		let version = NSURLQueryItem(name: "v", value: "20160105")
		let limit = NSURLQueryItem(name: "limit", value: "50")
        let radius = NSURLQueryItem(name:"radius", value: radiusDefault)
		var latlongStr :String
		if let latitude = lat as String!, longitude = lng as String! {
			latlongStr = String(latitude) + "," + String(longitude)
		} else {
			if let latlng = latlngFromCurrLoc {
				latlongStr = latlng
			} else  {
				latlongStr = ""
			}
		}
//		let escapedRestaurantValue = self.restaurantTextField.text!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
		let escapedRestaurantValue = "\(self.restaurantTextField.text!)"
		let latlong = NSURLQueryItem(name: "ll", value: latlongStr)
		let query = NSURLQueryItem(name: "query", value: escapedRestaurantValue)
		
		foursquareComponents.queryItems = [clientid,clientsecret, version,limit,latlong,radius,query]
		let url = foursquareComponents.URL! as NSURL
		
		print(url)
		
		let session = NSURLSession.sharedSession()
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
			
			guard (error == nil ) else {
				print("There is error in Google Geo-coding api request")
				return
			}
			
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				
				if let response = response as? NSHTTPURLResponse {
					print ("Your Google geocoding request returned an Invalid response! Status code : \(response.statusCode)")
				} else if let response = response {
					print ("Your Google geocoding request returned an Invalid response! Response : \(response)")
				} else {
					print ("Your Google geocoding request returned an Invalid response!")
				}
				
				return
			}
			
			guard let data = data else {
				
				print("No data was returned by the request")
				return
			}
			
			
			let parsedResult : AnyObject!
			
			do {
				parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			}catch {
				
				parsedResult = nil
				print("Could not parse the data as JSON : \(data)")
				return
			}
			
			
			guard let meta = parsedResult["meta"] as! NSDictionary?, stat = meta["code"] as? Int where stat == 200 else {
				print ("Google geocoding API returned an error = See error code in \(parsedResult)")
				return
			}
			
			guard let response = parsedResult["response"] as? NSDictionary, venues = response["venues"] as? NSArray where venues.count >= 1
				else {
					print ("cannot find key restaurant in \(parsedResult)")
					dispatch_async(dispatch_get_main_queue(), {
						self.restaurantName.text = "Coudn't find any restaurant - Try again"
						self.spinner.stopAnimating()
						
					})
					return
			}
			
			let venueCount = venues.count
			print(venues.count)
			let venueLimit = min(venueCount, 50)
			let randomRestaurant = Int(arc4random_uniform(UInt32(venueLimit)))
			
			if let restaurant = venues[randomRestaurant] as? NSDictionary {
					let location = restaurant["location"]!
					let formattedAddress = location["formattedAddress"]
				    let stats = restaurant["stats"]!
					let name = restaurant["name"]!
					let id = restaurant["id"]
					let checkIns = stats["checkinsCount"]
					
//					print(name, " \nAddress : " , formattedAddress, "\nstats: ", checkIns)
				if let venueId = id as! String! {
					self.getRandomPhoto(venueId)
					var checkInsCount : Int
					if let checkins = checkIns  {
						checkInsCount = checkins as! Int
					} else {
						checkInsCount = 0
					}
					
					dispatch_async(dispatch_get_main_queue(), {
						self.restaurantName.font = UIFont.systemFontOfSize(20.0)
						self.restaurantName.text = "\(name)"
						self.restaurantCheckins.text = "Checkins : \(checkInsCount)"
						var addressArray =  [String]()
						if let address = formattedAddress {
							addressArray = address as! [String]
//							print("Formatted address: ", addressArray)
							self.restaurantAddress.text = addressArray.joinWithSeparator(" ")
						}
					})

				}
				
				}
			
			
			
		}
		
		task.resume()
		
		
	}
    
    func stopSpinner(error : String!) {
        dispatch_async(dispatch_get_main_queue(), {
            self.spinner.stopAnimating()
            if let error = error {
                self.restaurantName.text = error
            }
        })
    }
	
	func getRandomPhoto(id : String!)  {
		
		let foursquareComponents = NSURLComponents()
		foursquareComponents.scheme = "https"
		foursquareComponents.host = FOURSQUARE_BASE_URL_HOST
		var venueID :String
		if let venueId = id as String! {
			venueID = venueId;
			print(venueID, " venueid : " , venueId)
		} else {
			print("venue Id is nil ")
			return
		}
		foursquareComponents.path = "/v2/venues/"+venueID+"/photos"
		
		let clientid = NSURLQueryItem(name: "client_id", value: FOURSQUARE_CLIENT_ID)
		let clientsecret = NSURLQueryItem(name: "client_secret", value: FOURSQUARE_CLIENT_SECRET)
		let version = NSURLQueryItem(name: "v", value: "20160105")
		

		
		foursquareComponents.queryItems = [clientid,clientsecret, version]
		let url = foursquareComponents.URL! as NSURL
		
		print(url)
		
		let session = NSURLSession.sharedSession()
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
			
			guard (error == nil ) else {
				print("There is error in Foursquare Photo request api request")
				self.spinner.stopAnimating()
				return
			}
			
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				
				if let response = response as? NSHTTPURLResponse {
					print ("Your Foursquare photo request returned an Invalid response! Status code : \(response.statusCode)")
				} else if let response = response {
					print ("Your Foursquare photo request returned an Invalid response! Response : \(response)")
				} else {
					print ("Your Foursquare photo  request returned an Invalid response!")
				}
				self.spinner.stopAnimating()
				return
			}
			
			guard let data = data else {
				
				print("No data was returned by the Foursquare photo  request")
				self.spinner.stopAnimating()
				return
			}
			
			
			let parsedResult : AnyObject!
			
			do {
				parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			}catch {
				
				parsedResult = nil
				print("Could not parse the data (Foursquare photo ) as JSON : \(data)")
				self.spinner.stopAnimating()
				return
			}
			
			
			guard let meta = parsedResult["meta"] as! NSDictionary?, stat = meta["code"] as? Int where stat == 200 else {
				print ("Google geocoding API returned an error = See error code in \(parsedResult)")
				self.spinner.stopAnimating()
				return
			}
			
			guard let response = parsedResult["response"] as? NSDictionary, photos = response["photos"] as? NSDictionary,
			let photoCount = photos["count"] as? Int where photoCount >= 1, let photoItems = photos["items"] as? NSArray
				else {
					print ("cannot find key / or count is zero / in \(parsedResult)")
					dispatch_async(dispatch_get_main_queue(), {
						self.spinner.stopAnimating()
						self.restaurantImageView.image = nil
					})
					return
			}
			
			let photoLimit = min(photoCount, 100)
			let randomPhoto = Int(arc4random_uniform(UInt32(photoLimit)))
			
			if let photo = photoItems[randomPhoto] as? NSDictionary {
				let prefix = photo["prefix"]!
				let suffix = photo["suffix"]!
				
				print(prefix, "original" , suffix)
				let photoURLString = (prefix as! String) + "width600" + (suffix as! String)
				let photoURL = NSURL(string:photoURLString)
				if let imageData = NSData(contentsOfURL: photoURL!) {
					dispatch_async(dispatch_get_main_queue(), {
						self.restaurantImageView.image = UIImage(data: imageData)
						self.restaurantImageView.alpha = 0.5
						
					})
				} else {
					print("Image does not exist at \(photoURL)")
				}
				
			}
			
			
			
		}
		
		task.resume()
		
	}
	
    func testAPI()  {
        
        let foursquareComponents = NSURLComponents()
        foursquareComponents.scheme = "https"
//        foursquareComponents.host = "localhost"
//        foursquareComponents.port = 8000
        foursquareComponents.host = "searchrestaurant.pythonanywhere.com"
        
   
        foursquareComponents.path = "/api/v1/"
//        ocation=insa-dong&rtype=pizza
        let format = NSURLQueryItem(name: "format", value: "json")
        let location = NSURLQueryItem(name: "location", value: "insa-dong")
        let rtype = NSURLQueryItem(name: "rtype", value: "pizza")
        
        
        
        foursquareComponents.queryItems = [format,location,rtype]
        let url = foursquareComponents.URL! as NSURL
        
        print(url)
        
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard (error == nil ) else {
                print("There is error in test rest api request")
                self.spinner.stopAnimating()
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                
                if let response = response as? NSHTTPURLResponse {
                    print ("Your api request returned an Invalid response! Status code : \(response.statusCode)")
                } else if let response = response {
                    print ("Your api request returned an Invalid response! Response : \(response)")
                } else {
                    print ("Your api request returned an Invalid response!")
                }
                self.spinner.stopAnimating()
                return
            }
            
            guard let data = data else {
                
                print("No data was returned by the api  request")
                self.spinner.stopAnimating()
                return
            }
            
            
            let parsedResult : AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
//                print(parsedResult)
                for r in parsedResult as! NSArray {
                    print(r["address"])
                }
                
            }catch {
                
                parsedResult = nil
                print("Could not parse the data (Foursquare photo ) as JSON : \(data)")
                self.spinner.stopAnimating()
                return
            }
           
        }
        
        task.resume()
        
    }
	
	// MARK: Helper methods
	
	func addKeyboardDismissRecognizer() {
		
		self.view.addGestureRecognizer(tapRecognizer!)
	}
	
	func removeKeyboardDismissRecognizer() {
		
		self.view.removeGestureRecognizer(tapRecognizer!)
	}
	
	
	func subscribeKeyboardNotifications() {
	
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
		
	
	}
	
	func unsubscribeKeyboardNotifications() {
	
		NSNotificationCenter.defaultCenter().removeObserver(self,name: UIKeyboardWillHideNotification, object:  nil)
	}
	
	func keyboardWillShow(notification: NSNotification) {
		if self.restaurantImageView.image != nil {
			self.restaurantName.alpha = 0.0
		}
		
		if self.view.frame.origin.y == 0.0  {
		
			self.view.frame.origin.y -= self.getKeyboardHeight(notification) / 1.2
		}
	
	}
	func keyboardWillHide(notification: NSNotification) {
		
		if self.restaurantImageView.image == nil {
			self.restaurantName.alpha = 1.0
		}
		
		if self.view.frame.origin.y != 0.0 {
			
			self.view.frame.origin.y += self.getKeyboardHeight(notification) / 1.2
		}
	
	}
	
	func getKeyboardHeight(notification: NSNotification) -> CGFloat {
		let userInfo = notification.userInfo
		let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
		return keyboardSize.CGRectValue().height
	}
	
	func handleSingleTap(recognizer: UITapGestureRecognizer) {
		self.view.endEditing(true)
	}

}

extension ViewController {
	func dismissAnyVisibleKeyboards()  {
	
		if locationTextField.isFirstResponder() || restaurantTextField.isFirstResponder() {
			self.view.endEditing(true)
		}
	}
	
	
	func getRestaurants(lat:String! , lng: String!)  {
		restaurants.removeAll()
		let foursquareComponents = NSURLComponents()
		foursquareComponents.scheme = "https"
		foursquareComponents.host = FOURSQUARE_BASE_URL_HOST
		foursquareComponents.path = "/v2/venues/search"
		
		let clientid = NSURLQueryItem(name: "client_id", value: FOURSQUARE_CLIENT_ID)
		let clientsecret = NSURLQueryItem(name: "client_secret", value: FOURSQUARE_CLIENT_SECRET)
		let version = NSURLQueryItem(name: "v", value: "20160105")
		let limit = NSURLQueryItem(name: "limit", value: "50")
        let radius = NSURLQueryItem(name:"radius", value: radiusDefault)
		var latlongStr :String
		if let latitude = lat as String!, longitude = lng as String! {
			latlongStr = String(latitude) + "," + String(longitude)
		} else {
			if let latlng = latlngFromCurrLoc {
				latlongStr = latlng
			} else  {
				latlongStr = ""
			}
		}
		//		let escapedRestaurantValue = self.restaurantTextField.text!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
		let escapedRestaurantValue = "\(self.restaurantTextField.text!)"
		let latlong = NSURLQueryItem(name: "ll", value: latlongStr)
		let query = NSURLQueryItem(name: "query", value: escapedRestaurantValue)
		
		foursquareComponents.queryItems = [clientid,clientsecret, version,limit,latlong,radius,query]
		let url = foursquareComponents.URL! as NSURL
		
		print(url)
		
		let session = NSURLSession.sharedSession()
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
			
			guard (error == nil ) else {
				print("There is error in Google Geo-coding api request")
				return
			}
			
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				
				if let response = response as? NSHTTPURLResponse {
					print ("Your Google geocoding request returned an Invalid response! Status code : \(response.statusCode)")
				} else if let response = response {
					print ("Your Google geocoding request returned an Invalid response! Response : \(response)")
				} else {
					print ("Your Google geocoding request returned an Invalid response!")
				}
				
				return
			}
			
			guard let data = data else {
				
				print("No data was returned by the request")
				return
			}
			
			
			let parsedResult : AnyObject!
			
			do {
				parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			}catch {
				
				parsedResult = nil
				print("Could not parse the data as JSON : \(data)")
				return
			}
			
			
			guard let meta = parsedResult["meta"] as! NSDictionary?, stat = meta["code"] as? Int where stat == 200 else {
				print ("Google geocoding API returned an error = See error code in \(parsedResult)")
				return
			}
			
			guard let response = parsedResult["response"] as? NSDictionary, venues = response["venues"] as? NSArray where venues.count >= 1
				else {
					print ("cannot find key restaurant in \(parsedResult)")
					dispatch_async(dispatch_get_main_queue(), {
						self.spinner.stopAnimating()
						
					})
					return
			}
			
			print("Total Venues : " , venues.count)
			for r in venues {
				if let restaurant = r as? NSDictionary {
					let location = restaurant["location"]!
					let formattedAddress = location["formattedAddress"]
//					let stats = restaurant["stats"]!
					let name = restaurant["name"]!
					let id = restaurant["id"]
					if let venueId = id as! String! {
						var addressArray =  [String]()
						if let address = formattedAddress {
							addressArray = address as! [String]
                            dispatch_async(dispatch_get_main_queue(), {
                                self.spinner.startAnimating()
                                
                            })
                            self.getPhotoForRestaurant(venueId,name: name as! String,address: addressArray.joinWithSeparator(" "),totalCount: venues.count)
                            
						}
					
					}
				
				}
			
			}
            
            
			
		}
		
		task.resume()
		
		
	}
	
    func getPhotoForRestaurant(id : String!, name: String!, address: String!,totalCount:Int)  {
		
		let foursquareComponents = NSURLComponents()
		foursquareComponents.scheme = "https"
		foursquareComponents.host = FOURSQUARE_BASE_URL_HOST
		var venueID :String
		if let venueId = id as String! {
			venueID = venueId;
		} else {
			return
		}
		foursquareComponents.path = "/v2/venues/"+venueID+"/photos"
		
		let clientid = NSURLQueryItem(name: "client_id", value: FOURSQUARE_CLIENT_ID)
		let clientsecret = NSURLQueryItem(name: "client_secret", value: FOURSQUARE_CLIENT_SECRET)
		let version = NSURLQueryItem(name: "v", value: "20160105")
		
		foursquareComponents.queryItems = [clientid,clientsecret, version]
		let url = foursquareComponents.URL! as NSURL
		
		let session = NSURLSession.sharedSession()
		let request = NSURLRequest(URL: url)
		
		let task = session.dataTaskWithRequest(request) { (data, response, error) in
			self.count += 1
			guard (error == nil ) else {
				print("There is error in Foursquare Photo request api request")
				self.spinner.stopAnimating()
				return
			}
			
			guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
				
				if let response = response as? NSHTTPURLResponse {
					print ("Your Foursquare photo request returned an Invalid response! Status code : \(response.statusCode)")
				} else if let response = response {
					print ("Your Foursquare photo request returned an Invalid response! Response : \(response)")
				} else {
					print ("Your Foursquare photo  request returned an Invalid response!")
				}
				self.spinner.stopAnimating()
				return
			}
			
			guard let data = data else {
				
				print("No data was returned by the Foursquare photo  request")
				self.spinner.stopAnimating()
				return
			}
			
			
			let parsedResult : AnyObject!
			
			do {
				parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
			}catch {
				
				parsedResult = nil
				print("Could not parse the data (Foursquare photo ) as JSON : \(data)")
				self.spinner.stopAnimating()
				return
			}
			
			
			guard let meta = parsedResult["meta"] as! NSDictionary?, stat = meta["code"] as? Int where stat == 200 else {
				print ("Google geocoding API returned an error = See error code in \(parsedResult)")
				self.spinner.stopAnimating()
				return
			}
			
			guard let response = parsedResult["response"] as? NSDictionary, photos = response["photos"] as? NSDictionary,
				let photoCount = photos["count"] as? Int where photoCount >= 1, let photoItems = photos["items"] as? NSArray
				else {
					return
				}
			
			let photoLimit = min(photoCount, 100)
			let randomPhoto = Int(arc4random_uniform(UInt32(photoLimit)))
			
			if let photo = photoItems[randomPhoto] as? NSDictionary {
				let prefix = photo["prefix"]!
				let suffix = photo["suffix"]!
				let photoURLString = (prefix as! String) + "width600" + (suffix as! String)
				let photoURL = NSURL(string:photoURLString)
				if let imageData = NSData(contentsOfURL: photoURL!) {
					let image  = UIImage(data: imageData)
					let restaurant = Restaurant(name: name, photo: image, address: address)!
					self.restaurants.append(restaurant)
                    self.saveRestaurants()
//					self.saveRestaurants()
                    if(self.count == (totalCount+1)) {
                        print("count : \(self.count) == \(totalCount)")
                        dispatch_async(dispatch_get_main_queue(), {
//                            self.saveRestaurants()
                            self.spinner.stopAnimating()
                            
                        })
                    } else {
                        print("count : \(self.count) != \(totalCount)")
                    }
					
				} else {
					print("Image does not exist at \(photoURL)")
				}
				
			}
			
			
			
		}
		
		task.resume()
		
	}
	
	// MARK: NSCoding
	
	func saveRestaurants() {
		deleteRestaurants()
        self.count = 0
		let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(restaurants, toFile: Restaurant.ArchiveURL.path!)

		self.spinner.stopAnimating()
		if !isSuccessfulSave {
			print("Failed to save restaurants...")
		} else {
            self.showRestaurantsList.enabled = true
			print("saved restaurants")
		}
	}
    
    func deleteRestaurants() {
        do {
        try  NSFileManager.defaultManager().removeItemAtPath(Restaurant.ArchiveURL.path!)
        } catch {
            print("couldn't delete restaurant")
        }
    
    }
    
    func loadRestaurants() -> [Restaurant]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Restaurant.ArchiveURL.path!) as? [Restaurant]
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
//        self.saveRestaurants()
        
    }
    
    // MARK : Helper methods
    
    func setupTextFields() {
        
        self.restaurantName.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.restaurantName.numberOfLines = 2
        self.showRestaurantsList.enabled = false
        self.restaurantAddress.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.restaurantAddress.numberOfLines = 0
    }

}

