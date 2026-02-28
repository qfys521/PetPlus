@Component
export struct  Dashboard {
  build() {

    Column(){
      Text("Dashboard").fontSize(20)
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}