import SwiftUI

struct MainEstimateView: View {
    @StateObject private var vm = MainEstimateViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if vm.categories.isEmpty {
                    Text("Нет данных")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(vm.categories.indices, id: \.self) { i in
                                let selected = i == vm.selectedCategoryIndex
                                Button(vm.categories[i].title) {
                                    vm.selectedCategoryIndex = i
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selected ? .white : .primary)
                                .clipShape(Capsule())
                            }
                        }
                        .padding()
                    }
                }

                List {
                    ForEach(vm.currentSections) { section in
                        DisclosureGroup(section.title) {
                            ForEach(section.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .padding(.vertical, 8)
                                        HStack {
                                            Button(action: { vm.showInfo(item) }) {
                                                Image(systemName: "info.circle")
                                                    .imageScale(.large)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                            Text("\(item.price, specifier: "%.0f") ₽ / \(item.unit)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)

                                            Spacer()
                                        }
                                    }
                                    .padding(.vertical, 4)

                                    Spacer()

                                    Button(action: { vm.showQuantity(item) }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 48))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.blue)
                                    .padding(.leading, 20)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 12))
                            }
                        }
                    }
                }
            }
            .onAppear { vm.load() }

            // Фото поверх
            if let item = vm.infoItem {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { vm.infoItem = nil }

                VStack(spacing: 12) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)

                    if let photos = item.photos, !photos.isEmpty {
                        TabView {
                            ForEach(photos, id: \.self) { name in
                                Image(name)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        .frame(height: 260)
                        .tabViewStyle(.page)
                    } else {
                        Text("Фото нет")
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $vm.isQuantitySheetPresented) {
            if let item = vm.quantityItem {
                QuantitySheet(item: item, rooms: vm.roomOptions)
                    .presentationDetents([.medium])
            } else {
                Text("Нет данных")
            }
        }
    }
}

#Preview {
    MainEstimateView()
}
