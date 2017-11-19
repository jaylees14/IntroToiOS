//
//  NewItemViewController.swift
//  Introduction-Final
//
//  Created by Jay Lees on 11/11/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.
//

import UIKit


class NewItemViewController: UIViewController {

    @IBOutlet weak var toDoTextField: UITextField!
    @IBOutlet weak var prioritySegment: UISegmentedControl!
    
    var delegate: NewItemDelegate!
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        guard toDoTextField.text != "" else { return }
        
        let newItem = ToDoItem(name: toDoTextField.text!)
        newItem.addPriority(rawValue: prioritySegment.selectedSegmentIndex)
        
        delegate.didAddNewItem(item: newItem)
        navigationController?.popViewController(animated: true)
    }
}
