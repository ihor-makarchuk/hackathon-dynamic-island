//
//  NotchCompositeView.swift
//  Island
//
//  Created by Celve on 9/21/24.
//

import ColorfulX
import SwiftUI
import UniformTypeIdentifiers

struct NotchCompositeView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var galleryModel = GalleryModel.shared

    var headline: some View {
        Text("Catchbox").contentTransition(.numericText())
    }

    var menubar: some View { EmptyView() }

    var body: some View {
        VStack(alignment: .center, spacing: vm.spacing) {
            HeaderView(headline: headline, menubar: menubar)
                .animation(vm.normalAnimation, value: galleryModel.currentItem)
            TodoView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.blurReplace)
    }
}
