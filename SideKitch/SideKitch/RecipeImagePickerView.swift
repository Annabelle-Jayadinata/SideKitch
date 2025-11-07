//
//  RecipeImagePickerView.swift
//  SideKitch
//
//  Created by Annabelle Jayadinata on 04/03/25.
//

import SwiftUI
import PhotosUI

struct RecipeImagePickerView: View {
    @Binding var selectedImage: PhotosPickerItem?
    @Binding var imageData: Data?
    @Binding var imageUrl: String?

    var body: some View {
        Section(header: Text("Recipe Image")) {
            ZStack(alignment: .topTrailing) {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else if let urlString = imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 200)
                    .cornerRadius(10)
                }
                
                // Delete Button
                if imageData != nil || imageUrl != nil {
                    Button(action: {
                        imageData = nil
                        imageUrl = nil
                    }) {
                        Image(systemName: "trash.fill")
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    .padding(10)
                }
            }

            // PhotosPicker
            PhotosPicker(selection: $selectedImage, matching: .images, photoLibrary: .shared()) {
                Label("Choose from Gallery", systemImage: "photo")
                    .foregroundColor(.red)
            }
            .onChange(of: selectedImage) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }
}
