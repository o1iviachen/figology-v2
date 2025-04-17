//
//  FoodViewController.swift
//  figology-v2
//
//  Created by su huang on 2025-03-05.
//

import Foundation
import UIKit
import Firebase
import SwiftUI

class FoodViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var dateString: String? = nil
    let fibreCallManager = FibreCallManager()
    var fibreRequests: [URLRequest?] = []
    var fibreGoal: Int? = nil
    var tableData: [[Food]] = []
    let headerTitles = ["breakfast", "lunch", "dinner", "snacks"]
    let firebaseManager = FirebaseManager()
    var fibreIntake = 0.0
    var selectedFood: Food? = nil
    var selectedMeal: String? = nil
    let errorManager = ErrorManager()
    
    override func viewDidLoad() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: K.foodCellIdentifier, bundle: nil), forCellReuseIdentifier: K.foodCellIdentifier)
        progressBar.isHidden = true
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if dateString == nil {
            dateString = firebaseManager.formatDate()
        }
        
        firebaseManager.fetchUserDocument { document in
            self.firebaseManager.fetchFoods(dateString: self.dateString!, document: document) { data in
                self.tableData = data
                self.tableView.reloadData()
                print(self.tableData)
            }
            self.firebaseManager.fetchFibreIntake(dateString: self.dateString!, document: document) { intake in
                self.fibreIntake = Double(intake)
            }
            
            self.firebaseManager.fetchFibreGoal(document: document) { goal in
                self.fibreGoal = goal
                self.updateProgressUI()
            }
        }
        
        DispatchQueue.main.async {
            if CGFloat(62*self.tableData.count + 40) > CGFloat(UIScreen.main.bounds.size.height) {
                self.tableView.heightAnchor.constraint(equalToConstant: CGFloat(62*self.tableData.count + 40)).isActive = true
                self.tableView.reloadData()
            }
        }
    }
    
    func updateProgressUI() {
        if let setFibreGoal = fibreGoal {
            self.progressLabel.text = "you have consumed \(self.fibreIntake) g out of your \(setFibreGoal) g fibre goal! way to go."
            self.progressBar.progress = Float(self.fibreIntake/Double(setFibreGoal))
            self.progressBar.isHidden = false
        } else {
            self.progressLabel.text = "please set your fibre goal."
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.foodResultSegue {
            let destinationVC = segue.destination as! ResultViewController
            destinationVC.selectedFood = selectedFood!
            destinationVC.originalMeal = selectedMeal!
        }
    }
    
    
}

//MARK: - UITableViewDataSource
extension FoodViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.foodCellIdentifier, for: indexPath) as! FoodCell
        let cellFood = tableData[indexPath.section][indexPath.row]
        cell.foodNameLabel.text = cellFood.food
        let descriptionString = "\(cellFood.brandName), \(String(format: "%.1f", cellFood.multiplier*cellFood.selectedMeasure.measureMass)) g"
        cell.foodDescriptionLabel.text = descriptionString
        cell.fibreMassLabel.text = "\(String(format: "%.1f", cellFood.fibrePerGram*cellFood.multiplier*cellFood.selectedMeasure.measureMass)) g"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < headerTitles.count {
            return headerTitles[section]
        }
        return nil
    }
}

//MARK: - UITableViewDelegate
extension FoodViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exists = navigationController?.viewControllers.contains {
            $0 is UIHostingController<AnyView>
        } == true
        if !exists {
            selectedMeal = headerTitles[indexPath.section]
            selectedFood = tableData[indexPath.section][indexPath.row]
            performSegue(withIdentifier: K.foodResultSegue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // update firegoalui
        // deletes the first one?
        if editingStyle == .delete {
            selectedFood = tableData[indexPath.section][indexPath.row]
            firebaseManager.removeFood(food: selectedFood!, meal: headerTitles[indexPath.section], dateString: dateString!, fibreIntake: fibreIntake) { foodRemoved in
                if foodRemoved {
                    self.tableData[indexPath.section].remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    self.firebaseManager.fetchUserDocument { document in
                        self.firebaseManager.fetchFibreIntake(dateString: self.dateString!, document: document) { intake in
                            self.fibreIntake = intake
                            self.updateProgressUI()
                        }
                    }
                } else {
                    self.errorManager.showError(errorMessage: "could not remove food.", viewController: self)
                }
            }
            
            
        }
    }
}

//MARK: - UIViewControllerRepresentable
struct FoodView: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: FoodViewController, context: Context) {
        print("ok")
    }
    
    let date: Date
    
    func makeUIViewController(context: Context) -> FoodViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "FoodViewController") as! FoodViewController
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy_MM_dd"
        vc.dateString = dateFormatter.string(from: date)
        
        
        
        return vc
    }
    
}
