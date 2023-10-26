//
//  ViewController.swift
//  MVPLesson
//
//  Created by Shamil Aglarov on 07.08.2023.
//

import UIKit

// MARK: - Протоколы

// Протокол, отвечающий за реакцию на создание новой заметки.
protocol AddingNotesProtocol {
    func createButtonTapped()
}

// Протокол для отображения предупреждений с текстовыми полями.
protocol AlertViewProtocol  {
    /// Функция для показа предупреждения с двумя текстовыми полями.
    func presentAlertWithTextFields(
        title: String,
        message: String,
        firstTextFieldPlaceholder: String,
        secondTextFieldPlaceholder: String,
        addActionTitle: String,
        cancelActionTitle: String,
        addActionCompletion: @escaping (String, String) -> Void
    )
}

// Протокол, описывающий интерфейс отображения заметок.
protocol NoteViewProtocol: AnyObject {
    func showError(title: String, message: String)
    func showLoading()
    func hideLoading()
    func reloadData()
    func reloadRow(at index: Int)
    func didInsertRow(at index: Int)
    func didDeleteRow(at index: Int)
}

// MARK: - NoteViewController

/// Основной класс контроллера для управления заметками.
class NoteViewController: UIViewController {
    
    // MARK: - Приватные свойства
    
    // Основное представление для работы с заметками.
    private let appView = AppView()
    
    // Презентер, обеспечивающий бизнес-логику.
    private var notePresenter: NotePresenterProtocol!
    private var storyPresenter: StoryPresenterProtocol!
    
    // Таблица для отображения списка заметок.
    private var tableView: UITableView!
    
    // MARK: - Жизненный цикл контроллера
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Настройка пользовательского интерфейса.
        setupUI()
        setupPresenter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Загрузка и обновление данных для отображения.
        notePresenter.loadAnUpdateDisplayData()
        reloadData()
    }
    
    // MARK: - Настройка пользовательского интерфейса
    
    private func setupUI() {
        setupTableView()
        setupNavigationBar()
    }
    
    private func setupTableView() {
        tableView = appView.tableView(style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        setupConfigureConstraints()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Напоминания"
        
        // Кнопка добавления новой заметки.
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .add,
                            target: self,
                            action: #selector(addNote))
    }
    
    private func setupPresenter() {
        // Инициализация обработчика файлов.
        let fileHandler: FileHandlerProtocol = FileHandler()
        
        // Инициализация презентера с вью и репозиторием.
        notePresenter = NotePresenter(view: self, dataRepository: ServiceRepository(fileHandler: fileHandler))
        storyPresenter = StoryPresenter(view: self, dataRepository: ServiceRepository(fileHandler: fileHandler))
    }
    
    // MARK: - Действия пользователя
    
    /// Действие при нажатии на кнопку добавления новой заметки.
    @objc func addNote() {
        showLoading()
        createButtonTapped()
    }
    
    /// Действие при нажатии на кнопку в ячейке (переключение состояния заметки).
    @objc func buttonAction(sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint.zero, to: self.tableView)
        guard let indexPath = self.tableView.indexPathForRow(at: buttonPosition) else { return }
        notePresenter.isToggleNote(for: indexPath.row)
    }
    
    // MARK: - Конфигурация элементов интерфейса
    
    private func setupConfigureConstraints() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}

// MARK: - Реализация NoteViewProtocol для управления отображением UI

extension NoteViewController: NoteViewProtocol {
    
    // Отображение ошибки с помощью всплывающего окна
    func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "Закрыть", style: .default)
        alertController.addAction(alertAction)
        self.present(alertController, animated: true)
    }
    
    // Отображение индикатора загрузки на панели навигации
    func showLoading() {
        let activityIndicatovView = UIActivityIndicatorView(style: .medium)
        activityIndicatovView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicatovView)
    }
    
    // Скрытие индикатора загрузки и возвращение кнопки добавления на панель навигации
    func hideLoading() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                 target: self,
                                                                 action: #selector(addNote))
    }
    
    // Вставка строки в таблицу при добавлении новой заметки
    func didInsertRow(at index: Int) {
        let indexPathToAdd = IndexPath(row: index, section: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPathToAdd], with: .automatic)
        tableView.endUpdates()
    }
    
    // Удаление строки из таблицы
    func didDeleteRow(at index: Int) {
        let indexPathToDelete = IndexPath(row: index, section: 0)
        tableView.beginUpdates()
        tableView.deleteRows(at: [indexPathToDelete], with: .automatic)
        tableView.endUpdates()
    }
    
    // Обновление строки в таблице
    func reloadRow(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    // Обновление всей таблицы
    func reloadData() {
        tableView.reloadData()
    }
}

