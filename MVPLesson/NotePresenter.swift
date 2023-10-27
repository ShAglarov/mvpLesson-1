//
//  NotePresenter.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 08.08.2023.
//

import Foundation

// Описание методов, которые должны быть реализованы presenter'ом заметок
protocol NotePresenterProtocol {
    func loadAnUpdateDisplayData()
    func addNote(note: Note)
    func deleteNote(at index: Int)
    func numberOfNotes() -> Int
    func noteAt(at index: Int) -> Note
    func getImage(for isComplete: Bool) -> String
    func isToggleNote(for index: Int)
}

// Класс presenter'а, который управляет логикой работы с заметками
class NotePresenter: NotePresenterProtocol {
    
    // Слабая ссылка на интерфейс view, чтобы избежать утечек памяти
    private weak var view: NoteViewProtocol?
    // Сервис для работы с данными (например, для сохранения/загрузки заметок)
    private var dataRepository: ServiceRepositoryProtocol
    // Локальное хранение заметок для быстрого доступа
    private var notes: [Note] = []
    
    // Инициализация presenter'а
    required init(view: NoteViewProtocol, dataRepository: ServiceRepositoryProtocol) {
        self.view = view
        self.dataRepository = dataRepository
    }
    
    // Загрузка и обновление данных для отображения
    func loadAnUpdateDisplayData() {
        view?.showLoading() // Показать индикатор загрузки на view
        dataRepository.fetchNotes(url: dataRepository.noteURL, completion: { [weak self] result in
            switch result {
            case .success(let notes):
                // Сортировка заметок по дате
                self?.notes = notes.sorted(by: { $0.date > $1.date })
                self?.view?.reloadData() // Обновляем данные на view
                self?.view?.hideLoading() // Скрыть индикатор загрузки
            case .failure(let error):
                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
                self?.view?.hideLoading()
            }
        })
    }
    
//    // Загрузка и обновление данных для отображения
//    func loadAnUpdateDisplayData2() {
//        view?.showLoading() // Показать индикатор загрузки на view
//        dataRepository.fetchNotes(url: dataRepository.storyURL, completion: { [weak self] result in
//            switch result {
//            case .success(let notes):
//                // Сортировка заметок по дате
//                self?.notes = notes.sorted(by: { $0.date > $1.date })
//                self?.view?.reloadData() // Обновляем данные на view
//                self?.view?.hideLoading() // Скрыть индикатор загрузки
//            case .failure(let error):
//                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
//                self?.view?.hideLoading()
//            }
//        })
//    }
    
    // Добавить новую заметку
    func addNote(note: Note) {
        view?.showLoading()
        dataRepository.saveData(url: dataRepository.noteURL, note: note, completion: { [weak self] result in
            switch result {
            case .success:
                self?.notes.append(note)
                // Снова сортируем заметки
                self?.notes = self?.notes.sorted(by: { $0.date > $1.date }) ?? []
                self?.view?.didInsertRow(at: 0)
                self?.view?.hideLoading()
            case .failure(let error):
                self?.view?.hideLoading()
                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
            }
        })
    }
    
    // Удалить заметку по индексу
    func deleteNote(at index: Int) {
        let note = notes[index]
        dataRepository.removeData(url: dataRepository.noteURL, note: note, completion: { [weak self] result in
            switch result {
            case .success:
                self?.notes.remove(at: index)
                self?.view?.didDeleteRow(at: index)
            case .failure(let error):
                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
            }
        })
    }
    
    // Вернуть количество заметок
    func numberOfNotes() -> Int {
        return notes.count
    }
    
    // Получить заметку по индексу
    func noteAt(at index: Int) -> Note {
        return notes[index]
    }
    
    // Получить изображение на основе статуса завершения заметки
    func getImage(for isComplete: Bool) -> String {
        return isComplete ? "checkmark.circle.fill" : "circle"
    }
    
    // Изменить статус заметки на противоположный
    func isToggleNote(for index: Int) {
        guard index >= 0, index < notes.count else {
            // Проверка на правильность индекса, чтобы избежать ошибки Index out of range
            return
        }
        
        var note = notes[index]
        note.isComplete.toggle()
        
        dataRepository.updateNote(url: dataRepository.noteURL, note, completion: { [weak self] result in
            switch result {
            case .success:
                print("Заметка успешно обновилась")
                // Удалить заметку из массива только если она еще существует в нем
                if let indexOfNote = self?.notes.firstIndex(where: { $0.id == note.id }) {
                    self?.notes.remove(at: indexOfNote)
                    self?.view?.didDeleteRow(at: indexOfNote)
                }
                
            case .failure(let error):
                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
            }
        })
    }
}
