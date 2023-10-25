//
//  FileHandler.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 07.08.2023.
//

import Foundation

// Протокол, описывающий методы для работы с файлами
protocol FileHandlerProtocol {
    typealias FetchCompletion = (Result<Data, Error>) -> Void
    typealias WriteCompletion = (Result<Void, Error>) -> Void
    typealias EncodeResult = Result<Data, Error>

    func fetch(completion: @escaping FetchCompletion)
    func write(_ data: Data, completion: @escaping WriteCompletion)
    func encodeNotes(_ notes: [Note]) -> EncodeResult
}

class FileHandler: FileHandlerProtocol {
    
    // URL файла, в который будут сохраняться и из которого будут извлекаться данные
    private var url: URL
    
    // Инициализатор создаёт URL к файлу и, если файл не существует, создаёт его
    init() {
        // Определение директории документов пользователя
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url = documentsDirectory.appendingPathComponent("todo").appendingPathExtension("plist")
        
        // Проверка существования файла по указанному URL. Если файл не существует, он создаётся.
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
    }
    
    // Метод для извлечения данных из файла
    func fetch(completion: @escaping FetchCompletion) {
        do {
            let data = try Data(contentsOf: url)
            completion(.success(data))
        } catch {
            // В случае ошибки при извлечении данных возвращается ошибка
            completion(.failure(error))
        }
    }
    
    // Метод для записи данных в файл
    func write(_ data: Data, completion: @escaping WriteCompletion) {
        do {
            try data.write(to: url)
            completion(.success(()))
        } catch {
            // В случае ошибки при записи данных выводится сообщение об ошибке и возвращается ошибка
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
