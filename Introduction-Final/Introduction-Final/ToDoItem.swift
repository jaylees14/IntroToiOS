//
//  ToDoItem.swift
//  Introduction-Final
//
//  Created by Jay Lees on 11/11/2017.
//  Copyright © 2017 Jay Lees. All rights reserved.

import Foundation

public class ToDoItem {
    var name: String
    var priority: ToDoPriority?
    
    init(name: String){
        self.name = name
    }
    
    func addPriority(rawValue: Int){
        let priority = ToDoPriority(rawValue: rawValue)
        self.priority = priority
    }
    
}

