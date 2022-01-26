//
//  ContentView.swift
//  Kadai20
//
//  Created by mana on 2022/01/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    private enum Mode {
        case add, edit
    }

    private let dataStore = ItemDataStore()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    @State private var isShowAddEditView = false
    @State private var name: String = ""
    @State private var mode: Mode = .add
    @State private var editId: UUID?

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    HStack {
                        ItemView(item: item)
                            .onTapGesture {
                                item.isChecked.toggle()
                            }

                        Spacer()

                        Label("", systemImage: "info.circle")
                            .onTapGesture {
                                mode = .edit
                                editId = item.id
                                name = item.name ?? ""
                                isShowAddEditView = true
                            }
                    }
                }
                .onDelete { dataStore.delete(items: items, offset: $0) }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        mode = .add
                        name = ""
                        isShowAddEditView = true
                    }, label: { Image(systemName: "plus") })
                }
            }
        }
        .fullScreenCover(isPresented: $isShowAddEditView) {
            AddOrEditItemView(
                name: $name,
                didSave: { addOrEditName in
                    isShowAddEditView = false
                    switch mode {
                    case .add:
                        dataStore.didAdd(addName: addOrEditName)
                    case .edit:
                        dataStore.didEditName(items: items, editId: editId, editName: addOrEditName)
                    }
                },
                didCancel: { isShowAddEditView = false })
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .inactive:
                if viewContext.hasChanges {
                    do {
                        try dataStore.save()
                    } catch {
                        print("書き込みエラー\n\(error.localizedDescription)")
                    }
                }
            default: break
            }
        }
    }
}

struct ItemDataStore {
    private let context = PersistenceController.shared.container.viewContext

    func didAdd(addName: String) {
        let newItem = Item(context: context)
        newItem.timestamp = Date()
        newItem.id = UUID()
        newItem.name = addName
        newItem.isChecked = false
    }

    func didEditName(items: FetchedResults<Item>, editId: UUID?, editName: String) {
        guard let targetIndex = items.firstIndex(where: { $0.id == editId }) else { return }
        items[targetIndex].name = editName
    }

    func delete(items: FetchedResults<Item>, offset: IndexSet) {
        let targetItem = offset.map { items[$0] }.first ?? .init()
        context.delete(targetItem)
    }

    func save() throws {
        do {
            try context.save()
        } catch {
            throw error
        }
    }
}

struct AddOrEditItemView: View {
    @Binding var name: String
    let didSave: (String) -> Void
    let didCancel: () -> Void

    var body: some View {
        NavigationView {
            HStack(spacing: 30) {
                Text("名前")
                    .padding(.leading)

                TextField("", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.trailing)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        didCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        didSave(name)
                    }
                }
            }
        }
    }
}

struct ItemView: View {
    @ObservedObject var item: Item
    private let checkMark = Image(systemName: "checkmark")

    var body: some View {
        HStack {
            if item.isChecked {
                checkMark.foregroundColor(.orange)
            } else {
                checkMark.hidden()
            }

            Text(item.name ?? "")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct AddOrEditItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddOrEditItemView(name: .constant("みかん"), didSave: { _ in }, didCancel: {})
    }
}

struct ItemView_Previews: PreviewProvider {
    static var previews: some View {
        ItemView(item: .init())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
