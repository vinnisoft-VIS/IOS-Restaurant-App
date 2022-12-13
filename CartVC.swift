//
//  CartVC.swift
//  Denis Kebap
//
//  Created by Apple Developer on 26/07/21.
//

import UIKit
import SwiftGifOrigin
class CartVC: UIViewController,CartTblCellButtons,selectedTime,selectedAddons,refreshAfterOrderPlaced {
    
    
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var imgEmptyCart: UIImageView!
    @IBOutlet weak var tblHeight: NSLayoutConstraint!
    @IBOutlet weak var lblPickupTime: UILabel!
    @IBOutlet weak var lblItemTotal: UILabel!
    @IBOutlet weak var lblTaxesAndCharges: UILabel!
    @IBOutlet weak var lblToPay: UILabel!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var btnPayAtRestaurant: UIButton!
    @IBOutlet weak var viewOnlinePayment: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    var arrCartProducts : [CartData]?
    // Cart Control Variables
    var selectedIndexes = [[String:Int]]()
    var selectedIngredients = [[String]]()
    var selectedIngredientIds = [[String]]()
    var selectedAddOns = [[String]]()
    var selectedAddOnsIds = [[String]]()
    var timeArray = [String]()
    var amountToPay = String()
    var preparingTime = String()
    var productTimerId = String()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {

        self.checkForSkipLogin()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.lblPickupTime.text = ""
    }
    
    
    //MARK:- Table View Cell Button Actions
    func btnAdd(cell: CartTblCell) {
        if let indexPath = tblView.indexPath(for: cell){
            selectedIndexes.append(["index":indexPath.row,"cartCount":1])
        }
        self.tblView.reloadData()
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddOnVC") as! AddOnVC
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    func btnSubtract(cell: CartTblCell) {
        if let indexPath = tblView.indexPath(for: cell){
            if let index = selectedIndexes.firstIndex(where: {$0["index"]! == indexPath.row}){
                let dict = selectedIndexes[index]
                if let cartCount = dict["cartCount"]{
                    if cartCount == 1{
                        let product = arrCartProducts?[indexPath.row]
                        if let id = product?.id{
                            self.deleteCartProduct(id: id)
                        }
                    }else{
                        let product = arrCartProducts?[indexPath.row]
                        if let id = product?.id{
                            self.editCartProduct(id: id, ingredients: self.selectedIngredientIds[indexPath.row], addOns: self.selectedAddOnsIds[indexPath.row], quantity: "\(cartCount - 1)", isSubtract: 1, cartCount: cartCount, index: indexPath.row, editIndex : index)
                        }
                    }
                }
            }
        }
    }
    
    func btnAddItem(cell: CartTblCell) {
        if let indexPath = tblView.indexPath(for: cell){
            if let index = selectedIndexes.firstIndex(where: {$0["index"]! == indexPath.row}){
                let dict = selectedIndexes[index]
                if let cartCount = dict["cartCount"]{
                    let product = arrCartProducts?[indexPath.row]
                    if let id = product?.id{
                        self.editCartProduct(id: id, ingredients: self.selectedIngredientIds[indexPath.row], addOns: self.selectedAddOnsIds[indexPath.row], quantity: "\(cartCount + 1)", isSubtract: 2, cartCount: cartCount, index: indexPath.row, editIndex : index)
                    }
                }
            }
        }
    }
    
    func btnCutomized(cell: CartTblCell) {
        
        if let indexPath = tblView.indexPath(for: cell){
            let product = arrCartProducts?[indexPath.row]
            if let id = product?.product_id{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddOnVC") as! AddOnVC
                vc.productId = id
                vc.preselectedIngredients = self.selectedIngredientIds[indexPath.row]
                vc.preselectedAddOns = self.selectedAddOnsIds[indexPath.row]
                vc.isFromCart = true
                vc.preSelectedIndex = indexPath.row
                vc.selectedValuesDelegate = self
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func checkForSkipLogin(){
        let isLogin = self.checkAlreadyLogin()
        if isLogin{
            getCart()
        }else{
            let story = UIStoryboard(name: "Main", bundle:nil)
            let vc = story.instantiateViewController(withIdentifier: "FirstViewController") as! FirstViewController
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true
            UIApplication.shared.windows.first?.rootViewController = nav
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
    
    @IBAction func btnSelectPickupTime(_ sender: Any) {
        if self.arrCartProducts?.count ?? 0 > 0{
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PickUpTimeVC") as! PickUpTimeVC
            vc.delegate = self
            let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
            vc.userId = userId
            vc.preparingTime = self.preparingTime
            vc.productTimerId = self.productTimerId
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnDropdown(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddOnVC") as! AddOnVC
        vc.modalPresentationStyle = .overFullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func btnContinue(_ sender: Any) {
        if lblPickupTime.text == ""{
            self.showToast(msg: "SelectPickUpTime".localized())
        }else{
            let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PaymentVC") as! PaymentVC
            vc.link = "\(serverBaseURL)\(Apis.makePayment)?userId=\(userId)&GrandTotal=\(self.amountToPay)"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func btnPayAtRestaurant(_ sender: Any) {
        if self.lblPickupTime.text == ""{
            self.showAlert(message: "SelectPickUpTime".localized(), strtitle: "")
        }else{
            self.showAlertWithCancel_Red(message: "SureToPlaceOrder".localized(), strtitle: "", okTitle: "Confirm".localized(), cancel: "Cancel".localized()) { (success) in
                self.insertSelectedTime()
            } Cancelhandler: { (cancel) in
                
            }
        }
    }
    
    //MARK:- Functions
    
    func selectedTime(time: String) {
        lblPickupTime.text = time
    }
    
    func refresh() {
        getCart()
        self.tabBarController?.selectedIndex = 0
    }
    
    func addOns(selectedIngredients: [String], selectedAddOns: [String], preselectedIndex: Int) {
        self.selectedIngredientIds[preselectedIndex] = selectedIngredients
        self.selectedAddOnsIds[preselectedIndex] = selectedAddOns
        let product = arrCartProducts?[preselectedIndex]
        if let index = selectedIndexes.firstIndex(where: {$0["index"]! == preselectedIndex}){
            let dict = selectedIndexes[index]
            if let cartCount = dict["cartCount"]{
                if let id = product?.id{
                    self.editCartProduct(id: id, ingredients: self.selectedIngredientIds[preselectedIndex], addOns: self.selectedAddOnsIds[preselectedIndex], quantity: "\(cartCount)", isSubtract: 0, cartCount: cartCount, index: preselectedIndex, editIndex : index)
                }
            }
        }
    }
}
extension CartVC: UITableViewDataSource,UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCartProducts?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tblView.dequeueReusableCell(withIdentifier: "CartTblCell", for: indexPath) as! CartTblCell
        cell.cellDelegate = self
        let product = arrCartProducts?[indexPath.row]
        if let name = product?.product_name{
            cell.lblTitle.text = name
        }
        if let ingridients = product?.ingredients_name{
            cell.lblDescription.text = ingridients.joined(separator: ", ")
        }
        if let price = product?.product_price{
            cell.lblPrice.text = "€ \(price)"
        }
        if let index = selectedIndexes.firstIndex(where: {$0["index"]! == indexPath.row}){
            let dict = selectedIndexes[index]
            if let cartCount = dict["cartCount"]{
                if cartCount > 0{
                    cell.btnAdd.isHidden = true
                    cell.lblItemCount.text = "\(cartCount)"
                    cell.viewAddSubtract.isHidden = false
                }else{
                    cell.btnAdd.isHidden = false
                    cell.viewAddSubtract.isHidden = true
                }
            }
        }else{
            cell.btnAdd.isHidden = false
            cell.viewAddSubtract.isHidden = true
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension CartVC{
    //MARK:- API Methods
    private func getCart(){
        let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
        let params = ["userId":userId]
        self.selectedIndexes.removeAll()
        self.selectedIngredients.removeAll()
        self.selectedIngredientIds.removeAll()
        self.selectedAddOns.removeAll()
        self.selectedAddOnsIds.removeAll()
        self.tblView.isUserInteractionEnabled = true
        
        RVApiManager.postAPI(Apis.getCart, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (cartData:CartModal) in
            if let success = cartData.success{
                self?.lblPickupTime.text = ""
                if success == 1{
                    self?.scrollView.isHidden = false
                    self?.btnContinue.isEnabled = true
                    self?.btnPayAtRestaurant.isEnabled = true
                    self?.viewOnlinePayment.isHidden = false
                    self?.btnPayAtRestaurant.isHidden = false
                    if let data = cartData.data{
                        self?.arrCartProducts = data
                        self?.imgEmptyCart.isHidden = true
                        self?.tblView.isHidden = false
                        self?.btnContinue.isEnabled = true
                        self?.navigationController!.tabBarItem.badgeValue = "\(data.count)"
                        var index = -1
                        for i in self?.arrCartProducts ?? []{
                            index = index + 1
                            if let quantity = i.quantity{
                                self?.selectedIndexes.append(["index": index ,"cartCount": Int(quantity) ?? 0])
                            }
                            if let ingredients = i.ingredients_name{
                                self?.selectedIngredients.append(ingredients)
                            }
                            if let ingredientIds = i.ingredients_id{
                                self?.selectedIngredientIds.append(ingredientIds)
                            }
                            if let addOns = i.addson_name{
                                self?.selectedAddOns.append(addOns)
                            }
                            if let addOnsIds = i.addson_id{
                                self?.selectedAddOnsIds.append(addOnsIds)
                            }
                        }
                        if let itemTotal = cartData.TotalPrice{
                            self?.lblItemTotal.text = "€ \(itemTotal)"
                            if let tax = cartData.Tax{
                                self?.lblTaxesAndCharges.text = "€ \(tax)"
                            }
                            if let grandTotal = cartData.GrandTotal{
                                self?.lblToPay.text = "€ \(grandTotal)"
                                self?.amountToPay = grandTotal
                            }
                        }
                        if let times = cartData.timer{
                            self?.timeArray = times
                        }
                        if let preTime = cartData.preparingTime{
                            self?.preparingTime = "\(preTime)"
                        }
                        if let timerProductId = cartData.timerProductId{
                            self?.productTimerId = timerProductId
                        }
                        
                    }
                    self?.tblHeight.constant = CGFloat(self?.arrCartProducts?.count ?? 0) * 90
                    self?.tblView.reloadData()
                }else{
                    self?.navigationController!.tabBarItem.badgeValue = nil
                    self?.viewOnlinePayment.isHidden = true
                    self?.btnPayAtRestaurant.isHidden = true
                    self?.scrollView.isHidden = true
                    self?.imgEmptyCart.isHidden = false
                    self?.imgEmptyCart.loadGif(name: "emptyCart")
                    self?.btnContinue.isEnabled = false
                    self?.btnContinue.isEnabled = false
                    self?.btnPayAtRestaurant.isEnabled = false
                    self?.tblView.reloadData()
                    self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
                }
            }else{
                self?.viewOnlinePayment.isHidden = true
                self?.btnPayAtRestaurant.isHidden = true
                self?.scrollView.isHidden = true
                self?.imgEmptyCart.isHidden = false
                self?.btnContinue.isEnabled = false
                self?.btnPayAtRestaurant.isEnabled = false
                self?.imgEmptyCart.loadGif(name: "emptyCart")
                self?.lblPickupTime.text = ""
                self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
            }
        }
    }
    
    private func createOfflineOrder(){
        let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
        let params = ["userId":userId,"GrandTotal":self.amountToPay]
        RVApiManager.postAPI(Apis.payAtRestaurant, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (cartData:CartModal) in
            
            if let success = cartData.success{
                if success == 1{
                    let vc = self?.storyboard?.instantiateViewController(withIdentifier: "OrderPlacedVC") as! OrderPlacedVC
                    vc.delegate = self
                    self?.present(vc, animated: true, completion: nil)
                }else{
                    self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
                }
            }else{
                self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
            }
        }
    }
    
    private func deleteCartProduct(id:String){
        let params = ["id":id,"timerProductId":self.productTimerId]
        self.tblView.isUserInteractionEnabled = false
        RVApiManager.postAPI(Apis.deleteFromCart, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (cartData:CartModal) in
            self?.tblView.isUserInteractionEnabled = true
            if let success = cartData.success{
                if success == 1{
                    self?.getCart()
                }else{
                    self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
                }
            }else{
                self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
            }
        }
    }
    
    private func editCartProduct(id:String, ingredients:[String], addOns: [String], quantity: String, isSubtract : Int, cartCount: Int, index : Int,editIndex:Int){
        let params = ["id":id,"ingredients_id": "\(ingredients)", "addson_id": "\(addOns)", "quantity":quantity]
        self.tblView.isUserInteractionEnabled = false
        RVApiManager.postAPI(Apis.editCart, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (cartData:CartModal) in
            self?.tblView.isUserInteractionEnabled = true
            if let success = cartData.success{
                if success == 1{
                    if isSubtract == 0{
                        self?.selectedIndexes[editIndex] = ["index":index,"cartCount": cartCount]
                    }else if isSubtract == 1{
                        self?.selectedIndexes[editIndex] = ["index":index,"cartCount": cartCount - 1]
                    }else{
                        self?.selectedIndexes[editIndex] = ["index":index,"cartCount": cartCount + 1]
                    }
                    self?.getCart()
                }else{
                    self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
                }
            }else{
                self?.showToast(msg: cartData.message ??  "SomethingWentWrong".localized())
            }
        }
    }
    
    func insertSelectedTime(){
        let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
        let params = ["userId":userId,"user_time": self.lblPickupTime.text ?? "", "preparingTime":self.preparingTime,"timerProductId":self.productTimerId]
        RVApiManager.postAPI(Apis.insertTime, parameters: params, Vc: self, showLoader: true) { [weak self] (data: ProductAvailabilityModal) in
            if let success = data.success{
                if success == 1{
                    self?.createOfflineOrder()
                }else{
                    if let msg = data.message{
                        self?.showAlert(message: msg, strtitle: "")
                    }
                    self?.lblPickupTime.text = ""
                }
            }else{
                self?.showAlert(message: data.message ?? "Something went wrong", strtitle: "")
            }
        }
    }
}
