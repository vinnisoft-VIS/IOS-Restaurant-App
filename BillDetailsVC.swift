//
//  BillDetailsVC.swift
//  Denis Kebap
//
//  Created by Gaurav on 27/10/21.
//

import UIKit
class BillDetailsVC: UIViewController {

    
    @IBOutlet weak var tblView: UITableView!
    @IBOutlet weak var lblOrderDate: UILabel!
    @IBOutlet weak var lblPaymentType: UILabel!
    @IBOutlet weak var lblGrandTotal: UILabel!
    @IBOutlet weak var lblItemTotal: UILabel!
    @IBOutlet weak var lblTaxesAndCharges: UILabel!
    @IBOutlet weak var tblHeight: NSLayoutConstraint!
    var orderItems: [PastOrderDetailData]?
    var orderId = String()
    override func viewDidLoad() {
        super.viewDidLoad()
        getBillDetails()
    }
    
    override func viewDidLayoutSubviews() {
        super.updateViewConstraints()
        self.tblHeight.constant = self.tblView.intrinsicContentSize.height
    }

    @IBAction func btnBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
//MARK:- Table View Methods

extension BillDetailsVC:UITableViewDataSource,UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tblView.dequeueReusableCell(withIdentifier: "PastOrdersDetailTblCell", for: indexPath) as! PastOrdersDetailTblCell
        if let item = orderItems?[indexPath.row]{
            if let name = item.name{
                if let quantity = item.quantity{
                    cell.lblTitle .text = "\(name) × \(quantity)"
                    if let ingredients = item.ingredients{
                        if ingredients.count > 0{
                            cell.lblTitle .attributedText = self.setAttributedTwoTexts(str1: "\(name) × \(quantity)", str2: "\n\("Ingredients".localized()): \((ingredients.map{String($0)}).joined(separator: ","))", str1Color: .black, str2Color: .black)
                            if let addOns = item.addson_name{
                                if addOns.count > 0{
                                    cell.lblTitle .attributedText = self.setAttributedThreeTexts(str1: "\(name) × \(quantity)", str2: "\n\("Ingredients".localized()): \((ingredients.map{String($0)}).joined(separator: ","))", str3: "\n\("AddOns".localized()): \((addOns.map{String($0)}).joined(separator: ","))"  , str1Color: .black, str2Color: .black, str3Color: .black)

                                }
                            }
                        } else {
                            if let addOns = item.addson_name{
                                if addOns.count > 0{
                                    cell.lblTitle .attributedText = self.setAttributedTwoTexts(str1: "\(name) × \(quantity)", str2: "\n\("AddOns".localized()): \((addOns.map{String($0)}).joined(separator: ","))"  , str1Color: .black, str2Color: .black)

                                }
                            }
                        }
                    }
                }
                if let price = item.price{
                    cell.lblPrice.text = "Є \(price)"
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

extension BillDetailsVC{
    private func getBillDetails(){
        let params = ["transaction_id":self.orderId]
    RVApiManager.postAPI(Apis.pastOrderDetail, parameters: params as [String : Any], Vc: self, showLoader: true) { [weak self] (billDetail:PastOrderDetailModal) in
            if let success = billDetail.success{
                if success == 1{
                    if let items = billDetail.data{
                        self?.orderItems = items
                        self?.tblView.reloadData()
                    }
                    
                    if let orderDate = billDetail.payment_date{
                        self?.lblOrderDate.text = orderDate
                    }
                    
                    if let paymentType = billDetail.payment_method{
                        self?.lblPaymentType.text = paymentType
                    }
                    if let tax = billDetail.Tax{
                        self?.lblTaxesAndCharges.text = "€ \(tax)"
                    }
                    if let itemPrice = billDetail.TotalPrice{
                        self?.lblItemTotal.text = "Є \(itemPrice)"
                    }
                    if let grandTotal = billDetail.GrandTotal{
                        self?.lblGrandTotal.text = "Є \(grandTotal)"
                    }
                }else{

                    self?.tblHeight.constant = 0
                }
            }else{
                self?.tblHeight.constant = 0
                self?.showAlert(message: billDetail.message ?? "Something went wrong", strtitle: "")
            }
        }
    }
}
