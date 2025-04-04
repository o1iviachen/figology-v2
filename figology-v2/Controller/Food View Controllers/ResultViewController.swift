//
//  ResultViewController.swift
//  figology-v2
//
//  Created by olivia chen on 2025-04-02.
//

import UIKit
import Firebase
import FLAnimatedImage

class ResultViewController: UIViewController, UITextFieldDelegate {
    var pickerOptions: [String] = []
    var measureQuantity = 0.0
    var fibreMass = 0.0
    var measureList: [Measure] = []
    var selectedFood: Food? = nil
    // Food(food: "hasbjda", fibrePerGram: 2.3, brandName: "sdf", measures: [Measure(measureExpression: "Sdf", measureMass: 213)], selectedMeasure: Measure(measureExpression: "Sdf", measureMass: 213), multiplier: 123)
    var measureDescriptionList: [String] = []
    let firebaseManager = FirebaseManager()
    let db = Firestore.firestore()
    var dateString: String? = nil
    var meal: String = "breakfast"
    
    @IBOutlet weak var foodLabel: UILabel!
    @IBOutlet weak var fibreLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var servingTextField: UITextField!
    @IBOutlet weak var servingMeasureButton: UIButton!
    @IBOutlet weak var mealButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if dateString == nil {
            dateString = firebaseManager.formatDate()
        }
        foodLabel.text = selectedFood!.food
        fibreLabel.text = "\(String(format: "%.1f", selectedFood!.fibrePerGram*selectedFood!.multiplier)) g"
        descriptionLabel.text = "\(selectedFood!.brandName), \(String(format: "%.1f", selectedFood!.selectedMeasure.measureMass*selectedFood!.multiplier))"
        servingTextField.delegate = self
        servingMeasureButton.setTitle(selectedFood!.selectedMeasure.measureExpression, for: .normal)
        mealButton.setTitle(meal, for: .normal)
        //        if UserDefaults.standard.integer(forKey: "proteinGoal") != 0 {
        //            DispatchQueue.main.async {
        //                self.progressLabel.text = "This is \(Int((Float(self.proteinAmount)/Float(UserDefaults.standard.integer(forKey: "proteinGoal"))*100)))% of your daily goal!"
        //                self.progressBar.progress = Float(self.proteinAmount)/Float(UserDefaults.standard.integer(forKey: "proteinGoal"))
        //            }
        //        } else {
        //            DispatchQueue.main.async {
        //                self.progressLabel.text = "Please set your protein goal."
        //                self.progressBar.isHidden = true
        //            }
        //        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    @objc func handleSwipe() {
        servingTextField.resignFirstResponder()
    }
    
    @objc func handleTap() {
        servingTextField.resignFirstResponder()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        // textfield triggers --> pass reference
        if textField.text != "" {
            return true
        } else {
            textField.text = "1.0"
            return false
        }
        
    } 
    
    @IBAction func mealButtonSelected(_ sender: UIButton) {
        pickerOptions = ["breakfast", "lunch", "dinner", "snacks"]
        performSegue(withIdentifier: K.resultPickerSegue, sender: self)
    }
    
    @IBAction func servingButtonSelected(_ sender: UIButton) {
        pickerOptions = selectedFood!.measures.map { $0.measureExpression }
        performSegue(withIdentifier: K.resultPickerSegue, sender: self)
        
    }
    
    
    @IBAction func addFood(_ sender: UIBarButtonItem) {
        if let lastViewController = navigationController!.viewControllers.last,
           lastViewController is FoodViewController {
            firebaseManager.removeFood(food: selectedFood!, meal: meal, dateString: dateString!)
            selectedFood!.multiplier = Double(servingTextField.text!)!
            firebaseManager.logFood(food: selectedFood!, meal: mealButton.currentTitle!, dateString: dateString!)
           } else {
            selectedFood!.multiplier = Double(servingTextField.text!)!
            firebaseManager.logFood(food: selectedFood!, meal: mealButton.currentTitle!, dateString: dateString!)
        }
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == K.resultPickerSegue {
                let destinationVC = segue.destination as! PickerViewController
                destinationVC.options = pickerOptions
                
            }
        }

}
