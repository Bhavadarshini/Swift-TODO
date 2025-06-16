//
//  ContentView.swift
//  TODOAPP
//
//  Created by Bhavadarshini on 16/06/25.
//

import SwiftUI

struct Task: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isImportant: Bool
    var dueDate: Date
    var category: String
    var isDone: Bool = false
}

struct ContentView: View {
    @State private var newTask = ""
    @State private var isImportant = false
    @State private var selectedCategory = "Select"
    @State private var dueDate = Date()
    @State private var tasks: [Task] = []
    @AppStorage("storedTasksData") private var storedTasksData: Data = Data()

    @State private var showEditAlert = false
    @State private var taskToEdit: Task?
    @State private var editedTitle: String = ""

    let categories = ["Personal", "Work", "Study", "Health", "Other"]
    let pinkColor = Color.pink.opacity(0.6)
    let pastel = Color(red: 1.0, green: 0.9, blue: 0.95)

    var body: some View {
        NavigationStack {
            ZStack {
                pastel.ignoresSafeArea()

                VStack(spacing: 16) {
                    headerView

                    Form {
                        addTaskSection
                        taskListSection
                    }
                    .scrollContentBackground(.hidden)
                }
                .padding([.top, .leading, .trailing], 16.0)
            }
            .onAppear(perform: loadTasks)
            .alert("Edit Task", isPresented: $showEditAlert, actions: {
                TextField("New Title", text: $editedTitle)
                Button("Save", action: saveEditedTask)
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("Update your task name")
            })
        }
    }

    var headerView: some View {
        VStack(spacing: 4) {
            Text("My Planner")
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(.black)

            Text("To-Do")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(pinkColor)
        }
    }

    var addTaskSection: some View {
        Section(header: Label("Add A Task", systemImage: "square.and.pencil.circle.fill")
            .foregroundColor(pinkColor)) {

            TextField("Task title", text: $newTask)
                .textFieldStyle(.roundedBorder)

            Toggle("Mark as Important", isOn: $isImportant)
                .toggleStyle(.switch)

            Picker("Choose Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) {
                    Text($0)
                }
            }

            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

            Button(action: addTask) {
                Label("Add Task", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .disabled(newTask.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding()
            .background(pinkColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    var taskListSection: some View {
        Section(header: Label("Task List", systemImage: "checklist")
            .foregroundColor(pinkColor)) {
            if tasks.isEmpty {
                Text("No tasks yet. Add a new one!")
                    .foregroundColor(.gray)
            } else {
                ForEach(tasks) { task in
                    TaskRow(
                        task: task,
                        toggle: { toggleTask(task) },
                        edit: {
                            taskToEdit = task
                            editedTitle = task.title
                            showEditAlert = true
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Edit") {
                            taskToEdit = task
                            editedTitle = task.title
                            showEditAlert = true
                        }
                        .tint(.orange)

                        Button(role: .destructive) {
                            deleteTaskByID(task)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    func addTask() {
        let trimmed = newTask.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let task = Task(title: trimmed,
                        isImportant: isImportant,
                        dueDate: dueDate,
                        category: selectedCategory)

        withAnimation(.spring()) {
            tasks.append(task)
        }

        resetInputs()
        saveTasks()
    }

    func resetInputs() {
        newTask = ""
        isImportant = false
        selectedCategory = "Personal"
        dueDate = Date()
    }

    func toggleTask(_ task: Task) {
        if let index = tasks.firstIndex(of: task) {
            tasks[index].isDone.toggle()
            saveTasks()
        }
    }

    func deleteTaskByID(_ task: Task) {
        if let index = tasks.firstIndex(of: task) {
            tasks.remove(at: index)
            saveTasks()
        }
    }

    func saveEditedTask() {
        if let index = tasks.firstIndex(where: { $0.id == taskToEdit?.id }) {
            tasks[index].title = editedTitle
            saveTasks()
        }
    }

    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            storedTasksData = encoded
        }
    }

    func loadTasks() {
        if let decoded = try? JSONDecoder().decode([Task].self, from: storedTasksData) {
            tasks = decoded
        }
    }
}

struct TaskRow: View {
    let task: Task
    let toggle: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isDone ? .green : .gray)
                .onTapGesture {
                    withAnimation(.spring()) {
                        toggle()
                    }
                }

            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.system(.headline, design: .rounded))
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .gray : .primary)

                HStack {
                    Text("📅 \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                    Text("📂 \(task.category)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            if task.isImportant {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}
