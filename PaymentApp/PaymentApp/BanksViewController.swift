//
//  BanksViewController.swift
//  PaymentApp
//
//  Created by Agustín Errecalde on 13/12/2019.
//  Copyright © 2019 nistsugaDev.paymentApp. All rights reserved.
//

import UIKit

class BanksViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    enum CardState {
        case expanded
        case colapsed
    }
    
    var amount: Int?
    var amountString : String?
    var paymentMethod: PaymentMethodModel?
    var carIssuersArray: [CardIssuersModel]?
    let picker = UIPickerView()
    let segmentedControl = UISegmentedControl()
    @IBOutlet weak var bankLabel: UILabel!
    
    var cardViewDetailController: CardDetailViewController!
    var visualEfectView: UIVisualEffectView!
    
    let cardHeight: CGFloat = 300
    let cardHandleAreaHeight: CGFloat = 65
    
    var cardVisible = false
    var nextState: CardState {
        return cardVisible ? .colapsed : .expanded
    }
    
    var runningAnimation = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
        bankLabel.text = paymentMethod?.name
        let parameters = ["public_key":PUBLIC_KEY_API,
                        "payment_method_id": paymentMethod?.id ?? ""]
        let service = CardIssuersService()
        service.getCardIssuers(parameters: parameters) { (array) in
            self.carIssuersArray = array
            if array.count > 1 {
                self.configurePickerView()
            }
        }
    }
    
    func configurePickerView(){
        self.picker.delegate = self
        self.picker.dataSource = self
        
        picker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker)
        picker.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        picker.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return carIssuersArray?.count ?? 2
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if carIssuersArray?.count == 0 {
            return paymentMethod?.name
        } else {
            if let bankName = carIssuersArray?[row].name{
                return bankName
            } else {
                return "Not Bank support"
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if carIssuersArray?.count == 0 {
            self.view.endEditing(true)
            bankLabel.text = paymentMethod?.name
        } else {
            if let bankName = carIssuersArray?[row].name{
                bankLabel.text = bankName
            } else {
                bankLabel.text = paymentMethod?.name
            }
        }
    }
    
    func setupCard(){
        visualEfectView = UIVisualEffectView()
        visualEfectView.frame = self.view.frame
        self.view.addSubview(visualEfectView)
        
        cardViewDetailController = CardDetailViewController(nibName: "CardDetailViewController", bundle: nil)
        self.addChild(cardViewDetailController)
        self.view.addSubview(cardViewDetailController.view)
        
        cardViewDetailController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        cardViewDetailController.view.clipsToBounds = true
        cardViewDetailController.amountLabel.text = self.amountString
        cardViewDetailController.methodLabel.text = self.paymentMethod?.name
        cardViewDetailController.rowImage.image = #imageLiteral(resourceName: "upButton")
        
        cardViewDetailController.methodView.layer.cornerRadius = 60
        cardViewDetailController.methodView.layer.shadowOpacity = 0.8
        cardViewDetailController.methodView.layer.shadowOffset = .zero
        cardViewDetailController.methodView.layer.shadowRadius = 10
        cardViewDetailController.methodView.layer.masksToBounds = false
        
        cardViewDetailController.backRowImage.layer.cornerRadius = 15
        cardViewDetailController.backRowImage.layer.shadowOpacity = 0.8
        cardViewDetailController.backRowImage.layer.shadowOffset = .zero
        cardViewDetailController.backRowImage.layer.shadowRadius = 5
        cardViewDetailController.backRowImage.layer.masksToBounds = false
        
        cardViewDetailController.amountView.layer.cornerRadius = 60
        cardViewDetailController.amountView.layer.shadowOpacity = 0.8
        cardViewDetailController.amountView.layer.shadowOffset = .zero
        cardViewDetailController.amountView.layer.shadowRadius = 10
        cardViewDetailController.amountView.layer.masksToBounds = false
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BanksViewController.handleCardTap(recognizer:)))
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(BanksViewController.handleCardPan(recognizer:)))
        
        cardViewDetailController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewDetailController.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    func handleCardTap(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
            case .ended:
                animationTransitionIsNeeded(state: nextState, duration: 0.9)
            default:
                break
            }
    }
    
    @objc
    func handleCardPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.cardViewDetailController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    func animationTransitionIsNeeded(state: CardState, duration: TimeInterval){
        if runningAnimation.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state{
                case .expanded :
                    self.cardViewDetailController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                    self.cardViewDetailController.rowImage.image = #imageLiteral(resourceName: "downButton")
                case .colapsed :
                    self.cardViewDetailController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                    self.cardViewDetailController.rowImage.image = #imageLiteral(resourceName: "upButton")

                }
            }
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimation.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimation.append(frameAnimator)
            
            
            let cornerRadiusAnimator  = UIViewPropertyAnimator(duration: duration, curve: .linear){
                switch state{
                case .expanded :
                    self.cardViewDetailController.view.layer.cornerRadius = 12
                case .colapsed :
                    self.cardViewDetailController.view.layer.cornerRadius = 0

                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimation.append(cornerRadiusAnimator)
            
            let blurAnimation = UIViewPropertyAnimator(duration: duration, dampingRatio: 1){
                switch state{
                case .expanded :
                    self.visualEfectView.effect = UIBlurEffect(style: .dark)
                case .colapsed :
                    self.visualEfectView.effect = nil
                }
            }
            blurAnimation.startAnimation()
            runningAnimation.append(blurAnimation)
        }
        
        
    }
    
    func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        if runningAnimation.isEmpty{
            animationTransitionIsNeeded(state: state, duration: duration)
        }
        for animator in runningAnimation {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimation {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition() {
        for animator in runningAnimation {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
