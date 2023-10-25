//
//  AppView.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 08.08.2023.
//

import Foundation
import UIKit

class AppView {
    
    func tableView(style: UITableView.Style) -> UITableView {
        let table = UITableView(frame: .zero, style: style)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return table
    }

}

