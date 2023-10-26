//
//  FileHandler.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 07.08.2023.
//

import Foundation

// Протокол, описывающий методы для работы с файлами
protocol FileHandlerProtocol {
    var notesURL: URL { get set }
    var storyNotesURL: URL { get set }
    
    typealias FetchCompletion = (Result<Data, Error>) -> Void
    typealias WriteCompletion = (Result<Void, Error>) -> Void
    typealias EncodeResult = Result<Data, Error>

    func fetchData(from url: URL, completion: @escaping FetchCompletion)
    func writeData(_ data: Data, to url: URL, completion: @escaping WriteCompletion)
    func encodeNotes(_ notes: [Note]) -> EncodeResult
}

class FileHandler: FileHandlerProtocol {
    
    // URL файла, в который будут сохраняться и из которого будут извлекаться данные
    var notesURL: URL
    var storyNotesURL: URL
    
    // Инициализатор создаёт URL к файлу и, если файл не существует, создаёт его
    init() {
        // Определение директории документов пользователя
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        notesURL = documentsDirectory.appendingPathComponent("todo").appendingPathExtension("plist")
        storyNotesURL = documentsDirectory.appendingPathComponent("storyNotes").appendingPathExtension("plist")
        
        // Проверка существования файлов по указанным URL. Если файл не существует, он создаётся.
        [notesURL, storyNotesURL].forEach {
            if !FileManager.default.fileExists(atPath: $0.path) {
                FileManager.default.createFile(atPath: $0.path, contents: nil)
            }
        }
    }
    
    // Метод для извлечения данных из файла
    func fetchData(from url: URL, completion: @escaping FetchCompletion) {
        do {
            let data = try Data(contentsOf: url)
            completion(.success(data))
        } catch {
            completion(.failure(error))
        }
    }
    
    // Метод для записи данных в файл
    func writeData(_ data: Data, to url: URL, completion: @escaping WriteCompletion) {
        do {
            try data.write(to: url)
            completion(.success(()))
        } catch {
            print("При записи данных произошла ошибка: \(error)")
            completion(.failure(error))
        }
    }
    
    // Метод для кодирования массива заметок в формат Data
    func encodeNotes(_ notes: [Note]) -> EncodeResult {
        let propertyListEncoder = PropertyListEncoder()
        // Пробуем закодировать заметки
        if let encodedList = try? propertyListEncoder.encode(notes) {
            return .success(encodedList)
        } else {
            // В случае ошибки возвращаем ошибку с сообщением
            return .failure(NoteServiceError.fileWriteError("Не удалось закодировать массив заметок в данные"))
        }
    }
}
