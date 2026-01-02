import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Form {
                Section {
                    HStack {
                        Text("Rest Timer Duration")
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(AppSettings.shared.restTimerDuration)s")
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("30s")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: Binding(
                                get: { Double(AppSettings.shared.restTimerDuration) },
                                set: { 
                                    AppSettings.shared.restTimerDuration = Int($0)
                                    AppSettings.shared.saveSettings()
                                }
                            ), in: 30...300, step: 10)
                            
                            Text("5m")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Timer")
                        .foregroundColor(.white)
                }
                
                Section {
                    Picker("Weight Unit", selection: Binding(
                        get: { AppSettings.shared.preferredUnit },
                        set: { 
                            AppSettings.shared.preferredUnit = $0
                            AppSettings.shared.saveSettings()
                        }
                    )) {
                        ForEach(AppSettings.WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue.uppercased()).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .foregroundColor(.white)
                } header: {
                    Text("Units")
                        .foregroundColor(.white)
                }
                
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.white)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Built with")
                            .foregroundColor(.white)
                        Spacer()
                        Text("SwiftUI + SwiftData")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("About")
                        .foregroundColor(.white)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}