//
//  NoteService.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 08.08.2023.
//

import Foundation

// Протокол, описывающий методы для работы с заметками в репозитории
protocol ServiceRepositoryProtocol {
    typealias FetchNotesCompletion = (Result<[Note], Error>) -> Void
    typealias OperationCompletion = (Result<Void, Error>) -> Void
    
    func fetchNotes(completion: @escaping FetchNotesCompletion)
    func saveData(note: Note, completion: @escaping OperationCompletion)
    func removeData(note: Note, completion: @escaping OperationCompletion)
    func updateNote(_ noteToUpdate: Note, completion: @escaping OperationCompletion)
}

// Определенные ошибки для обработки ошибок сервиса
enum NoteServiceError: Error {
    case fileReadError(String)
    case fileWriteError(String)
    case noteNotFound(String)
}

// Класс репозитория для работы с заметками
final class ServiceRepository: ServiceRepositoryProtocol {
    
    private let fileHandler: FileHandlerProtocol  // Обработчик файлов для чтения и записи заметок
    private var notesCache = [Note]()             // Кэш для заметок, чтобы не обращаться к файлу каждый раз
    private var storyCache = [Note]()             // Кэш для заметок, чтобы не обращаться к файлу каждый раз
    
    // Инициализатор принимает обработчик файлов
    init(fileHandler: FileHandlerProtocol) {
        self.fileHandler = fileHandler
    }
    
    // Получение всех заметок
    func fetchNotes(completion: @escaping FetchNotesCompletion) {
        // Возвращаем данные из кэша, если он не пуст
        !notesCache.isEmpty ? completion(.success(notesCache)) : nil
        
        // Запрос данных из файла
        fileHandler.fetchData(from: fileHandler.notesURL, completion: { result in
            switch result {
            case .success(let dataContent):
                // Если файл пустой, возвращаем пустой массив
                guard !dataContent.isEmpty else {
                    print("Файл пуст")
                    completion(.success([]))
                    return
                }
                // Декодируем данные из файла
                let propertyListDecoder = PropertyListDecoder()
                guard let notes = try? propertyListDecoder.decode([Note].self, from: dataContent) else {
                    completion(.failure(NoteServiceError.fileReadError("Не удалось декодировать данные в массив заметок")))
                    return
                }
                // Обновляем кэш и возвращаем результат
                self.notesCache = notes
                completion(.success(notes))
                
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    // Сохранение заметки
    func saveData(note: Note, completion: @escaping OperationCompletion) {
        // Добавляем новую заметку в кэш
        notesCache.append(note)
        
        // Кодируем все заметки и сохраняем в файл
        switch fileHandler.encodeNotes(notesCache) {
        case .success(let data):
            fileHandler.writeData(data, to: fileHandler.notesURL, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    // Обновление заметки
    func updateNote(_ noteToUpdate: Note, completion: @escaping OperationCompletion) {
        // Проверяем наличие заметки в кэше
        guard let index = notesCache.firstIndex(where: { $0 == noteToUpdate }) else {
            completion(.failure(NoteServiceError.noteNotFound("Не удалось найти заметку")))
            return
        }
        
        // Обновляем заметку в кэше
        if noteToUpdate.isComplete {
            notesCache[index] = noteToUpdate
            storyCache.append(notesCache[index])  // Добавляем в storyCache
            notesCache.remove(at: index)          // Удаляем из notesCache
        }
        
        // Кодируем заметки из notesCache и сохраняем в файл
        switch fileHandler.encodeNotes(notesCache) {
        case .success(let data):
            fileHandler.writeData(data, to: fileHandler.notesURL, completion: completion)
            fileHandler.writeData(data, to: fileHandler.storyNotesURL, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    // Удаление заметки
    func removeData(note: Note, completion: @escaping OperationCompletion) {
        // Проверяем наличие заметки в кэше
        guard let index = notesCache.firstIndex(where: { $0 == note }) else {
            completion(.failure(NoteServiceError.noteNotFound("Не удалось найти заметку для удаления")))
            return
        }
        // Удаляем заметку из кэша
        notesCache.remove(at: index)
        
        // Кодируем все оставшиеся заметки и сохраняем в файл
        switch fileHandler.encodeNotes(notesCache) {
        case .success(let data):
            fileHandler.writeData(data, to: fileHandler.notesURL, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
