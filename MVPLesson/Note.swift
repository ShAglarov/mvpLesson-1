//
//  Note.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 07.08.2023.
//

import Foundation

struct Note: Codable, Identifiable, Equatable {
    
    var id = UUID()
    var title: String
    var isComplete: Bool
    var date: Date
    var notes: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
