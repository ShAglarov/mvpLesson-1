//
//  StoryPresenter.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 26.10.2023.
//
// Описание методов, которые должны быть реализованы presenter'ом заметок
// Описание методов, которые должны быть реализованы presenter'ом заметок
protocol StoryPresenterProtocol {
    func loadAnUpdateDisplayData()
    func addNote(note: Note)
    func deleteNote(at index: Int)
    func numberOfNotes() -> Int
    func noteAt(at index: Int) -> Note
    func getImage(for isComplete: Bool) -> String
    func isToggleNote(for index: Int)
}

// Класс presenter'а, который управляет логикой работы с заметками
class StoryPresenter: StoryPresenterProtocol {
    
    // Слабая ссылка на интерфейс view, чтобы избежать утечек памяти
    private weak var view: StoryViewProtocol?
    // Сервис для работы с данными (например, для сохранения/загрузки заметок)
    private var dataRepository: ServiceRepositoryProtocol
    // Локальное хранение заметок для быстрого доступа
    private var stories: [Note] = []
    
    // Инициализация presenter'а
    required init(view: StoryViewProtocol, dataRepository: ServiceRepositoryProtocol) {
        self.view = view
        self.dataRepository = dataRepository
    }
    
    // Загрузка и обновление данных для отображения
    func loadAnUpdateDisplayData() {
        view?.showLoading() // Показать индикатор загрузки на view
        dataRepository.fetchNotes(url: dataRepository.storyURL, completion: { [weak self] result in
            switch result {
            case .success(let notes):
                // Сортировка заметок по дате
                self?.stories = notes.sorted(by: { $0.date > $1.date })
                self?.view?.reloadData() // Обновляем данные на view
                self?.view?.hideLoading() // Скрыть индикатор загрузки
            case .failure(let error):
                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
                self?.view?.hideLoading()
            }
        })
    }
    
    // Добавить новую заметку
    func addNote(note: Note) {
        view?.showLoading()
        dataRepository.saveData(url: dataRepository.storyURL, note: note, completion: { [weak self] result in
            switch result {
            case .success:
                self?.stories.append(note)
                // Снова сортируем заметки
                self?.stories = self?.stories.sorted(by: { $0.date > $1.date }) ?? []
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
        let note = stories[index]
        dataRepository.removeData(url: dataRepository.noteURL, note: note, completion: { [weak self] result in
            switch result {
            case .success:
                self?.stories.remove(at: index)
                self?.view?.didDeleteRow(at: index)
            case .failure(let error):
                self?.view?.showError(title: "Ошибка", message: error.localizedDescription)
            }
        })
    }
    
    // Вернуть количество заметок
    func numberOfNotes() -> Int {
        return stories.count
    }
    
    // Получить заметку по индексу
    func noteAt(at index: Int) -> Note {
        return stories[index]
    }
    
    // Получить изображение на основе статуса завершения заметки
    func getImage(for isComplete: Bool) -> String {
        return isComplete ? "checkmark.circle.fill" : "circle"
    }
    
    // Изменить статус заметки на противоположный
    func isToggleNote(for index: Int) {
        var note = stories[index]
        note.isComplete.toggle()

        dataRepository.updateNote(url: dataRepository.storyURL, note, completion: { result in
            switch result {
            case .success:
                print("Заметка успешно обновилась")
                self.stories.remove(at: index)
                self.view?.didDeleteRow(at: index)
                
                // Добавляем эту же заметку в другую таблицу/базу данных
                self.dataRepository.saveData(url: self.dataRepository.noteURL, note: note, completion: { result in
                    switch result {
                    case .success:
                        print("Заметка успешно добавлена в другую таблицу")
                    case .failure(let error):
                        self.view?.showError(title: "Ошибка", message: "Не удалось добавить заметку в другую таблицу: \(error.localizedDescription)")
                    }
                })
                
            case .failure(let error):
                self.view?.showError(title: "Ошибка4", message: error.localizedDescription)
            }
        })
    }
}
