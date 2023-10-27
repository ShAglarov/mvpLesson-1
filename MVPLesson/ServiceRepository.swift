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
    
    var noteURL: URL { get }
    var storyURL: URL { get }
    
    func fetchNotes(url: URL, completion: @escaping FetchNotesCompletion)
    func saveData(url: URL, note: Note, completion: @escaping OperationCompletion)
    func removeData(url: URL, note: Note, completion: @escaping OperationCompletion)
    func updateNote(url: URL, _ noteToUpdate: Note, completion: @escaping OperationCompletion)
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
    // вместо создания пустых данных нужно загружать из файла
    private var notesCache = [Note]()             // Кэш для заметок, чтобы не обращаться к файлу каждый раз
    private var storyCache = [Note]()             // Кэш для заметок, чтобы не обращаться к файлу каждый раз
   
    var noteURL: URL {
        fileHandler.notesURL
    }
    var storyURL: URL {
        fileHandler.storyNotesURL
    }
    
    // Инициализатор принимает обработчик файлов
    init(fileHandler: FileHandlerProtocol) {
        self.fileHandler = fileHandler
    }
    
    // Получение всех заметок
    func fetchNotes(url: URL, completion: @escaping FetchNotesCompletion) {
        // Возвращаем данные из кэша, если он не пуст
        !notesCache.isEmpty ? completion(.success(notesCache)) : nil
        
        // Запрос данных из файла
        fileHandler.fetch(from: url, completion: { result in
            switch result {
            case .success(let dataContent):
                // Если файл пустой, возвращаем пустой массив
                guard !dataContent.isEmpty else {
                    print("Файл пуст")
                    completion(.success([]))
                    return
                }
                // Декодируем данные из файла для notes
                let propertyListDecoder = PropertyListDecoder()
                guard let notes = try? propertyListDecoder.decode([Note].self, from: dataContent) else {
                    completion(.failure(NoteServiceError.fileReadError("Не удалось декодировать данные в массив заметок")))
                    return
                }
                // Обновляем кэш для notes и возвращаем результат
                self.notesCache = notes

                // Теперь декодируем данные из файла для story
                // Здесь важно, чтобы тип данных для story был правильным
                // После декодирования обновляем кэш для story
                if url == self.storyURL {
                    guard let story = try? propertyListDecoder.decode([Note].self, from: dataContent) else {
                        completion(.failure(NoteServiceError.fileReadError("Не удалось декодировать данные в массив заметок для story")))
                        return
                    }
                    self.storyCache = story
                }
                
                completion(.success(notes))
                
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    // Сохранение заметки
    func saveData(url: URL, note: Note, completion: @escaping OperationCompletion) {
        // Добавляем новую заметку в кэш
        notesCache.append(note)
        
        // Кодируем все заметки и сохраняем в файл
        switch fileHandler.encodeNotes(notesCache) {
        case .success(let data):
            fileHandler.write(from: url, data, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    // Обновление заметки
    func updateNote(url: URL, _ noteToUpdate: Note, completion: @escaping OperationCompletion) {
        // Проверяем наличие заметки в кэше
        guard let index = notesCache.firstIndex(where: { $0 == noteToUpdate }) else {
            completion(.failure(NoteServiceError.noteNotFound("Не удалось найти заметку")))
            return
        }
        
        // Обновляем заметку в кэше
        if url == fileHandler.notesURL {
            storyCache.append(noteToUpdate)  // Добавляем в storyCache
            notesCache.remove(at: index)     // Удаляем из notesCache
        } else {
            notesCache.append(noteToUpdate)
            storyCache.remove(at: index)
        }
        
        // Кодируем заметки из notesCache и сохраняем в файл
        switch fileHandler.encodeNotes(notesCache) {
        case .success(let data):
            fileHandler.write(from: url, data, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
        
        // Кодируем и сохраняем заметку в storyURL
        switch fileHandler.encodeNotes(storyCache) {
        case .success(let data):
            fileHandler.write(from: storyURL, data, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    // Удаление заметки
    func removeData(url: URL, note: Note, completion: @escaping OperationCompletion) {
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
            fileHandler.write(from: url, data, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
