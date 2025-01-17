//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by 谢乾坤 on 4/18/16.
//  Copyright © 2016 QiankunXie. All rights reserved.
//

import UIKit
class CategoryPickerViewController: UITableViewController {
    var selectedCategoryName = ""
    let categories = [ "No Category",
                       "Apple Store",
                       "Bar",
                       "Bookstore",
                       "Club",
                       "Grocery Store",
                       "Historic Building",
                       "House",
                       "Icecream Vendor",
                       "Landmark",
                       "Park"]
    var selectedIndexPath = NSIndexPath()
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<categories.count {
            if categories[i] == selectedCategoryName {
                selectedIndexPath = NSIndexPath(forRow: i, inSection: 0)
                break
            }
        }
    }
    // MARK: - UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(
            "Cell", forIndexPath: indexPath)
        let categoryName = categories[indexPath.row]
        cell.textLabel!.text = categoryName
        if categoryName == selectedCategoryName {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        return cell
    }
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != selectedIndexPath.row {
            if let newCell = tableView.cellForRowAtIndexPath(indexPath) {
                newCell.accessoryType = .Checkmark
            }
            if let oldCell = tableView.cellForRowAtIndexPath( selectedIndexPath) {
                oldCell.accessoryType = .None
            }
            selectedIndexPath = indexPath
            // May not work
//            selectedCategoryName = categories[indexPath.row]
//            print(selectedCategoryName)

        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        print("in segue")
//        print(selectedCategoryName)
        if segue.identifier == "PickedCategory" {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPathForCell(cell) {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }
    
    
}











