//
//  ScanOptionView.swift
//  Scane
//
//  Created by Matt Adam on 2021-12-11.
//

import SwiftUI

struct ScanOptionStringView : View {
    
    var option: ScanOption<String>
    
    var body: some View {
        TextField(option.title, text: option.value).textFieldStyle(.squareBorder)
    }
}

struct ScanOptionStringPickerView : View {
    
    @ObservedObject var option: ScanOption<String>

    var body: some View {
        Picker(option.title, selection: option.value) {
            ForEach(option.options ?? [], id: \.self) { option in
                Text(option)
            }
        }
    }
}

struct ScanOptionIntView : View {
    
    @ObservedObject
    var option: ScanOption<Int>
    
    var body: some View {
        TextField(option.title, value: option.value, formatter: NumberFormatter()).textFieldStyle(.squareBorder)
    }
}

struct ScanOptionIntPickerView : View {
    
    @ObservedObject var option: ScanOption<Int>

    var body: some View {
        Picker(option.title, selection: option.value) {
            ForEach(option.options ?? [], id: \.self) { option in
                Text(String(option))
            }
        }
    }
}


struct ScanOptionDoubleView : View {
    
    @ObservedObject
    var option: ScanOption<Double>
    
    var body: some View {
        TextField(option.title, value: option.value, formatter: NumberFormatter()).textFieldStyle(.squareBorder)
    }
}

struct ScanOptionDoublePickerView : View {
    
    @ObservedObject var option: ScanOption<Double>

    var body: some View {
        Picker(option.title, selection: option.value) {
            ForEach(option.options ?? [], id: \.self) { option in
                Text(String(option))
            }
        }
    }
}

struct ScanOptionBoolView : View {
    
    @ObservedObject
    var option: ScanOption<Bool>
    
    var body: some View {
        Toggle(option.title, isOn: option.value).toggleStyle(.checkbox)
    }
}

struct ScanOptionView : View {

    @ObservedObject
    var option: IScanOption
    
    var body: some View {

        if option.isActive {
            if let option = self.option as? ScanOption<Bool> {
                ScanOptionBoolView(option: option)
            }

            if let option = self.option as? ScanOption<String> {
                if option.options != nil {
                    ScanOptionStringPickerView(option: option)
                }
                else {
                    ScanOptionStringView(option: option)
                }
            }
            
            if let option = self.option as? ScanOption<Int> {
                if option.options != nil {
                    ScanOptionIntPickerView(option: option)
                }
                else {
                    ScanOptionIntView(option: option)
                }
            }

            if let option = self.option as? ScanOption<Double> {
                if option.options != nil {
                    ScanOptionDoublePickerView(option: option)
                }
                else {
                    ScanOptionDoubleView(option: option)
                }
            }
        }
    }
}