extension NoteViewController: StoryViewProtocol {
    
}

// MARK: - Реализация UITableViewDataSource для отображения данных заметок в таблице

extension NoteViewController: UITableViewDataSource {
    
    // Возвращаем количество заметок для отображения
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notePresenter.numberOfNotes()
    }
    
    // Заполняем ячейку таблицы данными из модели
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let note = notePresenter.noteAt(at: indexPath.row)
        
        // Создание и настройка кнопки для отображения статуса заметки
        let iconButton = UIButton(type: .custom)
        let image = notePresenter.getImage(for: note.isComplete)
        iconButton.setImage(UIImage(systemName: image), for: .normal)
        // Важно! Отключаем автоматические constraints
        iconButton.translatesAutoresizingMaskIntoConstraints = false
        iconButton.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        iconButton.tag = indexPath.row
        cell.contentView.addSubview(iconButton)
        
        // Добавляем constraints
        NSLayoutConstraint.activate([
            iconButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 10),
            iconButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            iconButton.widthAnchor.constraint(equalToConstant: 24),
            iconButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Настройка отступов для текста
        //Определяем уровень отступа контента ячейки
        cell.indentationLevel = 2
        //Устанавливаем ширину отступа для каждого уровня отступа
        cell.indentationWidth = 15
        
        // Заполнение текстовых полей ячейки данными из модели
        cell.textLabel?.text = note.title
        cell.detailTextLabel?.text = note.notes
        
        return cell
    }
}

// MARK: - Реализация UITableViewDelegate для обработки действий пользователя с таблицей

extension NoteViewController: UITableViewDelegate {
    
    // Удаление заметки при свайпе ячейки
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            notePresenter.deleteNote(at: indexPath.row)
            notePresenter.loadAnUpdateDisplayData()
        }
    }
}

// MARK: - Реализация AddingNotesProtocol для добавления новых заметок

extension NoteViewController: AddingNotesProtocol {
    
    // Метод вызывается при нажатии кнопки добавления новой заметки
    func createButtonTapped() {
        presentAlertWithTextFields(
            title: "Добавить новую заметку",
            message: "",
            firstTextFieldPlaceholder: "Введите заголовок заметки",
            secondTextFieldPlaceholder: "Введите текст заметки",
            addActionTitle: "Добавить",
            cancelActionTitle: "Закрыть") { [weak self] title, note in
            let newNote = Note(title: title, isComplete: false, date: Date(), notes: note)
            self?.notePresenter.addNote(note: newNote)
        }
    }
}

// MARK: - Реализация AlertViewProtocol для отображения всплывающих окон

extension NoteViewController: AlertViewProtocol {
    // Метод для отображения всплывающего окна с двумя текстовыми полями
    typealias DoubleString = (String, String) -> Void
    
    func presentAlertWithTextFields(
        title: String,
        message: String,
        firstTextFieldPlaceholder: String,
        secondTextFieldPlaceholder: String,
        addActionTitle: String,
        cancelActionTitle: String,
        addActionCompletion: @escaping DoubleString) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Добавление текстовых полей
        alertController.addTextField { textField in
            textField.placeholder = firstTextFieldPlaceholder
        }
        alertController.addTextField { textField in
            textField.placeholder = secondTextFieldPlaceholder
        }
        
        // Добавление кнопок и обработка их нажатия
        let addAction = UIAlertAction(title: addActionTitle, style: .default) { [weak self, weak alertController] _ in
            guard let titleField = alertController?.textFields?[0],
                  let noteField = alertController?.textFields?[1],
                  let titleText = titleField.text, !titleText.isEmpty,
                  let noteText = noteField.text, !noteText.isEmpty else {
                self?.showError(title: "Ошибка", message: "Пожалуйста, заполните все поля.")
                self?.hideLoading()
                return
            }
            
            addActionCompletion(titleText, noteText)
        }
        
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel) { _ in
            self.hideLoading() // когда пользователь нажмет "Закрыть"
        }
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
}
