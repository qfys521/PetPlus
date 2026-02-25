import { ToastUtil } from '@pura/harmony-utils';

@Entry
@Component
struct Index {
  @State username: string = "";
  @State password: string = "";
  @State isSelect: boolean = false;
  @State isReadUserAgreement: boolean = false;
  @State isReadPrivacyPolicy: boolean = false;

  build() {
    Stack() {

      // ===== 背景 =====
      Image($r('app.media.bg1'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // ===== 淡白色模糊层 =====
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.login_blur_layer'))
        .backdropBlur(25)

      // ===== 主内容 =====
      Column() {

        // 头像
        Image($r('app.media.touxiang2'))
          .width(110)
          .height(110)
          .borderRadius(55)
          .margin({ top: 120, bottom: 50 })

        // ===== 登录卡片 =====
        Column({ space: 22 }) {

          // 用户名
          Row() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(20)
              .fontColor([Color.White])
              .margin({ right: 10 })

            TextInput({
              text: this.username,
              placeholder: "请输入用户名"
            })
              .layoutWeight(1)
              .height(45)
              .borderRadius(10)
              .backgroundColor($r('app.color.login_input_bg'))
              .fontColor(Color.White)
              .placeholderColor(Color.White)
              .padding({ left: 10 })
              .onChange(v => this.username = v)
          }

          // 密码
          Row() {
            SymbolGlyph($r('sys.symbol.lock'))
              .fontSize(20)
              .fontColor([Color.White])
              .margin({ right: 10 })

            TextInput({
              text: this.password,
              placeholder: "请输入密码"
            })
              .type(InputType.Password)
              .layoutWeight(1)
              .height(45)
              .borderRadius(10)
              .backgroundColor($r('app.color.login_input_bg'))
              .fontColor(Color.White)
              .placeholderColor(Color.White)
              .padding({ left: 10 })
              .onChange(v => this.password = v)
          }

          // 登录按钮
          Button("登录")
            .width('100%')
            .constraintSize({
              minWidth: 280,
              maxWidth: 420
            })
            .height(50)
            .borderRadius(12)
            .backgroundColor($r('app.color.login_button_bg'))
            .backdropBlur(15)
            .fontColor(Color.White)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              if (!this.isSelect) {
                ToastUtil.showToast("请先阅读并同意用户协议和隐私政策！");
                return;
              }

              if (!this.isReadUserAgreement || !this.isReadPrivacyPolicy) {
                ToastUtil.showToast("请先阅读并同意用户协议和隐私政策！");
                return;
              }

              // 登录逻辑...
            })

          // 注册入口
          Row() {
            Text("还没有账号?")
              .fontSize(14)
              .fontColor(Color.White)

            Text(" 去注册 >")
              .fontSize(14)
              .fontColor($r('app.color.login_highlight'))
              .fontWeight(FontWeight.Bold)
          }
          .justifyContent(FlexAlign.Center)
          .margin({ top: 5 })
        }
        .padding(25)
        .width('90%')
        .constraintSize({
          minWidth: 280,
          maxWidth: 420
        })
        .backgroundColor($r('app.color.login_card_bg'))
        .borderRadius(20)
        .alignItems(HorizontalAlign.Center)

        // 协议选择
        Row() {
          Checkbox()
            .select(this.isSelect)
            .margin({ right: 8 })
            .onChange(v => this.isSelect = v)

          Text("已阅读并同意 ")
            .fontSize(12)
            .fontColor(Color.White)

          Text("用户协议")
            .fontSize(12)
            .fontColor($r('app.color.login_highlight'))
            .onClick(() => {
              this.getUIContext().showAlertDialog({
                title: "用户协议",
                subtitle: "请仔细阅读 《用户协议》和《隐私政策》",
                message: $r("app.string.user_agreement"),
                primaryButton: {
                  value: "取消",
                  action: () => {
                    this.isReadUserAgreement = false;
                  }
                },
                secondaryButton: {
                  value: "同意",
                  action: () => {
                    this.isReadUserAgreement = true;
                  }
                }
              })
            })

          Text(" 和 ")
            .fontSize(12)
            .fontColor(Color.White)

          Text("隐私政策")
            .fontSize(12)
            .fontColor($r('app.color.login_highlight'))
            .onClick(() => {
              this.getUIContext().showAlertDialog({
                title: "隐私政策",
                subtitle: "请仔细阅读 《用户协议》和《隐私政策》》",
                message: $r("app.string.privacy_policy"),
                primaryButton: {
                  value: "取消",
                  action: () => {
                    this.isReadPrivacyPolicy = false;
                  }
                },
                secondaryButton: {
                  value: "同意",
                  action: () => {
                    this.isReadPrivacyPolicy = true;
                  }
                }
              })
            })
        }
        .margin({ top: 30 })

        Blank()
          .layoutWeight(1)

        // 底部品牌语
        Text("PetPlus宠家，您的家庭小助手。")
          .fontSize(12)
          .fontColor(Color.White)
          .opacity(0.9)
          .margin({ bottom: 25 })

      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }
}