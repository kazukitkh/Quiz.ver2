////
////  SwiftUIView.swift
////  Quiz.ver2
////
////  Created by 武樋一樹 on 2022/04/11.
////
//
//import SwiftUI
//import Combine
//
//class LearnCardModel: ObservableObject {
//    @Published var attributeTitle: String
//    @Published var attributeName: String
//    init(_ title: String, _ name: String) {
//        self.attributeTitle = title
//        self.attributeName = name
//    }
//}
//
//struct LearnCardUIView: View {
//    @ObservedObject var cardObj = LearnCardModel("title", "name")
//
//    var body: some View {
//        VStack(alignment: .center, spacing: 10) {
//            Text(self.$cardObj.attributeTitle)
//            Text(self.$cardObj.attributeName)
//        }
//    }
//}
//
//struct LearnUIView: View {
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: true) {
//            LearnCardUIView()
//        }
//    }
//}
//
//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        LearnUIView()
//    }
//}
