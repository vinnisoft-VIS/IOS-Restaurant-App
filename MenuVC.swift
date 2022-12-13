//
//  MenuVC.swift
//  Denis Kebap
//
//  Created by Apple Developer on 19/07/21.
//

import UIKit
import CarbonKit
import GooglePlaces
class MenuVC: UIViewController,CarbonTabSwipeNavigationDelegate {
    
    @IBOutlet weak var viewForCarbonKit: UIView!
    @IBOutlet weak var lblLocation: UILabel!
    let locationManager = CLLocationManager()
    var arrLocations : [LocationModalData]?
    var arrCategories : [CategoriesModalData]?
    override func viewDidLoad() {
        super.viewDidLoad()
        initialLoads()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getLocations { (true) in
            self.getCategories {
                self.setupUpperTabBar()
            }
        }
    }
    
    //MARK:- Actions
    
    @objc func labelTapped(tapGestureRecognizer: UITapGestureRecognizer){
        //        goToPlace()
        
        if let isAlreadyLogin = UserDefaults.standard.value(forKey: "isAlreadyLogin") as? Bool{
            if isAlreadyLogin{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LocationVC") as! LocationVC
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    @IBAction func btnLocation(_ sender: Any) {
        
        if let isAlreadyLogin = UserDefaults.standard.value(forKey: "isAlreadyLogin") as? Bool{
            if isAlreadyLogin{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "LocationVC") as! LocationVC
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    //MARK:- Funtions
    func initialLoads(){
        //            setUpLocation()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(labelTapped(tapGestureRecognizer:)))
        lblLocation.isUserInteractionEnabled = true
        lblLocation.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    func selectedLocation(loc: String) {
        self.lblLocation.text = loc
    }
    
}
extension MenuVC{
    
    //MARK:- Functions
    
    func setupUpperTabBar(){
        var items = [String]()
        for i in arrCategories ?? []{
            if let name = i.name{
                items.append(name)
            }
        }
        let carbonTabSwipeNavigation = CarbonTabSwipeNavigation(items: items, delegate: self)
        carbonTabSwipeNavigation.carbonSegmentedControl?.backgroundColor = .black
        carbonTabSwipeNavigation.setSelectedColor(.white)
        carbonTabSwipeNavigation.setNormalColor(.white)
        carbonTabSwipeNavigation.toolbarHeight.constant = 45
        carbonTabSwipeNavigation.setIndicatorColor(.white)
        carbonTabSwipeNavigation.insert(intoRootViewController: self, andTargetView: viewForCarbonKit)
    }
    
    // Carbon Kit Delegate Methods
    
    func carbonTabSwipeNavigation(_ carbonTabSwipeNavigation: CarbonTabSwipeNavigation, viewControllerAt index: UInt) -> UIViewController {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "KebapVC") as! KebapVC
        if let category = self.arrCategories?[Int(index)]{
            if let id = category.id{
                vc.categoryId = id
            }
            if let name = category.name{
                vc.categoryName = name
            }
        }
        return vc
    }
}
extension MenuVC: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        let locValue: CLLocationCoordinate2D = place.coordinate
        UserDefaults.standard.set(locValue.latitude, forKey: "latitude")
        UserDefaults.standard.set(locValue.longitude, forKey: "longitude")
        let location = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        
        location.placemark { (place, err) in
            if err == nil{
                self.lblLocation.text = "\(place?.subLocality ?? "Unnamed Area"), \(place?.subAdministrativeArea ?? "Unnamed Location")"
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
extension MenuVC: CLLocationManagerDelegate{
    
    //MARK:- Location Methods
    
    func goToPlace() {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        UserDefaults.standard.set(locValue.latitude, forKey: "latitude")
        UserDefaults.standard.set(locValue.longitude, forKey: "longitude")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedAlways:
            setUpLocation()
        case.authorizedWhenInUse:
            setUpLocation()
        case.denied:
            print("Location Permission denied")
        case .notDetermined:
            print("Location Permission not determined")
        default:
            print("Location Permission not determined")
        }
    }
    
    
    
    func setUpLocation(){
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestAlwaysAuthorization()
        
        if
            CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() ==  .authorizedAlways
        {
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            let locValue: CLLocationCoordinate2D = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            UserDefaults.standard.set(locValue.latitude, forKey: "latitude")
            UserDefaults.standard.set(locValue.longitude, forKey: "longitude")
            let location = CLLocation(latitude: locationManager.location?.coordinate.latitude ?? 0.0, longitude: locationManager.location?.coordinate.longitude ?? 0.0)
            location.placemark { (place, err) in
                if err == nil{
                    self.lblLocation.text = "\(place?.subLocality ?? ""), \(place?.subAdministrativeArea ?? "")"
                }
            }
            
        }
    }
}

extension MenuVC{
    //MARK:- API Methods
    
    private func getLocations(completion: @escaping(Bool) -> ()){
        let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? "1"
        let params = ["userId":userId]
        RVApiManager.postAPI(Apis.getLocations, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (locationData:LocationModal) in
            if let success = locationData.success{
                if success == 1{
                    if let data = locationData.data{
                        self?.arrLocations = data
                    }
                    if self?.arrLocations?.count ?? 0 > 1{
                        self?.lblLocation.text = self?.arrLocations?[0].address ?? "Select Location"
                    }
                }else{
                    self?.showToast(msg: locationData.message ??  "SomethingWentWrong".localized())
                }
            }else{
                self?.showToast(msg: locationData.message ??  "SomethingWentWrong".localized())
            }
            completion(true)
        }
    }
    
    private func getCategories(completion: @escaping()-> ()){
        let selectedLocation = UserDefaults.standard.value(forKey: "selectedLocation") as? String ?? "1"
        let params = ["location": selectedLocation]
        RVApiManager.getAPI(Apis.getCategories, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (categories:CategoriesModal) in
            if let success = categories.success{
                if success == 1{
                    if let data = categories.data{
                        self?.arrCategories = data
                    }
                    completion()
                }else{
                    self?.showToast(msg: categories.message ??  "SomethingWentWrong".localized())
                }
            }else{
                self?.showToast(msg: categories.message ??  "SomethingWentWrong".localized())
            }
        }
    }
    
}
