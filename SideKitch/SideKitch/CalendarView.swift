//
//  CalendarView.swift
//  SideKitch
//
//  Created by Febie Lin on 2/5/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    
    @State private var mealPlans: [Date: [String: Recipe]] = [:] // Store recipes for each day & meal type
    
    @State private var isAddingRecipe = false
    @State private var selectedMealType: String? = nil

    private var calendar: Calendar { Calendar.current }
    
    private var monthDays: [Date] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    private var firstWeekdayOfMonth: Int {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let firstDayOfMonth = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDayOfMonth) - 1
    }
    
    private var daysInWeek: [String] {
        return calendar.shortWeekdaySymbols
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Calendar")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // month year + toggling
                HStack {
                    Button(action: {
                        self.changeMonth(by: -1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                    }
                    
                    Text(getMonthString(for: currentDate))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        self.changeMonth(by: 1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title)
                    }
                }
                .padding()
                
                // days of the week
                HStack {
                    ForEach(daysInWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                
                // calendar day grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(0..<firstWeekdayOfMonth, id: \.self) { _ in
                        Spacer()
                    }

                    ForEach(monthDays, id: \.self) { day in
                        VStack {
                            Text("\(calendar.component(.day, from: day))")
                                .frame(width: 40, height: 40)
                                .background(self.selectedDate == day ? Color.blue : Color.clear)
                                .cornerRadius(20)
                                .onTapGesture {
                                    selectedDate = day
                                }
                                .foregroundColor(self.selectedDate == day ? .white : .primary)
                            
                            if let meals = mealPlans[day] {
                                VStack {
                                    if let breakfast = meals["Breakfast"] {
                                        NavigationLink(destination: FullRecipeView(recipe: breakfast)) {
                                            Text("🍳 B").font(.caption)
                                        }
                                    }
                                    if let lunch = meals["Lunch"] {
                                        NavigationLink(destination: FullRecipeView(recipe: lunch)) {
                                            Text("🥪 L").font(.caption)
                                        }
                                    }
                                    if let dinner = meals["Dinner"] {
                                        NavigationLink(destination: FullRecipeView(recipe: dinner)) {
                                            Text("🍽 D").font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                
                // Display meals for the selected day
                if let selectedDate = selectedDate {
                    VStack {
                        Text("Meals for \(getDayString(for: selectedDate))")
                            .font(.headline)
                            .padding()

                        let meals = ["Breakfast", "Lunch", "Dinner"]
                        ForEach(meals, id: \.self) { meal in
                            HStack {
                                Text(meal)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if let recipe = mealPlans[selectedDate]?[meal] {
                                    NavigationLink(destination: FullRecipeView(recipe: recipe)) {
                                        Text(recipe.title)
                                            .foregroundColor(.blue)
                                    }
                                } else {
                                    Button("Add Recipe") {
                                        selectedMealType = meal
                                        isAddingRecipe = true
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .sheet(isPresented: $isAddingRecipe) {
                HomeViewMealSelector(selectedMealType: selectedMealType, selectedDate: selectedDate) { selectedRecipe in
                    if let selectedDate = selectedDate, let mealType = selectedMealType {
                        mealPlans[selectedDate, default: [:]][mealType] = selectedRecipe
                    }
                    isAddingRecipe = false
                }
            }
        }
    }
    
    // Function to change month
    private func changeMonth(by value: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) else { return }
        currentDate = newDate
    }
    
    // Function to get the string representation of the current month
    private func getMonthString(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    // Function to get the string representation of a selected day
    private func getDayString(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d"
        return dateFormatter.string(from: date)
    }
}

#Preview {
    CalendarView()
}

