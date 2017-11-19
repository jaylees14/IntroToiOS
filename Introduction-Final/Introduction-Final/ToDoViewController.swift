//
//  ViewController.swift
//  Introduction-Final
//
//  Created by Jay Lees on 11/11/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import UIKit

class ToDoViewController: UITableViewController, NewItemDelegate {

    var items = [ToDoItem]()
    
    //MARK: - New Item Delegate
    func didAddNewItem(item: ToDoItem){
        items.append(item)
        tableView.reloadData() 
    }
    
    //MARK: - TableView Data Source and Delegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "toDoCell", for: indexPath)
        let label = cell.viewWithTag(101) as! UILabel
        label.text = items[indexPath.row].name
        
        if let priority = items[indexPath.row].priority {
            switch priority {
                case .Low: cell.backgroundColor = UIColor.green
                case .Medium: cell.backgroundColor = UIColor.orange
                case .High: cell.backgroundColor = UIColor.red
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentAccessory = tableView.cellForRow(at: indexPath)!.accessoryType
        if currentAccessory == .checkmark {
            tableView.cellForRow(at: indexPath)!.accessoryType = .none
        } else {
            tableView.cellForRow(at: indexPath)!.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    //MARK: - Preparation for Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewItem" {
            let destination = segue.destination as! NewItemViewController
            destination.delegate = self
        }
    }
}

