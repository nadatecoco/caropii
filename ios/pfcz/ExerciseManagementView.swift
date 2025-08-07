import SwiftUI
import UniformTypeIdentifiers

struct ExerciseManagementView: View {
    @State private var exercises: [String] = []
    @State private var showingAddExercise = false
    @State private var newExerciseName = ""
    @State private var editingExercise: String? = nil
    @State private var editedName = ""
    @State private var draggedExercise: String?
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    // デフォルトの種目
    let defaultExercises = [
        "ベンチプレス",
        "スクワット",
        "デッドリフト",
        "ショルダープレス",
        "ラットプルダウン",
        "レッグプレス",
        "ダンベルカール",
        "トライセプスエクステンション"
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(exercises, id: \.self) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            isEditing: editingExercise == exercise,
                            editedName: $editedName,
                            onEdit: { startEditing(exercise: exercise) },
                            onSave: { saveEditedExercise(oldName: exercise) },
                            onCancel: { 
                                editingExercise = nil
                                editedName = ""
                            },
                            onDelete: { deleteExercise(exercise) }
                        )
                        .opacity(draggedExercise == exercise ? 0.5 : 1)
                        .scaleEffect(draggedExercise == exercise && isDragging ? 1.05 : 1.0)
                        .offset(draggedExercise == exercise ? dragOffset : .zero)
                        .zIndex(draggedExercise == exercise ? 1 : 0)
                        .onDrag {
                            self.draggedExercise = exercise
                            return NSItemProvider(object: exercise as NSString)
                        } preview: {
                            // ドラッグ中のプレビュー
                            Text(exercise)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .onDrop(of: [UTType.text], delegate: ExerciseDropDelegate(
                            item: exercise,
                            exercises: $exercises,
                            draggedItem: $draggedExercise
                        ))
                        .animation(.spring(), value: exercises)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("筋トレ種目の管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddExercise = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(exercises: $exercises, newExerciseName: $newExerciseName)
        }
        .onAppear {
            loadExercises()
        }
        .onDisappear {
            saveExercises()
        }
    }
    
    // 種目を削除
    private func deleteExercise(_ exercise: String) {
        exercises.removeAll { $0 == exercise }
        saveExercises()
    }
    
    // 種目リストを読み込み
    private func loadExercises() {
        if let savedExercises = UserDefaults.standard.stringArray(forKey: "customExercises") {
            exercises = savedExercises
        } else {
            exercises = defaultExercises
            saveExercises()
        }
    }
    
    // 種目リストを保存
    private func saveExercises() {
        UserDefaults.standard.set(exercises, forKey: "customExercises")
    }
    
    // 編集開始
    private func startEditing(exercise: String) {
        editingExercise = exercise
        editedName = exercise
    }
    
    // 編集内容を保存
    private func saveEditedExercise(oldName: String) {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty && (trimmedName == oldName || !exercises.contains(trimmedName)) {
            if let index = exercises.firstIndex(of: oldName) {
                exercises[index] = trimmedName
                saveExercises()
            }
        }
        
        editingExercise = nil
        editedName = ""
    }
}

// 各種目の行ビュー
struct ExerciseRow: View {
    let exercise: String
    let isEditing: Bool
    @Binding var editedName: String
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 削除ボタン（背景）
            HStack {
                Spacer()
                Button(action: onDelete) {
                    VStack {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                        Text("削除")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80)
                }
                .background(Color.red)
            }
            
            // メインコンテンツ
            HStack {
                if isEditing {
                    TextField("種目名", text: $editedName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit { onSave() }
                    
                    HStack(spacing: 12) {
                        Button("保存", action: onSave)
                            .foregroundColor(.blue)
                        
                        Button("キャンセル", action: onCancel)
                            .foregroundColor(.red)
                    }
                } else {
                    Text(exercise)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture { onEdit() }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -40 {
                            offset = -80
                            showDeleteButton = true
                        } else {
                            offset = 0
                            showDeleteButton = false
                        }
                    }
            )
            .animation(.spring(), value: offset)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.vertical, 4)
    }
}

// ドラッグ&ドロップのデリゲート
struct ExerciseDropDelegate: DropDelegate {
    let item: String
    @Binding var exercises: [String]
    @Binding var draggedItem: String?
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item,
              let from = exercises.firstIndex(of: draggedItem),
              let to = exercises.firstIndex(of: item) else { return }
        
        withAnimation {
            exercises.move(fromOffsets: IndexSet(integer: from),
                         toOffset: to > from ? to + 1 : to)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [UTType.text])
    }
}

// 種目追加画面（変更なし）
struct AddExerciseView: View {
    @Binding var exercises: [String]
    @Binding var newExerciseName: String
    @Environment(\.dismiss) var dismiss
    @State private var showingDuplicateAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("新しい種目")) {
                        TextField("種目名を入力", text: $newExerciseName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Spacer()
            }
            .navigationTitle("種目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        newExerciseName = ""
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addExercise()
                    }
                    .disabled(newExerciseName.isEmpty)
                }
            }
            .alert("重複エラー", isPresented: $showingDuplicateAlert) {
                Button("OK") {
                    showingDuplicateAlert = false
                }
            } message: {
                Text("この種目は既に登録されています")
            }
        }
    }
    
    private func addExercise() {
        let trimmedName = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if exercises.contains(trimmedName) {
            showingDuplicateAlert = true
            return
        }
        
        if !trimmedName.isEmpty {
            exercises.append(trimmedName)
            UserDefaults.standard.set(exercises, forKey: "customExercises")
            newExerciseName = ""
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        ExerciseManagementView()
    }
}