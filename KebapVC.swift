//
//  KebapVC.swift
//  Denis Kebap
//
//  Created by Apple Developer on 20/07/21.
//

import UIKit

class KebapVC: UIViewController,kebapTblCellButtons,itemAdded {
    @IBOutlet weak var tblView: UITableView!
    var categoryId = String()
    // Cart Control Variables
    var selectedIndexes = [[String:Int]]()
    var  arrProducts: [ProductsModalData]?
    var  categoryName = String()
    var categoryImage = String()
    @IBOutlet weak var viewViewCart: UIView!
    @IBOutlet weak var lblCartItems: UILabel!
    @IBOutlet weak var viewCartHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getProducts()
        
    }
    
    
    //MARK:- Table View Cell Button Actions
    func btnAdd(cell: KebapTblCell) {
        
        let isLogin = self.checkAlreadyLogin()
        if isLogin{
            if let indexPath = tblView.indexPath(for: cell){
                let product = arrProducts?[indexPath.row]
                if let id = product?.id{
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddOnVC") as! AddOnVC
                    vc.productId = id
                    vc.delegate = self
                    vc.modalPresentationStyle = .overFullScreen
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }else{
            let story = UIStoryboard(name: "Main", bundle:nil)
            let vc = story.instantiateViewController(withIdentifier: "FirstViewController") as! FirstViewController
            let nav = UINavigationController(rootViewController: vc)
            nav.navigationBar.isHidden = true
            UIApplication.shared.windows.first?.rootViewController = nav
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
    
    func btnSubtract(cell: KebapTblCell) {
        if let indexPath = tblView.indexPath(for: cell){
            let product = arrProducts?[indexPath.row]
            if let isCustomized = product?.variantDiffer{
                if isCustomized != "0"{
                    self.showAlertWithCancel_Red(message: "The item has multiple customizations added.Proceed to cart to remove item?", strtitle: "", okTitle: "Proceed", cancel: "Cancel") { (success) in
                        self.tabBarController?.selectedIndex = 2
                    } Cancelhandler: { (cancel) in
                        
                    }
                }else{
                    if let cartCount = product?.CartCount{
                        if let cartId = product?.CartID{
                            self.decreaseQuantity(cartId: cartId, cartQuatity: "\(cartCount)")
                        }
                    }
                }
            }
        }
    }
    
    func btnAddItem(cell: KebapTblCell) {
        
        if let indexPath = tblView.indexPath(for: cell){
            let product = arrProducts?[indexPath.row]
            if let id = product?.id{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddOnVC") as! AddOnVC
                vc.productId = id
                vc.delegate = self
                vc.modalPresentationStyle = .overFullScreen
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func btnViewCart(_ sender: Any) {
        self.tabBarController?.selectedIndex = 2
    }
    
    
    //MARK:- Functions
    func itemAdded() {
        //        self.tabBarController?.selectedIndex = 2
        self.getProducts()
    }
    
}
extension KebapVC: UITableViewDataSource,UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let image = UIImageView()
        let label = UILabel()
        view.frame = CGRect(x: 0, y: 0, width: tblView.frame.width, height: 200)
        image.frame = CGRect(x: 8, y: 10, width: Int(view.frame.width) - 16, height: 150)
        label.frame = CGRect(x: 16, y: 170, width: Int(view.frame.width) - 16, height: 30)
        label.font = UIFont(name: "Poppins-Bold", size: 22.0)
        label.textColor  = .black
        label.text = categoryName
        image.layer.borderWidth = 1
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.cornerRadius = 15
        image.sd_setImage(with: URL(string: categoryImage), placeholderImage: UIImage(named: "ic_first_back"))
        view.clipsToBounds = true
        image.clipsToBounds = true
        view.addSubview(image)
        view.addSubview(label)
        return view
    }
//    func numberOfSections(in tableView: UITableView) -> Int {
//        var numOfSection: NSInteger = 0
//        if arrProducts?.count ?? 0 > 0
//        {
//            self.tblView.backgroundView = nil
//            numOfSection = 1
//        }
//        else
//        {
//            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.tblView.bounds.size.width, height: self.tblView.bounds.size.height))
//            noDataLabel.text = "No Proucts found"
//            noDataLabel.textColor = .black
//            noDataLabel.textAlignment = NSTextAlignment.center
//            self.tblView.backgroundView = noDataLabel
//        }
//        return numOfSection
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 200
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrProducts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tblView.dequeueReusableCell(withIdentifier: "KebapTblCell", for: indexPath) as! KebapTblCell
        cell.cellDelegate = self
        
        let product = arrProducts?[indexPath.row]
        if let productName = product?.name{
            cell.lblTitle.text = productName
        }
        if let ingredients = product?.ingredients{
            cell.lblDescription.text = ingredients.joined(separator: ", ")
        }
        if let price = product?.price{
            cell.lblPrice.text = "Є \(price)"
        }
        if let cartCount = product?.CartCount{
            if cartCount == "0"{
                cell.viewAddSubtract.isHidden = true
                cell.btnAdd.isHidden = false
            }else{
                cell.btnAdd.isHidden = true
                cell.viewAddSubtract.isHidden = false
                cell.lblItemCount.text = cartCount
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension KebapVC{
    private func getProducts(){
        let selectedLocation = UserDefaults.standard.value(forKey: "selectedLocation") as? String ?? "1"
        let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
        let params = ["cat_id":self.categoryId,"location": selectedLocation,"userId":userId]
        RVApiManager.postAPI(Apis.getProducts, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (products:ProductsModal) in
            if let success = products.success{
                if let image = products.category_image{
                    self?.categoryImage = image
                }
                if success == 1{
                    if let data = products.data{
                        self?.arrProducts = data
                    }
                }else{
                    self?.showToast(msg: products.message ??  "SomethingWentWrong".localized())
                }
                self?.tblView.reloadData()
            }else{
                self?.showToast(msg: products.message ??  "SomethingWentWrong".localized())
            }
            self?.getCart()
        }
    }
    
    private func getCart(){
        let userId = UserDefaults.standard.value(forKey: "userId") as? String ?? ""
        let params = ["userId":userId]
        RVApiManager.postAPI(Apis.getCart, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (cartData:CartModal) in
            if let success = cartData.success{
                if success == 1{
                    if let data = cartData.data{
                        self?.viewCartHeight.constant = 50
                        self?.viewViewCart.isHidden = false
                        if let total = cartData.GrandTotal{
                            let currentLang = UserDefaults.standard.value(forKey: "selectedLanguage") as? String ?? "de"
                            if data.count == 1{
                                if currentLang == "en" {
                                    self?.lblCartItems.text = "\(data.count) Item | Є \(total)"
                                } else {
                                    self?.lblCartItems.text = "\(data.count) Produkte | Є \(total)"
                                }
                            } else {
                                if currentLang == "en" {
                                    self?.lblCartItems.text = "\(data.count) Items | Є \(total)"
                                } else {
                                    self?.lblCartItems.text = "\(data.count) Produkte | Є \(total)"
                                }
                            }
                        }
                        self?.tabBarController?.tabBar.items![2].badgeValue = "\(data.count)"
                        
                    }else{
                        self?.tabBarController?.tabBar.items![2].badgeValue = nil
                        self?.viewCartHeight.constant = 0
                        self?.viewViewCart.isHidden = true
                    }
                }else{
                    self?.tabBarController?.tabBar.items![2].badgeValue = nil
                    self?.viewCartHeight.constant = 0
                    self?.viewViewCart.isHidden = true
                }
            }
        }
    }
    
    private func decreaseQuantity(cartId: String, cartQuatity:String){
        let params = ["cart_id":cartId,"quantity": cartQuatity] as [String : Any]
        RVApiManager.postAPI(Apis.decreaseCartQuantity, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (products:ProductsModal) in
            if let success = products.success{
                if success == 1{
                    self?.getProducts()
                }else{
                    self?.showToast(msg: products.message ??  "SomethingWentWrong".localized())
                }
            }
        }
    }
    
}


